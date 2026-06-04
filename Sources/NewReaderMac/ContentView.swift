import SwiftUI
import NewReaderCore

struct ContentView: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .frame(minWidth: 220)
        } content: {
            ArticleListView()
                .frame(minWidth: 320)
        } detail: {
            if let article = viewModel.selectedArticle {
                ArticleReaderView(article: article, viewModel: viewModel)
                    .id(article.id)
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
        .overlay(alignment: .bottom) {
            if let feed = viewModel.lastDeletedFeed {
                HStack {
                    Label("已删除「\(feed.title)」", systemImage: "trash")
                        .font(.callout)
                    Button("撤销") {
                        viewModel.undoDeleteFeed()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                .padding(.bottom, 40)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring, value: viewModel.lastDeletedFeed != nil)
            }
        }
        .overlay {
            if viewModel.showSubscribe {
                SubscribeOverlayView()
                    .environmentObject(viewModel)
            }
        }
        .toolbar {
            // Left side: primary actions
            ToolbarItemGroup {
                Button {
                    viewModel.showSubscribe = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("添加订阅 (⌘N)")

                Button {
                    Task { await viewModel.refreshAll() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("刷新全部订阅源")
                .disabled(viewModel.isRefreshing)
            }
            // Right side: settings
            ToolbarItem(placement: .primaryAction) {
                Button {
                    openSettings()
                } label: {
                    Image(systemName: "gearshape")
                }
                .help("设置 (⌘,)")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showSubscribeSheet)) { _ in
            viewModel.showSubscribe = true
        }
        .task {
            viewModel.selectUnread()
        }
        .preferredColorScheme(viewModel.appTheme.colorScheme)
    }
}

struct WelcomeView: View {
    @Environment(\.openSettings) private var openSettings
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
                openSettings()
            } label: {
                Label("打开设置", systemImage: "gearshape")
            }
            .buttonStyle(.bordered)
            .padding(.top, 4)
        }
    }
}
