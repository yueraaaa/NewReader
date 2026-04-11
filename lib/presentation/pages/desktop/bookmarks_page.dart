import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/category_model.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_event.dart';
import '../../blocs/article/article_state.dart';
import '../../blocs/feed/feed_bloc.dart';
import '../../blocs/feed/feed_state.dart';
import '../../widgets/desktop/article_card.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  @override
  void initState() {
    super.initState();
    context.read<ArticleBloc>().add(LoadFavoriteArticles());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final secondaryColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '我的收藏',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: textColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '您收藏的文章将在此处显示',
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final tertiaryColor = isDark ? AppColors.darkTertiary : AppColors.tertiary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: tertiaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '暂无收藏',
            style: TextStyle(
              color: textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '收藏的文章将显示在这里',
            style: TextStyle(
              color: secondaryColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('开始阅读'),
          ),
        ],
      ),
    );
  }

  Color textColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkOnSurface : AppColors.onSurface;
  }
}
