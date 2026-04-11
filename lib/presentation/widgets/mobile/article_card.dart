import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/article_model.dart';

class ArticleCard extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback onTap;
  final bool showImage;
  final bool isWide;

  const ArticleCard({
    super.key,
    required this.article,
    required this.onTap,
    this.showImage = true,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showImage && article.imageUrl != null) {
      return _ImageCard(article: article, onTap: onTap, isWide: isWide);
    }
    return _NoImageCard(article: article, onTap: onTap, isWide: isWide);
  }
}

class _ImageCard extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback onTap;
  final bool isWide;

  const _ImageCard({
    required this.article,
    required this.onTap,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: isWide ? 16 / 9 : 4 / 3,
                child: Image.network(
                  article.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: isDark
                        ? AppColors.darkSurfaceContainerHigh
                        : AppColors.surfaceContainerHigh,
                    child: Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: subtitleColor,
                    ),
                  ),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category dot + source and read time
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${article.feedId} • ${article.readingTimeMinutes} 分钟',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: subtitleColor,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Expanded(
                      child: Text(
                        article.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                        maxLines: isWide ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoImageCard extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback onTap;
  final bool isWide;

  const _NoImageCard({
    required this.article,
    required this.onTap,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.darkSurfaceContainerLow
        : AppColors.surfaceContainerLow;
    final borderColor = isDark
        ? AppColors.darkOutlineVariant.withValues(alpha: 0.15)
        : AppColors.outlineVariant.withValues(alpha: 0.1);
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source and read time
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${article.feedId} • ${article.readingTimeMinutes} 分钟',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: subtitleColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Title
            Expanded(
              child: Text(
                article.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                maxLines: isWide ? 4 : 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (article.description != null && isWide) ...[
              const SizedBox(height: 8),
              // Description
              Text(
                article.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: subtitleColor,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HeroArticleCard extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback onTap;

  const HeroArticleCard({
    super.key,
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with category label overlay
            if (article.imageUrl != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.network(
                        article.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: isDark
                              ? AppColors.darkSurfaceContainerHigh
                              : AppColors.surfaceContainerHigh,
                          child: Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: subtitleColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Category label
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '精选推荐',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source and read time
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${article.feedId} • ${article.readingTimeMinutes} 分钟',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: subtitleColor,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: textColor,
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (article.description != null) ...[
                    const SizedBox(height: 8),
                    // Description
                    Text(
                      article.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: subtitleColor,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
