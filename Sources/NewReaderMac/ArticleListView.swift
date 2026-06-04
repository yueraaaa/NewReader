import SwiftUI
import NewReaderCore

struct ArticleListView: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @State private var searchText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                TextField("搜索文章…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)

            Divider()

            // Article list
            if viewModel.articles.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text(viewModel.feeds.isEmpty ? "⌘N 添加订阅源" : "暂无文章")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                List(viewModel.filteredArticles, selection: $viewModel.selectedArticle) { article in
                    ArticleRowView(
                        article: article,
                        isSelected: viewModel.selectedArticle?.id == article.id,
                        onTap: {
                        if !article.isRead { viewModel.toggleRead(article) }
                        viewModel.selectedArticle = article
                    }
                    )
                    .tag(article as Article?)
                    .swipeActions(edge: .leading) {
                        Button {
                            viewModel.toggleRead(article)
                        } label: {
                            Label(
                                article.isRead ? "标为未读" : "标为已读",
                                systemImage: article.isRead ? "envelope.badge" : "envelope.open"
                            )
                        }
                        .tint(article.isRead ? .orange : .blue)
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            viewModel.toggleStarred(article)
                        } label: {
                            Label(
                                article.isStarred ? "取消星标" : "星标",
                                systemImage: article.isStarred ? "star.slash" : "star"
                            )
                        }
                        .tint(.yellow)
                    }
                }
                .listStyle(.plain)
            }

            // Status bar
            if !viewModel.feeds.isEmpty {
                Divider()
                HStack {
                    Text("共 \(viewModel.articles.count) 篇")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)

                    Spacer()

                    if viewModel.isRefreshing {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 14, height: 14)
                    }

                    let unreadCount = viewModel.articles.filter { !$0.isRead }.count
                    if unreadCount > 0 {
                        Text("\(unreadCount) 篇未读")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
            }
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchQuery = newValue
        }
        .onKeyPress(characters: .alphanumerics) { press in
            guard let idx = viewModel.filteredArticles.firstIndex(where: { $0.id == viewModel.selectedArticle?.id }) else {
                return .ignored
            }
            switch press.characters {
            case "j":
                let next = min(idx + 1, viewModel.filteredArticles.count - 1)
                let article = viewModel.filteredArticles[next]
                if !article.isRead { viewModel.toggleRead(article) }
                viewModel.selectedArticle = article
                return .handled
            case "k":
                let prev = max(idx - 1, 0)
                let article = viewModel.filteredArticles[prev]
                if !article.isRead { viewModel.toggleRead(article) }
                viewModel.selectedArticle = article
                return .handled
            default:
                return .ignored
            }
        }
            }
}
