import Foundation

/// Validates URLs for network safety: protocol allowlist + private IP blocking.
public enum URLValidator {

    /// Allowed URL schemes for fetching remote content.
    private static let allowedSchemes: Set<String> = ["https", "http"]

    /// Private / reserved IPv4 prefixes (CIDR notation).
    private static let privateRanges: [(UInt32, UInt32)] = [
        (0x0A000000, 0x0AFFFFFF),       // 10.0.0.0/8
        (0x7F000000, 0x7FFFFFFF),       // 127.0.0.0/8 (loopback)
        (0xA9FE0000, 0xA9FEFFFF),       // 169.254.0.0/16 (link-local)
        (0xAC100000, 0xAC1FFFFF),       // 172.16.0.0/12
        (0xC0A80000, 0xC0A8FFFF),       // 192.168.0.0/16
        (0x64400000, 0x647FFFFF),       // 100.64.0.0/10 (CGN)
        (0xE0000000, 0xEFFFFFFF),       // 224.0.0.0/4 (multicast)
        (0xF0000000, 0xFFFFFFFF),       // 240.0.0.0/4 (reserved)
    ]

    /// Validate that a URL string is safe to fetch from.
    /// - Returns: The validated `URL` if safe, or `nil` otherwise.
    public static func validate(_ urlString: String) -> URL? {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)

        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              allowedSchemes.contains(scheme),
              let host = url.host?.lowercased(),
              !host.isEmpty else {
            return nil
        }

        // Block raw IPv4 addresses in private ranges.
        if isPrivateIPv4(host) { return nil }

        // Block IPv6 loopback / link-local.
        if host == "::1" || host.hasPrefix("fe80:") { return nil }

        // Block common internal hostnames.
        if host == "localhost" || host == "localhost.localdomain" { return nil }

        return url
    }

    /// Check if the host string is a valid URL at all (used for OPML import
    /// where we only want to skip obviously bad entries, not full validation).
    public static func isPlausibleURL(_ urlString: String) -> Bool {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              allowedSchemes.contains(scheme),
              let host = url.host, !host.isEmpty else {
            return false
        }
        return true
    }

    // MARK: - Private

    private static func isPrivateIPv4(_ host: String) -> Bool {
        guard let ip = ipv4ToUInt32(host) else { return false }
        for (low, high) in privateRanges {
            if ip >= low && ip <= high { return true }
        }
        return false
    }

    private static func ipv4ToUInt32(_ host: String) -> UInt32? {
        let parts = host.split(separator: ".")
        guard parts.count == 4 else { return nil }
        var ip: UInt32 = 0
        for (i, part) in parts.enumerated() {
            guard let octet = UInt32(part), octet <= 255 else { return nil }
            ip |= octet << (24 - i * 8)
        }
        return ip
    }
}
