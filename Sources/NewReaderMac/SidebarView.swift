import SwiftUI
import NewReaderCore
import UniformTypeIdentifiers

struct SidebarView: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @State private var showImportOPML: Bool = false

    var body: some View {
        List(selection: $viewModel.selectedFeed) {
            Section("智能视图") {
                SmartViewRow(
                    icon: "tray.full",
                    label: "全部文章",
                    count: viewModel.feeds.flatMap { $0.articles }.count,
                    action: { viewModel.selectAllArticles() }
                )
                SmartViewRow(
                    icon: "envelope.badge",
                    label: "未读",
                    count: viewModel.feeds.flatMap { $0.articles }.filter { !$0.isRead }.count,
                    action: { viewModel.selectUnread() }
                )
                SmartViewRow(
                    icon: "star",
                    label: "星标",
                    count: viewModel.feeds.flatMap { $0.articles }.filter { $0.isStarred }.count,
                    action: { viewModel.selectStarred() }
                )
            }

            Section("订阅源") {
                ForEach(viewModel.feeds) { feed in
                    FeedRowView(feed: feed)
                        .tag(feed as Feed?)
                        .contextMenu {
                            Button("刷新") {
                                Task { await viewModel.refreshFeed(feed) }
                            }
                            Divider()
                            Button("标为已读") {
                                viewModel.markAllAsRead(in: feed)
                            }
                            Divider()
                            Button("删除", role: .destructive) {
                                viewModel.deleteFeed(feed)
                            }
                        }
                }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem {
                Menu {
                    Button {
                        viewModel.showSubscribe = true
                    } label: {
                        Label("添加订阅", systemImage: "plus")
                    }
                    Button {
                        Task { await viewModel.refreshAll() }
                    } label: {
                        Label("刷新全部", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isRefreshing)

                    Divider()

                    Button {
                        showImportOPML = true
                    } label: {
                        Label("导入 OPML…", systemImage: "square.and.arrow.down")
                    }
                    Button {
                        if let url = viewModel.exportOPML() {
                            NSWorkspace.shared.activateFileViewerSelecting([url])
                        }
                    } label: {
                        Label("导出 OPML…", systemImage: "square.and.arrow.up")
                    }
                    .disabled(viewModel.feeds.isEmpty)

                    Divider()

                    Button {
                        Task { await viewModel.summarizeAllUnread() }
                    } label: {
                        Label("批量 AI 摘要", systemImage: "sparkles")
                    }
                    .disabled(viewModel.articles.filter { !$0.isRead && $0.aiSummary == nil }.isEmpty)

                    Button {
                        viewModel.markAllVisibleAsRead()
                    } label: {
                        Label("全部标为已读", systemImage: "checkmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }

            ToolbarItem {
                Button {
                    // Open Settings window via AppKit
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                } label: {
                    Image(systemName: "gearshape")
                }
                .help("设置")
            }
        }
        .fileImporter(
            isPresented: $showImportOPML,
            allowedContentTypes: [.xml, UTType(filenameExtension: "opml") ?? .xml],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                Task { _ = await viewModel.importOPML(from: url) }
            }
        }
    }
}

struct SmartViewRow: View {
    public let icon: String
    public let label: String
    public let count: Int
    public let action: () -> Void

    public var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).frame(width: 20)
                Text(label)
                Spacer()
                Text("\(count)")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background(.quaternary, in: Capsule())
            }
        }
        .buttonStyle(.plain)
    }
}

struct FeedRowView: View {
    public let feed: Feed

    public var body: some View {
        HStack {
            Image(systemName: "dot.radiowaves.left.and.right")
                .frame(width: 20).foregroundStyle(.secondary)
            Text(feed.title).lineLimit(1)
            Spacer()
            let u = feed.unreadArticles.count
            if u > 0 {
                Text("\(u)")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background(.quaternary, in: Capsule())
            }
        }
    }
}
