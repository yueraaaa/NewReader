import SwiftUI
import SwiftData
import NewReaderCore
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

@main
struct NewReaderMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel: ReaderViewModel

    static let iCloudContainerID = "iCloud.com.newreader.app"

    init() {
        UserDefaults.standard.set(50, forKey: "NSInitialToolTipDelay")

        let schema = Schema([Feed.self, Article.self, Folder.self, WorkspaceSnapshot.self])
        let result = ModelContainerFactory.makeContainer(
            schema: schema,
            options: .init(iCloudContainerID: Self.iCloudContainerID)
        )
        _viewModel = StateObject(wrappedValue: ReaderViewModel(
            modelContext: result.container.mainContext,
            iCloudContainerID: Self.iCloudContainerID
        ))

        Task {
            _ = await NotificationService.shared.requestPermission()
        }
        CrashReporter.install()
        Task {
            await CrashReportCollector.uploadNewReports()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .newItem) {
                Button("添加订阅…") {
                    NotificationCenter.default.post(name: .showSubscribeSheet, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
                Divider()
                Button("阅读工作台") {
                    NotificationCenter.default.post(name: .showWorkspaceSheet, object: nil)
                }
                .keyboardShortcut("w", modifiers: [.command, .shift])
                Divider()
                Button("发送反馈…") {
                    let email = Bundle.main.object(forInfoDictionaryKey: "FeedbackEmail") as? String ?? "feedback@example.com"
                    if let url = URL(string: "mailto:\(email)?subject=NewReader%20%E5%8F%8D%E9%A6%88") {
                        NSWorkspace.shared.open(url)
                    }
                }
                Button("查看崩溃日志") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: CrashReporter.diagnosticReportsPath))
                }
            }
        }

        Settings {
            SettingsView()
                .environmentObject(viewModel)
        }
    }
}


extension Notification.Name {
    static let showSubscribeSheet = Notification.Name("showSubscribeSheet")
    static let showWorkspaceSheet = Notification.Name("showWorkspaceSheet")
}
