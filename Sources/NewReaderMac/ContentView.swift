import SwiftUI
import NewReaderCore
import OSLog

// macOS-only: relies on NavigationSplitView, .toolbar, .onOpenURL deep link,
// and macOS-specific key handling. See NewReaderiOS/ContentView.swift for the
// iOS counterpart (TabView-based).

struct ContentView: View {
    private static let logger = Logger(subsystem: "com.newreader.app", category: "ContentView")
    @EnvironmentObject var viewModel: ReaderViewModel
    @Environment(\.openSettings) private var openSettings

    @State private var showWorkspace: Bool = false

    var body: some View {
        Group {
            if !viewModel.authService.isLoggedIn {
                LoginView()
                    .environmentObject(viewModel)
            } else {
                mainContent
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
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

        .task {
            // Override any SwiftUI-replayed actions after navigation transition
            try? await Task.sleep(for: .milliseconds(800))
            viewModel.selectUnread()
        }
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
            ToolbarItem {
                Button {
                    viewModel.showSubscribe = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("添加订阅 (⌘N)")
            }
            ToolbarItem {
                Button {
                    Task { await viewModel.refreshAll() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("刷新全部订阅源")
                .disabled(viewModel.isRefreshing)
            }
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
        .onReceive(NotificationCenter.default.publisher(for: .showWorkspaceSheet)) { _ in
            showWorkspace = true
        }
        .sheet(isPresented: $showWorkspace) {
            WorkspaceView()
                .environmentObject(viewModel)
        }
        .onOpenURL { url in
            guard url.scheme == "newreader" else { return }
            Task {
                do {
                    try await viewModel.authService.handleCallback(url: url)
                } catch {
                    Self.logger.error("Auth callback error: \(error.localizedDescription, privacy: .public)")
                }
            }
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
