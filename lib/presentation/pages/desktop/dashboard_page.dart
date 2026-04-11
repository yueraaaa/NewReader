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
  @override
  void initState() {
    super.initState();
    context.read<ArticleBloc>().add(LoadAllArticles());
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
          // Header
          Text(
            '仪表盘',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: textColor,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Feeds section
          BlocBuilder<FeedBloc, FeedState>(
            builder: (context, feedState) {
              if (feedState is FeedsLoaded) {
                return _FeedsSection(
                  feeds: feedState.feeds,
                  categories: feedState.categories,
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // Recent articles section
          Text(
            '最近文章',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
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
                      itemCount: articleState.articles.length.clamp(0, 20),
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final article = articleState.articles[index];
                        final category = categories.where((c) => c.id == article.feedId).firstOrNull;

                        return ArticleCard(
                          article: article,
                          categoryName: category?.name,
                          categoryColor: category != null
                              ? Color(int.parse(category.color.replaceFirst('#', '0xFF')))
                              : null,
                          onTap: () => context.go('/article/${article.id}'),
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

  const _FeedsSection({
    required this.feeds,
    required this.categories,
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
        Text(
          '我的订阅',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
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
