import SwiftUI
import NewReaderCore
import UniformTypeIdentifiers

struct FeedsListView: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @State private var showSubscribe: Bool = false
    @State private var showImportOPML: Bool = false
    @State private var feedToRename: Feed?
    @State private var renameText: String = ""

    var body: some View {
        List {
            ForEach(viewModel.feeds) { feed in
                NavigationLink {
                    FeedArticlesView(feed: feed)
                } label: {
                    HStack {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .foregroundStyle(.secondary)
                        Text(feed.title).lineLimit(1)
                        Spacer()
                        let u = feed.unreadArticles.count
                        if u > 0 {
                            Text("\(u)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6).padding(.vertical, 1)
                                .background(.quaternary, in: Capsule())
                        }
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        feedToRename = feed
                        renameText = feed.title
                    } label: {
                        Label("重命名", systemImage: "pencil")
                    }
                    .tint(.orange)
                    Button(role: .destructive) { viewModel.deleteFeed(feed) } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("订阅源")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showSubscribe = true } label: {
                        Label("添加订阅", systemImage: "plus")
                    }
                    Button {
                        Task { await viewModel.refreshAll() }
                    } label: {
                        Label("刷新全部", systemImage: "arrow.clockwise")
                    }
                    Divider()
                    Button { showImportOPML = true } label: {
                        Label("导入 OPML", systemImage: "square.and.arrow.down")
                    }
                    if !viewModel.feeds.isEmpty, let url = viewModel.exportOPML() {
                        ShareLink(item: url) {
                            Label("导出 OPML", systemImage: "square.and.arrow.up")
                        }
                    }
                    Divider()
                    Button {
                        Task { await viewModel.summarizeAllUnread() }
                    } label: {
                        Label("批量 AI 摘要", systemImage: "sparkles")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showSubscribe) { SubscribeView() }
        .alert("重命名订阅源", isPresented: Binding(
            get: { feedToRename != nil },
            set: { if !$0 { feedToRename = nil } }
        )) {
            TextField("新名称", text: $renameText)
            Button("取消", role: .cancel) { feedToRename = nil }
            Button("确定") {
                if let feed = feedToRename {
                    viewModel.renameFeed(feed, to: renameText)
                }
                feedToRename = nil
            }
        } message: {
            Text("为订阅源「\(feedToRename?.title ?? "")」输入新名称")
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

struct FeedArticlesView: View {
    let feed: Feed
    @EnvironmentObject var viewModel: ReaderViewModel

    var body: some View {
        List(feed.sortedArticles) { article in
            NavigationLink {
                ArticleReaderView(article: article, viewModel: viewModel)
            } label: {
                ArticleRowView(article: article, isSelected: false, onTap: {})
            }
        }
        .navigationTitle(feed.title)
    }
}

extension Feed {
    var sortedArticles: [Article] {
        (articles ?? []).sorted { ($0.publishedDate ?? .distantPast) > ($1.publishedDate ?? .distantPast) }
    }
}
