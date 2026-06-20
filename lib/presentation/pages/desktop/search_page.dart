import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_event.dart';
import '../../blocs/article/article_state.dart';
import '../../widgets/desktop/article_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _query = query.trim();
    });
    if (_query.isNotEmpty) {
      context.read<ArticleBloc>().add(SearchArticles(_query));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final secondaryColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Scaffold(
      backgroundColor: surfaceColor,
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/'),
                  icon: Icon(Icons.arrow_back, color: textColor),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainerHigh
                          : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      onSubmitted: _onSearch,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: '搜索文章标题、内容...',
                        hintStyle: TextStyle(color: secondaryColor),
                        prefixIcon: Icon(Icons.search, color: secondaryColor),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: secondaryColor),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _query = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                TextButton(
                  onPressed: () => _onSearch(_searchController.text),
                  child: Text(
                    '搜索',
                    style: TextStyle(color: isDark ? AppColors.darkPrimary : AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _query.isEmpty
                ? _EmptySearchState(secondaryColor: secondaryColor)
                : BlocBuilder<ArticleBloc, ArticleState>(
                    builder: (context, articleState) {
                      if (articleState is ArticleLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (articleState is ArticlesLoaded) {
                        if (articleState.articles.isEmpty) {
                          return _NoResultsState(
                            query: _query,
                            secondaryColor: secondaryColor,
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: Text(
                                '找到 ${articleState.articles.length} 条结果',
                                style: TextStyle(
                                  color: secondaryColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                itemCount: articleState.articles.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppSpacing.md),
                                itemBuilder: (context, index) {
                                  final article = articleState.articles[index];

                                  return ArticleCard(
                                    article: article,
                                    categoryName: null,
                                    onTap: () =>
                                        context.go('/article/${article.id}'),
                                    onBookmarkTap: () {
                                      context.read<ArticleBloc>().add(
                                            MarkArticleFavorite(
                                              article.id,
                                              !article.isFavorite,
                                            ),
                                          );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }

                      return _EmptySearchState(secondaryColor: secondaryColor);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  final Color secondaryColor;

  const _EmptySearchState({required this.secondaryColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: secondaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '输入关键词搜索文章',
            style: TextStyle(
              color: secondaryColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '搜索文章标题、内容、描述',
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

class _NoResultsState extends StatelessWidget {
  final String query;
  final Color secondaryColor;

  const _NoResultsState({required this.query, required this.secondaryColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: secondaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '未找到 "$query" 相关文章',
            style: TextStyle(
              color: secondaryColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '尝试其他关键词',
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
