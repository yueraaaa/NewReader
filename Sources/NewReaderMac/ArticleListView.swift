import SwiftUI
import NewReaderCore

struct ArticleListView: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool


    private var groupedArticles: [(label: String, articles: [Article])] {
        let grouped = Dictionary(grouping: viewModel.filteredArticles) { dateGroup(for: $0.publishedDate) }
        let order = ["今天", "昨天", "本周", "更早"]
        return order.compactMap { key in
            grouped[key].map { (key, $0) }
        }
    }

    private func dateGroup(for date: Date?) -> String {
        guard let date = date else { return "更早" }
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "今天" }
        if cal.isDateInYesterday(date) { return "昨天" }
        if let weekAgo = cal.date(byAdding: .day, value: -7, to: Date()), date > weekAgo { return "本周" }
        return "更早"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                TextField("搜索文章…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($isSearchFocused)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape, modifiers: [])
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
            } else if viewModel.filteredArticles.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text("暂无文章")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(groupedArticles, id: \.label) { group in
                        Section {
                            ForEach(group.articles) { article in
                                Button {
                                    if !article.isRead { viewModel.toggleRead(article) }
                                    viewModel.selectedArticle = article
                                } label: {
                                    ArticleRowView(
                                        article: article,
                                        isSelected: viewModel.selectedArticle?.id == article.id,
                                        onTap: {}
                                    )
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .leading) {
                                    Button {
                                        if !article.isRead { viewModel.toggleRead(article) }
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
                        } header: {
                            Text(group.label).frame(maxWidth: .infinity, alignment: .trailing)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.leading, -10)
                        }
                    }
                }
                .listStyle(.plain)
                .focusable(true)
                .onKeyPress(characters: .alphanumerics) { press in
                    let articles = viewModel.filteredArticles
                    guard !articles.isEmpty,
                          let idx = articles.firstIndex(where: { $0.id == viewModel.selectedArticle?.id }) else {
                        return .ignored
                    }
                    switch press.characters {
                    case "j":
                        let next = idx + 1
                        if next < articles.count {
                            let article = articles[next]
                            if !article.isRead { viewModel.toggleRead(article) }
                            viewModel.selectedArticle = article
                        } else {
                            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                        }
                        return .handled
                    case "k":
                        let prev = idx - 1
                        if prev >= 0 {
                            let article = articles[prev]
                            if !article.isRead { viewModel.toggleRead(article) }
                            viewModel.selectedArticle = article
                        } else {
                            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                        }
                        return .handled
                    default:
                        return .ignored
                    }
                }
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

                    if viewModel.isAutoSummarizing {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 14, height: 14)
                        Text("AI 摘要中…")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
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
        .onChange(of: viewModel.selectedArticle) { _, newArticle in
            if let article = newArticle, !article.isRead {
                viewModel.toggleRead(article)
            }
        }
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "f" {
                    isSearchFocused = true
                    return nil
                }
                return event
            }
        }
    }
}
