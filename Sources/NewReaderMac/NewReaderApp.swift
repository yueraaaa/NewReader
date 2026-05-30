import SwiftUI
import SwiftData
import NewReaderCore

@main
struct NewReaderMacApp: App {
    @StateObject private var viewModel: ReaderViewModel

    init() {
        let schema = Schema([Feed.self, Article.self, Folder.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try! ModelContainer(for: schema, configurations: config)
        _viewModel = StateObject(wrappedValue: ReaderViewModel(modelContext: container.mainContext))

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
