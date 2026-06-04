import SwiftUI
import SwiftData
import NewReaderCore

@main
struct NewReaderMacApp: App {
    @StateObject private var viewModel: ReaderViewModel

    static let iCloudContainerID = "iCloud.com.newreader.app"

    init() {
        // Reduce system tooltip delay so toolbar hints appear instantly
        UserDefaults.standard.set(50, forKey: "NSInitialToolTipDelay")

        let schema = Schema([Feed.self, Article.self, Folder.self])
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
}
