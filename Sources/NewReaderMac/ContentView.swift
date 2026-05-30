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
            .disabled(viewModel.showSubscribe)
            .overlay {
                if viewModel.showSubscribe {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture { viewModel.showSubscribe = false }
                }
            }

            // Subscribe overlay on top so it can receive focus
            if viewModel.showSubscribe {
                SubscribeOverlayView()
                    .environmentObject(viewModel)
            }
        }
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
            Text("⌘N 添加订阅")
                .font(.callout)
                .foregroundStyle(.tertiary)

            Button {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } label: {
                Label("打开设置", systemImage: "gearshape")
            }
            .buttonStyle(.bordered)
            .padding(.top, 4)
        }
    }
}
