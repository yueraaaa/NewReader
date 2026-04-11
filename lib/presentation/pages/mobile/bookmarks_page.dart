import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_event.dart';
import '../../blocs/article/article_state.dart';
import '../../widgets/mobile/article_card.dart';

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
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ArticleBloc>().add(LoadFavoriteArticles());
      },
      child: CustomScrollView(
        slivers: [
          // Section title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Text(
                '我的收藏',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          ),

          // Bookmarks grid
          BlocBuilder<ArticleBloc, ArticleState>(
            builder: (context, state) {
              if (state is ArticleLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (state is ArticlesLoaded) {
                final articles = state.articles;
                if (articles.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildEmptyState(),
                  );
                }

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
                        final article = articles[index];
                        final bool hasImage = article.imageUrl != null && index % 3 != 2;
                        return ArticleCard(
                          article: article,
                          onTap: () => context.push('/article/${article.id}'),
                          showImage: hasImage,
                        );
                      },
                      childCount: articles.length,
                    ),
                  ),
                );
              }

              if (state is ArticleError) {
                return SliverFillRemaining(
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
                            context.read<ArticleBloc>().add(LoadFavoriteArticles());
                          },
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverFillRemaining(
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
            Icons.bookmark_border,
            size: 64,
            color: iconColor,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无收藏',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: textColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '收藏的文章会显示在这里',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }
}
