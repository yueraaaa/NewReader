import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/category_model.dart';
import '../../blocs/feed/feed_bloc.dart';
import '../../blocs/feed/feed_state.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_event.dart';
import '../../blocs/article/article_state.dart';
import '../../widgets/desktop/article_card.dart';

class FeedListPage extends StatefulWidget {
  final String? categoryId;
  final String? feedId;

  const FeedListPage({
    super.key,
    this.categoryId,
    this.feedId,
  });

  @override
  State<FeedListPage> createState() => _FeedListPageState();
}

class _FeedListPageState extends State<FeedListPage> {
  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  void _loadArticles() {
    if (widget.feedId != null) {
      context.read<ArticleBloc>().add(LoadArticles(feedId: widget.feedId));
    } else if (widget.categoryId != null) {
      context.read<ArticleBloc>().add(LoadArticles(categoryId: widget.categoryId));
    } else {
      context.read<ArticleBloc>().add(LoadAllArticles());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlocBuilder<FeedBloc, FeedState>(
                builder: (context, state) {
                  String title = '全部文章';
                  if (state is FeedsLoaded) {
                    if (widget.feedId != null) {
                      final feed = state.feeds.where((f) => f.id == widget.feedId).firstOrNull;
                      title = feed?.title ?? '文章列表';
                    } else if (widget.categoryId != null) {
                      final category = state.categories.where((c) => c.id == widget.categoryId).firstOrNull;
                      title = category?.name ?? '分类';
                    }
                  }
                  return Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: textColor,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Category filter chips
        BlocBuilder<FeedBloc, FeedState>(
          builder: (context, state) {
            if (state is FeedsLoaded && state.categories.isNotEmpty) {
              return Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _FilterChip(
                        label: '全部',
                        isSelected: widget.categoryId == null && widget.feedId == null,
                        onTap: () => context.go('/'),
                      );
                    }
                    final category = state.categories[index - 1];
                    return _FilterChip(
                      label: category.name,
                      color: Color(int.parse(category.color.replaceFirst('#', '0xFF'))),
                      isSelected: widget.categoryId == category.id,
                      onTap: () => context.go('/category/${category.id}'),
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        const SizedBox(height: AppSpacing.md),

        // Articles list
        Expanded(
          child: BlocBuilder<ArticleBloc, ArticleState>(
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
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      itemCount: articleState.articles.length,
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
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBgColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final unselectedBgColor = isDark
        ? AppColors.darkSurfaceContainerHigh
        : AppColors.surfaceContainerHigh;
    final selectedTextColor = isDark ? AppColors.darkOnPrimary : AppColors.onPrimary;
    final unselectedTextColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return Material(
      color: isSelected ? selectedBgColor : unselectedBgColor,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? selectedTextColor : unselectedTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
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

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
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
        ],
      ),
    );
  }
}
