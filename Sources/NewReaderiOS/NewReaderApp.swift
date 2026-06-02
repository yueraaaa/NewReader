import SwiftUI
import SwiftData
import NewReaderCore

@main
struct NewReaderiOSApp: App {
    @StateObject private var viewModel: ReaderViewModel

    init() {
        let schema = Schema([Feed.self, Article.self, Folder.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            print("[NewReader] ModelContainer failed, falling back to in-memory: \(error)")
            container = try! ModelContainer(for: schema, configurations: .init(schema: schema, isStoredInMemoryOnly: true))
        }
        _viewModel = StateObject(wrappedValue: ReaderViewModel(modelContext: container.mainContext))
        Task { _ = await NotificationService.shared.requestPermission() }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .task {
                    viewModel.selectAllArticles()
                }
        }
    }
}
