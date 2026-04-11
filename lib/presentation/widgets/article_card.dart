import 'package:flutter/material.dart';
import '../../../data/models/article_model.dart';
import '../../../core/constants/app_colors.dart';
import 'package:intl/intl.dart';

/// Article card widget for displaying article previews
class ArticleCard extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  const ArticleCard({
    super.key,
    required this.article,
    this.onTap,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      article.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onFavorite != null)
                    IconButton(
                      icon: Icon(
                        article.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                        color: article.isFavorite
                            ? AppColors.tertiary
                            : subtitleColor,
                      ),
                      onPressed: onFavorite,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              if (article.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  article.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (article.publishedAt != null) ...[
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: subtitleColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(article.publishedAt!),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: subtitleColor,
                          ),
                    ),
                  ],
                  const SizedBox(width: 16),
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: subtitleColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${article.readingTimeMinutes} min read',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: subtitleColor,
                        ),
                  ),
                  if (article.readProgress > 0) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: article.readProgress,
                        backgroundColor: isDark
                            ? AppColors.darkSurfaceContainerHigh
                            : AppColors.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ],
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
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}
