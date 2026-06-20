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
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<ArticleBloc>().add(LoadFavoriteArticles());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final secondaryColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final surfaceColor = isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow;

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
              const SizedBox(height: AppSpacing.md),
              // Search bar
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '搜索收藏...',
                    hintStyle: TextStyle(color: secondaryColor, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: secondaryColor, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
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
                // Filter articles based on search query
                var filteredArticles = articleState.articles;
                if (_searchQuery.isNotEmpty) {
                  filteredArticles = filteredArticles.where((article) {
                    return article.title.toLowerCase().contains(_searchQuery) ||
                        (article.description?.toLowerCase().contains(_searchQuery) ?? false);
                  }).toList();
                }
                if (filteredArticles.isEmpty) {
                  return _EmptyState();
                }

                return BlocBuilder<FeedBloc, FeedState>(
                  builder: (context, feedState) {
                    final categories = feedState is FeedsLoaded
                        ? feedState.categories
                        : <CategoryModel>[];

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      itemCount: filteredArticles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final article = filteredArticles[index];
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
