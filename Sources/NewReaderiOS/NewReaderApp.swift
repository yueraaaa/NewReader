import SwiftUI
import SwiftData
import NewReaderCore

@main
struct NewReaderiOSApp: App {
    static let iCloudContainerID = "iCloud.com.newreader.app"

    @StateObject private var viewModel: ReaderViewModel

    init() {
        let schema = Schema([Feed.self, Article.self, Folder.self])
        let result = ModelContainerFactory.makeContainer(
            schema: schema,
            options: .init(iCloudContainerID: Self.iCloudContainerID)
        )
        _viewModel = StateObject(wrappedValue: ReaderViewModel(
            modelContext: result.container.mainContext,
            iCloudContainerID: Self.iCloudContainerID
        ))
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
