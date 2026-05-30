import SwiftUI
import SwiftData
import NewReaderCore

@main
struct NewReaderiOSApp: App {
    @StateObject private var viewModel: ReaderViewModel

    init() {
        let schema = Schema([Feed.self, Article.self, Folder.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try! ModelContainer(for: schema, configurations: config)
        _viewModel = StateObject(wrappedValue: ReaderViewModel(modelContext: container.mainContext))
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
