import SwiftUI
import NewReaderCore

struct ContentView: View {
    @EnvironmentObject var viewModel: ReaderViewModel

    var body: some View {
        ZStack {
            NavigationSplitView {
                SidebarView()
                    .frame(minWidth: 220)
            } content: {
                ArticleListView()
                    .frame(minWidth: 320)
            } detail: {
                if let article = viewModel.selectedArticle {
                    ArticleReaderView(article: article, viewModel: viewModel)
                } else {
                    WelcomeView()
                }
            }

            // In-window subscribe overlay — no separate NSWindow, focus just works
            if viewModel.showSubscribe {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture { viewModel.showSubscribe = false }

                SubscribeOverlayView()
                    .environmentObject(viewModel)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.15), value: viewModel.showSubscribe)
        .onReceive(NotificationCenter.default.publisher(for: .showSubscribeSheet)) { _ in
            viewModel.showSubscribe = true
        }
        .task {
            viewModel.selectAllArticles()
        }
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "newspaper")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("NewReader")
                .font(.largeTitle.bold())
            Text("选择一篇文章开始阅读")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("⌘N 添加订阅 · ⌘, 打开设置")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
    }
}
