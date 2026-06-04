import SwiftUI
import NewReaderCore
import UniformTypeIdentifiers

struct FeedsListView: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @State private var showSubscribe: Bool = false
    @State private var showImportOPML: Bool = false
    @State private var feedToRename: Feed?
    @State private var renameText: String = ""
    @State private var folderToRename: Folder?
    @State private var folderRenameText: String = ""
    @State private var showNewFolderAlert: Bool = false
    @State private var newFolderName: String = ""

    var body: some View {
        List {
            // Folders with their feeds (collapsible via DisclosureGroup)
            ForEach(viewModel.folders) { folder in
                Section {
                    DisclosureGroup {
                        ForEach(folder.allFeeds) { feed in
                            feedRow(feed)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "folder")
                                .foregroundStyle(.secondary)
                            Text(folder.name)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(folder.allFeeds.count)")
                                .font(.caption).foregroundStyle(.secondary)
                                .padding(.horizontal, 6).padding(.vertical, 1)
                                .background(.quaternary, in: Capsule())
                        }
                    }
                } header: {
                    EmptyView()
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        folderToRename = folder
                        folderRenameText = folder.name
                    } label: {
                        Label("重命名", systemImage: "pencil")
                    }
                    .tint(.orange)
                    Button("删除", role: .destructive) {
                        viewModel.deleteFolder(folder)
                    }
                }
            }

            // Unassigned feeds
            let folderFeedIDs = Set(viewModel.folders.flatMap { $0.allFeeds.map { $0.id } })
            let orphanFeeds = viewModel.feeds.filter { !folderFeedIDs.contains($0.id) }
            Section(viewModel.folders.isEmpty ? "订阅源" : "未分类") {
                if orphanFeeds.isEmpty && !viewModel.feeds.isEmpty {
                    Text("所有订阅源已分类")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(orphanFeeds) { feed in
                    feedRow(feed)
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
                    Button { showNewFolderAlert = true } label: {
                        Label("新建分类", systemImage: "folder.badge.plus")
                    }
                    Divider()
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
        // Rename feed alert
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
        // Rename folder alert
        .alert("重命名分类", isPresented: Binding(
            get: { folderToRename != nil },
            set: { if !$0 { folderToRename = nil } }
        )) {
            TextField("新名称", text: $folderRenameText)
            Button("取消", role: .cancel) { folderToRename = nil }
            Button("确定") {
                if let folder = folderToRename {
                    viewModel.renameFolder(folder, to: folderRenameText)
                }
                folderToRename = nil
            }
        } message: {
            Text("为分类「\(folderToRename?.name ?? "")」输入新名称")
        }
        // New folder alert
        .alert("新建分类", isPresented: $showNewFolderAlert) {
            TextField("分类名称", text: $newFolderName)
            Button("取消", role: .cancel) { newFolderName = "" }
            Button("创建") {
                viewModel.createFolder(name: newFolderName)
                newFolderName = ""
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

    @ViewBuilder
    private func feedRow(_ feed: Feed) -> some View {
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
            if !viewModel.folders.isEmpty {
                Menu {
                    Button {
                        viewModel.moveFeed(feed, to: nil)
                    } label: {
                        Label("移除分类", systemImage: "folder.badge.minus")
                    }
                    ForEach(viewModel.folders) { folder in
                        if feed.folder?.id != folder.id {
                            Button {
                                viewModel.moveFeed(feed, to: folder)
                            } label: {
                                Label(folder.name, systemImage: "folder")
                            }
                        }
                    }
                } label: {
                    Label("移动", systemImage: "folder")
                }
                .tint(.blue)
            }
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
