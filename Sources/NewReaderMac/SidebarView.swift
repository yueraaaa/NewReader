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
    @State private var showNewFolderSheet: Bool = false
    @State private var collapsedFolders: Set<UUID> = []
    @State private var newFolderName: String = ""

    var body: some View {
        List(selection: $viewModel.selectedFeed) {
            Section("智能视图") {
                SmartViewRow(
                    icon: "tray.full",
                    label: "全部文章",
                    count: viewModel.feeds.flatMap { $0.allArticles }.count,
                    action: {
                        viewModel.selectAllArticles()
                    }
                )
                SmartViewRow(
                    icon: "envelope.badge",
                    label: "未读",
                    count: viewModel.feeds.flatMap { $0.allArticles }.filter { !$0.isRead }.count,
                    action: {
                        viewModel.selectUnread()
                    }
                )
                SmartViewRow(
                    icon: "star",
                    label: "星标",
                    count: viewModel.feeds.flatMap { $0.allArticles }.filter { $0.isStarred }.count,
                    action: {
                        viewModel.selectStarred()
                    }
                )
                SmartViewRow(
                    icon: "sparkles",
                    label: "工作台",
                    count: viewModel.workspace?.articleCount ?? 0,
                    action: { NotificationCenter.default.post(name: .showWorkspaceSheet, object: nil) }
                )
            }

            // Folders with their feeds (collapsible)
            ForEach(viewModel.folders) { folder in
                Section {
                    if !collapsedFolders.contains(folder.id) {
                        ForEach(folder.allFeeds) { feed in
                            Button {
                                viewModel.selectFeed(feed)
                            } label: {
                                FeedRowView(feed: feed)
                            }
                            .buttonStyle(.plain)
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
                        Button {
                            viewModel.selectFeed(feed)
                        } label: {
                            FeedRowView(feed: feed)
                        }
                        .buttonStyle(.plain)
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
                        showNewFolderSheet = true
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
        // Rename feed sheet
        .sheet(item: $feedToRename) { feed in
            VStack(spacing: 16) {
                Text("重命名订阅源")
                    .font(.headline)
                Text("为「\(feed.title)」输入新名称")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("新名称", text: $renameText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 260)

                HStack(spacing: 12) {
                    Button("取消") {
                        renameText = ""
                        feedToRename = nil
                    }
                    .keyboardShortcut(.escape, modifiers: [])

                    Button("确定") {
                        viewModel.renameFeed(feed, to: renameText)
                        renameText = ""
                        feedToRename = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.return, modifiers: [])
                }
            }
            .padding(30)
            .frame(width: 360, height: 200)
        }
        // Rename folder sheet
        .sheet(item: $folderToRename) { folder in
            VStack(spacing: 16) {
                Text("重命名分类")
                    .font(.headline)
                Text("为「\(folder.name)」输入新名称")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("新名称", text: $folderRenameText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 260)

                HStack(spacing: 12) {
                    Button("取消") {
                        folderRenameText = ""
                        folderToRename = nil
                    }
                    .keyboardShortcut(.escape, modifiers: [])

                    Button("确定") {
                        viewModel.renameFolder(folder, to: folderRenameText)
                        folderRenameText = ""
                        folderToRename = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(folderRenameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.return, modifiers: [])
                }
            }
            .padding(30)
            .frame(width: 360, height: 200)
        }
        // New folder sheet (avoids macOS alert TextField focus bug)
        .sheet(isPresented: $showNewFolderSheet) {
            VStack(spacing: 16) {
                Text("新建分类")
                    .font(.headline)
                TextField("分类名称", text: $newFolderName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 240)

                HStack(spacing: 12) {
                    Button("取消") {
                        newFolderName = ""
                        showNewFolderSheet = false
                    }
                    .keyboardShortcut(.escape, modifiers: [])

                    Button("创建") {
                        viewModel.createFolder(name: newFolderName)
                        newFolderName = ""
                        showNewFolderSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.return, modifiers: [])
                }
            }
            .padding(30)
            .frame(width: 320, height: 180)
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
    @State private var isPressed = false

    public var body: some View {
        HStack {
            Image(systemName: icon).frame(width: 20)
            Text(label)
            Spacer()
            Text("\(count)")
                .font(.caption).foregroundStyle(.secondary)
                .padding(.horizontal, 6).padding(.vertical, 1)
                .background(.quaternary, in: Capsule())
        }
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                isPressed = false
            }
            action()
        }
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
