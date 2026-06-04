import SwiftUI
import NewReaderCore
import UniformTypeIdentifiers

struct SidebarView: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @State private var showImportOPML: Bool = false
    @State private var feedToRename: Feed?
    @State private var renameText: String = ""
    @State private var folderToRename: Folder?
    @State private var folderRenameText: String = ""
    @State private var showNewFolderAlert: Bool = false
    @State private var collapsedFolders: Set<UUID> = []
    @State private var newFolderName: String = ""

    var body: some View {
        List(selection: $viewModel.selectedFeed) {
            Section("智能视图") {
                SmartViewRow(
                    icon: "tray.full",
                    label: "全部文章",
                    count: viewModel.feeds.flatMap { $0.allArticles }.count,
                    action: { viewModel.selectAllArticles() }
                )
                SmartViewRow(
                    icon: "envelope.badge",
                    label: "未读",
                    count: viewModel.feeds.flatMap { $0.allArticles }.filter { !$0.isRead }.count,
                    action: { viewModel.selectUnread() }
                )
                SmartViewRow(
                    icon: "star",
                    label: "星标",
                    count: viewModel.feeds.flatMap { $0.allArticles }.filter { $0.isStarred }.count,
                    action: { viewModel.selectStarred() }
                )
            }

            // Folders with their feeds (collapsible)
            ForEach(viewModel.folders) { folder in
                Section {
                    if !collapsedFolders.contains(folder.id) {
                        ForEach(folder.allFeeds) { feed in
                            FeedRowView(feed: feed)
                                .tag(feed as Feed?)
                                .contextMenu {
                                    feedContextMenu(feed: feed)
                                }
                        }
                    }
                } header: {
                    HStack {
                        Image(systemName: collapsedFolders.contains(folder.id) ? "folder" : "folder.fill")
                        Text(folder.name)
                        Spacer()
                        let feedCount = folder.allFeeds.count
                        if feedCount > 0 {
                            Text("\(feedCount)")
                                .font(.caption).foregroundStyle(.secondary)
                                .padding(.horizontal, 6).padding(.vertical, 1)
                                .background(.quaternary, in: Capsule())
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if collapsedFolders.contains(folder.id) {
                            collapsedFolders.remove(folder.id)
                        } else {
                            collapsedFolders.insert(folder.id)
                        }
                    }
                    .contextMenu {
                        Button {
                            folderToRename = folder
                            folderRenameText = folder.name
                        } label: {
                            Label("重命名分类", systemImage: "pencil")
                        }
                        Divider()
                        Button("删除分类", role: .destructive) {
                            viewModel.deleteFolder(folder)
                        }
                    }
                }
            }

            // Unassigned feeds
            let folderFeedIDs = Set(viewModel.folders.flatMap { $0.allFeeds.map { $0.id } })
            let orphanFeeds = viewModel.feeds.filter { !folderFeedIDs.contains($0.id) }
            if !orphanFeeds.isEmpty {
                Section(viewModel.folders.isEmpty ? "订阅源" : "未分类") {
                    ForEach(orphanFeeds) { feed in
                        FeedRowView(feed: feed)
                            .tag(feed as Feed?)
                            .contextMenu {
                                feedContextMenu(feed: feed)
                            }
                    }
                }
            } else if viewModel.folders.isEmpty {
                Section("订阅源") {
                    Text("暂无订阅源")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem {
                Menu {
                    Button {
                        showNewFolderAlert = true
                    } label: {
                        Label("新建分类", systemImage: "folder.badge.plus")
                    }
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
                .help("更多操作")
            }
        }
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
    private func feedContextMenu(feed: Feed) -> some View {
        Button("刷新") {
            Task { await viewModel.refreshFeed(feed) }
        }
        Divider()
        Button("标为已读") {
            viewModel.markAllAsRead(in: feed)
        }
        Divider()
        // Move to folder submenu
        if !viewModel.folders.isEmpty {
            Menu("移动到…") {
                Button("移除分类") {
                    viewModel.moveFeed(feed, to: nil)
                }
                Divider()
                ForEach(viewModel.folders) { folder in
                    if feed.folder?.id != folder.id {
                        Button(folder.name) {
                            viewModel.moveFeed(feed, to: folder)
                        }
                    }
                }
            }
            Divider()
        }
        Button("重命名") {
            feedToRename = feed
            renameText = feed.title
        }
        Divider()
        Button("删除", role: .destructive) {
            viewModel.deleteFeed(feed)
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
            if feed.lastError != nil {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)
            }
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
