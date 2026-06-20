import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/feed_model.dart';
import '../../blocs/feed/feed_bloc.dart';
import '../../blocs/feed/feed_state.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_event.dart';
import '../../blocs/article/article_state.dart';
import '../../widgets/desktop/article_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _readFilter = 'all'; // 'all', 'unread', 'read'

  @override
  void initState() {
    super.initState();
    context.read<ArticleBloc>().add(LoadAllArticles());
    context.read<ArticleBloc>().add(LoadUnreadCount());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),

          // Feeds section
          BlocBuilder<FeedBloc, FeedState>(
            builder: (context, feedState) {
              if (feedState is FeedsLoaded) {
                return BlocBuilder<ArticleBloc, ArticleState>(
                  builder: (context, articleState) {
                    final unreadCount = articleState is ArticlesLoaded
                        ? articleState.unreadCount
                        : 0;
                    return _FeedsSection(
                      feeds: feedState.feeds,
                      categories: feedState.categories,
                      totalUnreadCount: unreadCount,
                    );
                  },
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // Recent articles section
          Row(
            children: [
              Text(
                '最近文章',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _FilterChip(
                label: '全部',
                isSelected: _readFilter == 'all',
                onTap: () => setState(() => _readFilter = 'all'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: '未读',
                isSelected: _readFilter == 'unread',
                onTap: () => setState(() => _readFilter = 'unread'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: '已读',
                isSelected: _readFilter == 'read',
                onTap: () => setState(() => _readFilter = 'read'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          BlocBuilder<ArticleBloc, ArticleState>(
            builder: (context, articleState) {
              if (articleState is ArticlesLoaded) {
                if (articleState.articles.isEmpty) {
                  return _EmptyState();
                }

                return BlocBuilder<FeedBloc, FeedState>(
                  builder: (context, feedState) {
                    final categories = feedState is FeedsLoaded
                        ? feedState.categories
                        : <CategoryModel>[];

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: articleState.articles.where((a) {
                        if (_readFilter == 'unread') return !a.isRead;
                        if (_readFilter == 'read') return a.isRead;
                        return true;
                      }).length.clamp(0, 20),
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final filteredArticles = articleState.articles.where((a) {
                          if (_readFilter == 'unread') return !a.isRead;
                          if (_readFilter == 'read') return a.isRead;
                          return true;
                        }).toList();
                        final article = filteredArticles[index];
                        final category = categories.where((c) => c.id == article.feedId).firstOrNull;

                        return ArticleCard(
                          article: article,
                          categoryName: category?.name,
                          categoryColor: category != null
                              ? Color(int.parse(category.color.replaceFirst('#', '0xFF')))
                              : null,
                          onTap: () {
                            if (!article.isRead) {
                              context.read<ArticleBloc>().add(MarkArticleRead(article.id, true));
                            }
                            context.go('/article/${article.id}');
                          },
                          onBookmarkTap: () {
                            context.read<ArticleBloc>().add(
                              MarkArticleFavorite(article.id, !article.isFavorite),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              }

              if (articleState is ArticleLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return _EmptyState();
            },
          ),
        ],
      ),
    );
  }
}

class _FeedsSection extends StatelessWidget {
  final List<FeedModel> feeds;
  final List<CategoryModel> categories;
  final int totalUnreadCount;

  const _FeedsSection({
    required this.feeds,
    required this.categories,
    required this.totalUnreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final secondaryColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    if (feeds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          children: [
            Icon(
              Icons.rss_feed,
              size: 48,
              color: secondaryColor,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '暂无订阅源',
              style: TextStyle(color: secondaryColor),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: () => context.go('/explore'),
              icon: const Icon(Icons.add),
              label: const Text('添加订阅'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '我的订阅',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (totalUnreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  '$totalUnreadCount 未读',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: feeds.map((feed) {
            final category = categories.where((c) => c.id == feed.categoryId).firstOrNull;
            return _FeedChip(
              feed: feed,
              categoryColor: category != null
                  ? Color(int.parse(category.color.replaceFirst('#', '0xFF')))
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _FeedChip extends StatelessWidget {
  final FeedModel feed;
  final Color? categoryColor;

  const _FeedChip({
    required this.feed,
    this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.darkSurfaceContainerHigh
        : AppColors.surfaceContainerHigh;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: () => context.go('/feed/${feed.id}'),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (categoryColor != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                feed.title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '0',
                  style: TextStyle(
                    fontSize: 11,
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bgColor = isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHigh;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    return Material(
      color: isSelected ? primaryColor.withValues(alpha: 0.2) : bgColor,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? primaryColor : textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: secondaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '暂无文章',
            style: TextStyle(
              color: secondaryColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '订阅一些 RSS 源来开始阅读',
            style: TextStyle(
              color: secondaryColor.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
