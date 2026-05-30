import SwiftUI
import NewReaderCore

struct ContentView: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @State private var selectedTab: Tab = .feeds

    enum Tab: String, CaseIterable {
        case feeds, unread, starred, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { FeedsListView() }
                .tabItem { Label("订阅", systemImage: "dot.radiowaves.left.and.right") }
                .tag(Tab.feeds)

            NavigationStack {
                ArticleListTabView(
                    articles: viewModel.feeds.flatMap { $0.articles }.filter { !$0.isRead },
                    title: "未读文章"
                )
            }
            .tabItem { Label("未读", systemImage: "envelope.badge") }
            .badge(viewModel.feeds.flatMap { $0.articles }.filter { !$0.isRead }.count)
            .tag(Tab.unread)

            NavigationStack {
                ArticleListTabView(
                    articles: viewModel.feeds.flatMap { $0.articles }.filter { $0.isStarred },
                    title: "星标文章"
                )
            }
            .tabItem { Label("星标", systemImage: "star") }
            .tag(Tab.starred)

            NavigationStack { SettingsView() }
                .tabItem { Label("设置", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
    }
}

struct ArticleListTabView: View {
    let articles: [Article]
    let title: String
    @EnvironmentObject var viewModel: ReaderViewModel
    @State private var searchText: String = ""

    private var filtered: [Article] {
        guard !searchText.isEmpty else { return articles }
        let q = searchText.localizedLowercase
        return articles.filter {
            $0.title.localizedLowercase.contains(q) ||
            ($0.author?.localizedLowercase.contains(q) ?? false)
        }
    }

    var body: some View {
        List(filtered) { article in
            NavigationLink {
                ArticleReaderView(article: article, viewModel: viewModel)
            } label: {
                ArticleRowView(article: article, isSelected: false, onTap: {})
            }
            .swipeActions(edge: .trailing) {
                Button("已读", systemImage: "checkmark") { viewModel.toggleRead(article) }
                    .tint(.blue)
            }
        }
        .searchable(text: $searchText, prompt: "搜索文章…")
        .navigationTitle(title)
        .toolbar {
            if !articles.isEmpty {
                ToolbarItem {
                    Button {
                        articles.filter { !$0.isRead }.forEach { $0.isRead = true }
                    } label: {
                        Image(systemName: "checkmark.circle")
                    }
                }
            }
        }
    }
}
