import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/article_model.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_event.dart';
import '../../blocs/article/article_state.dart';
import '../../blocs/feed/feed_bloc.dart';
import '../../blocs/feed/feed_event.dart';
import '../../blocs/feed/feed_state.dart';
import '../../widgets/mobile/article_card.dart';
import '../../widgets/mobile/category_tabs.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    context.read<ArticleBloc>().add(LoadAllArticles());
    context.read<FeedBloc>().add(LoadFeeds());
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ArticleBloc>().add(LoadAllArticles());
      },
      child: CustomScrollView(
        slivers: [
          // Category tabs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: BlocBuilder<FeedBloc, FeedState>(
                builder: (context, state) {
                  if (state is FeedsLoaded) {
                    return CategoryTabs(
                      categories: state.categories,
                      selectedCategoryId: _selectedCategoryId,
                      onCategorySelected: (categoryId) {
                        setState(() {
                          _selectedCategoryId = categoryId;
                        });
                        if (categoryId != null) {
                          context
                              .read<ArticleBloc>()
                              .add(LoadArticles(categoryId: categoryId));
                        } else {
                          context.read<ArticleBloc>().add(LoadAllArticles());
                        }
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),

          // Hero Article
          BlocBuilder<ArticleBloc, ArticleState>(
            builder: (context, state) {
              if (state is ArticlesLoaded && state.articles.isNotEmpty) {
                final heroArticle = state.articles.first;
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: HeroArticleCard(
                      article: heroArticle,
                      onTap: () => _navigateToArticle(heroArticle),
                    ),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),

          // Section title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                '最新文章',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),

          // Articles bento grid
          BlocBuilder<ArticleBloc, ArticleState>(
            builder: (context, state) {
              if (state is ArticleLoading) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (state is ArticlesLoaded) {
                final articles = state.articles;
                if (articles.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildEmptyState(),
                  );
                }

                // Skip first article (hero) and show rest in grid
                final gridArticles = articles.length > 1 ? articles.sublist(1) : <ArticleModel>[];

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final article = gridArticles[index];
                        // Alternate between cards with and without images
                        final bool hasImage = article.imageUrl != null && index % 3 != 2;
                        // Every 3rd item is a wide card (spans 2 columns)
                        final bool isWide = index % 7 == 2;
                        return ArticleCard(
                          article: article,
                          onTap: () => _navigateToArticle(article),
                          showImage: hasImage,
                          isWide: isWide,
                        );
                      },
                      childCount: gridArticles.length,
                    ),
                  ),
                );
              }

              if (state is ArticleError) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: 16),
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<ArticleBloc>().add(LoadAllArticles());
                          },
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverToBoxAdapter(
                child: _buildEmptyState(),
              );
            },
          ),

          // Bottom padding for safe area
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? AppColors.darkOnSurfaceVariant.withValues(alpha: 0.5)
        : AppColors.onSurfaceVariant.withValues(alpha: 0.5);
    final textColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rss_feed,
            size: 64,
            color: iconColor,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无文章',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: textColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '添加订阅源开始阅读',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  void _navigateToArticle(ArticleModel article) {
    context.push('/article/${article.id}');
  }
}
