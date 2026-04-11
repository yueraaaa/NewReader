import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/article_model.dart';

class ArticleCard extends StatelessWidget {
  final ArticleModel article;
  final String? categoryName;
  final Color? categoryColor;
  final VoidCallback onTap;
  final VoidCallback? onBookmarkTap;

  const ArticleCard({
    super.key,
    required this.article,
    this.categoryName,
    this.categoryColor,
    required this.onTap,
    this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final secondaryColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final tertiaryColor = isDark ? AppColors.darkTertiary : AppColors.tertiary;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Metadata row
              Row(
                children: [
                  if (categoryName != null && categoryColor != null) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      categoryName!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: secondaryColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (article.publishedAt != null)
                    Text(
                      _formatDate(article.publishedAt!),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: secondaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  const Spacer(),
                  Text(
                    '${article.readingTimeMinutes} min',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: secondaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Title
              Text(
                article.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Description
              if (article.description != null && article.description!.isNotEmpty)
                Text(
                  _stripHtml(article.description!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: secondaryColor,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              // Footer row
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  if (article.author != null && article.author!.isNotEmpty)
                    Expanded(
                      child: Text(
                        article.author!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: secondaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    const Spacer(),
                  // Read indicator
                  if (article.isRead)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: secondaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '已读',
                        style: TextStyle(
                          fontSize: 10,
                          color: secondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Bookmark button
                  InkWell(
                    onTap: onBookmarkTap,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        article.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                        size: 20,
                        color: article.isFavorite ? tertiaryColor : secondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} 分钟前';
      }
      return '${diff.inHours} 小时前';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
