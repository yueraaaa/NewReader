import SwiftUI

/// A single article row in the list
public struct ArticleRowView: View {
    public let article: Article
    public let isSelected: Bool
    public let onTap: () -> Void

    public init(article: Article, isSelected: Bool, onTap: @escaping () -> Void) {
        self.article = article
        self.isSelected = isSelected
        self.onTap = onTap
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(article.isRead ? Color.clear : Color.accentColor)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.system(size: 13, weight: article.isRead ? .regular : .semibold))
                    .lineLimit(2)
                    .foregroundStyle(article.isRead ? .secondary : .primary)

                HStack(spacing: 8) {
                    if let feedTitle = article.feed?.title {
                        Text(feedTitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    if let date = article.publishedDate {
                        Text(date, style: .relative)
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }

                if !article.summary.isEmpty {
                    Text(article.summary)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if article.isStarred {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .onTapGesture { }
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
    }
}
