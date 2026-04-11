import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_event.dart';
import '../../blocs/article/article_state.dart';
import '../../widgets/article_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_shimmer.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ArticleBloc>().add(LoadAllArticles());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      context.read<ArticleBloc>().add(LoadAllArticles());
    } else {
      context.read<ArticleBloc>().add(SearchArticles(query));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search articles...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearch('');
                              },
                            )
                          : null,
                    ),
                    onChanged: _onSearch,
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<ArticleBloc, ArticleState>(
                builder: (context, state) {
                  if (state is ArticleLoading) {
                    return const FeedListShimmer();
                  }
                  if (state is ArticleError) {
                    return EmptyState(
                      icon: Icons.error_outline,
                      title: 'Error loading articles',
                      subtitle: state.message,
                    );
                  }
                  if (state is ArticlesLoaded) {
                    if (state.articles.isEmpty) {
                      if (_searchController.text.isNotEmpty) {
                        return EmptyState(
                          icon: Icons.search_off,
                          title: 'No results found',
                          subtitle: 'Try a different search term',
                        );
                      }
                      return const EmptyState(
                        icon: Icons.article_outlined,
                        title: 'No articles yet',
                        subtitle: 'Add some feeds to get started',
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: state.articles.length,
                      itemBuilder: (context, index) {
                        final article = state.articles[index];
                        return ArticleCard(
                          article: article,
                          onTap: () => context.go('/article/${article.id}'),
                          onFavorite: () {
                            context.read<ArticleBloc>().add(
                                  MarkArticleFavorite(article.id, !article.isFavorite),
                                );
                          },
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
