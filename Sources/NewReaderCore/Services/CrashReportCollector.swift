import Foundation
import Supabase

/// Scans the macOS DiagnosticReports directory for new crash reports from the
/// previous session and uploads them to Supabase Storage, then moves processed
/// files into a local archive so they are never uploaded twice.
///
/// **Security requirement**: The Supabase `crash-reports` storage bucket must
/// have Row-Level Security enabled with an INSERT policy restricted to the
/// `anon` role. Without RLS, anyone with the publishable key can write arbitrary
/// files to this bucket.
public enum CrashReportCollector {

    private static let bucketName = "crash-reports"

    /// Scan for new crash reports and upload them.
    ///
    /// - Compares file modification dates against `CrashReporter.lastLaunchTime`.
    /// - Matches files whose name contains the bundle executable name.
    /// - Uploads via the anon key (no login required); the bucket must grant
    ///   INSERT to the `anon` role.
    /// - Moves successfully uploaded files to `CrashReporter.processedReportsPath`.
    public static func uploadNewReports() async {
        let client = makeClient()
        let fm = FileManager.default
        let reportsDir = CrashReporter.diagnosticReportsPath
        let processedDir = CrashReporter.processedReportsPath
        let lastLaunch = CrashReporter.lastLaunchTime

        guard fm.fileExists(atPath: reportsDir) else {
            CrashReporter.log("DiagnosticReports directory not found, skipping crash scan")
            return
        }

        // Mac crash files are named like "NewReaderMac_2025-06-09-120000_imac.crash"
        let executableName = Bundle.main.executableURL?.deletingPathExtension().lastPathComponent
            ?? "NewReaderMac"

        guard let files = try? fm.contentsOfDirectory(
            at: URL(fileURLWithPath: reportsDir),
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else {
            CrashReporter.log("Could not read DiagnosticReports directory")
            return
        }

        let candidates = files.filter { url in
            url.pathExtension == "crash"
                && url.lastPathComponent.localizedCaseInsensitiveContains(executableName)
                && url.lastPathComponent.localizedCaseInsensitiveContains("NewReader")
        }

        let newReports = candidates.filter { url in
            guard let attrs = try? fm.attributesOfItem(atPath: url.path),
                  let modDate = attrs[.modificationDate] as? Date else { return false }
            return modDate > lastLaunch
        }

        if newReports.isEmpty {
            CrashReporter.log("No new crash reports to upload")
            return
        }

        CrashReporter.log("Found \(newReports.count) new crash report(s), uploading…")

        let deviceID = deviceIdentifier()
        let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "unknown"
        for reportURL in newReports {
            guard let data = try? Data(contentsOf: reportURL) else {
                CrashReporter.log("Could not read crash report: \(reportURL.lastPathComponent)")
                continue
            }

            let remotePath = "\(deviceID)/\(bundleVersion)/\(reportURL.lastPathComponent)"

            do {
                try await client.storage.from(bucketName)
                    .upload(remotePath, data: data, options: .init(contentType: "text/plain"))
                CrashReporter.log("Uploaded: \(reportURL.lastPathComponent)")

                // Move to processed so we never re-upload
                let dest = URL(fileURLWithPath: processedDir)
                    .appendingPathComponent(reportURL.lastPathComponent)
                try? fm.moveItem(at: reportURL, to: dest)

            } catch {
                CrashReporter.log("Upload failed for \(reportURL.lastPathComponent): \(error.localizedDescription)")
            }
        }

        CrashReporter.log("Crash report upload cycle complete")
    }

    // MARK: - Private

    private static func makeClient() -> SupabaseClient {
        SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.publishableKey
        )
    }

    /// Stable per-device identifier stored in UserDefaults.
    private static func deviceIdentifier() -> String {
        let key = "CrashReportCollector.deviceID"
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: key)
        return id
    }
}
