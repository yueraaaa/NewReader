import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/article_model.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_event.dart';
import '../../blocs/article/article_state.dart';

class ArticleDetailPage extends StatefulWidget {
  final String articleId;

  const ArticleDetailPage({
    super.key,
    required this.articleId,
  });

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  final ScrollController _scrollController = ScrollController();
  double _readProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll > 0) {
      final progress = (currentScroll / maxScroll).clamp(0.0, 1.0);
      if (progress != _readProgress) {
        setState(() {
          _readProgress = progress;
        });
        context.read<ArticleBloc>().add(
              UpdateReadProgress(widget.articleId, progress),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArticleBloc, ArticleState>(
      builder: (context, state) {
        ArticleModel? article;
        if (state is ArticlesLoaded) {
          try {
            article = state.articles.firstWhere((a) => a.id == widget.articleId);
          } catch (_) {
            // Article not found in current list
          }
        }

        return Scaffold(
          body: Column(
            children: [
              // Custom app bar with progress
              _buildAppBar(context, article),

              // Content
              Expanded(
                child: article != null
                    ? _buildContent(context, article)
                    : _buildLoadingOrError(),
              ),

              // AI action buttons
              if (article != null) _buildAIActions(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, ArticleModel? article) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.8)
        : AppColors.surface.withValues(alpha: 0.8);
    final textColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final progressBarColor = isDark
        ? AppColors.darkSurfaceContainerHigh
        : AppColors.surfaceContainerHigh;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App bar row
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      article?.feedId ?? '',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: textColor,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      article?.isFavorite == true
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                    ),
                    onPressed: () {
                      if (article != null) {
                        context.read<ArticleBloc>().add(
                              MarkArticleFavorite(article.id, !article.isFavorite),
                            );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      // TODO: share article
                    },
                  ),
                ],
              ),
            ),

            // Reading progress bar
            Container(
              height: 2,
              color: progressBarColor,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _readProgress,
                child: Container(
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ArticleModel article) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final dividerColor = isDark
        ? AppColors.darkOutlineVariant.withValues(alpha: 0.3)
        : AppColors.outlineVariant.withValues(alpha: 0.3);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image
          if (article.imageUrl != null) ...[
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
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
          ],

          // Title
          const SizedBox(height: 24),
          Text(
            article.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                  color: textColor,
                ),
          ),

          // Meta info
          const SizedBox(height: 16),
          Row(
            children: [
              if (article.author != null) ...[
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: subtitleColor,
                ),
                const SizedBox(width: 4),
                Text(
                  article.author!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: subtitleColor,
                      ),
                ),
                const SizedBox(width: 16),
              ],
              Icon(
                Icons.access_time,
                size: 16,
                color: subtitleColor,
              ),
              const SizedBox(width: 4),
              Text(
                '${article.readingTimeMinutes} 分钟阅读',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: subtitleColor,
                    ),
              ),
            ],
          ),

          // Divider
          const SizedBox(height: 24),
          Divider(color: dividerColor),

          // Article content
          const SizedBox(height: 24),
          Text(
            article.content ?? article.description ?? '',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.8,
                  color: textColor,
                ),
          ),

          // Bottom padding
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildLoadingOrError() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildAIActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.95)
        : AppColors.surface.withValues(alpha: 0.95);
    final borderColor = isDark
        ? AppColors.darkOutlineVariant.withValues(alpha: 0.2)
        : AppColors.outlineVariant.withValues(alpha: 0.2);
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(color: borderColor),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _AIActionButton(
              icon: Icons.summarize,
              label: '摘要',
              primaryColor: primaryColor,
              onTap: () {
                // TODO: AI summarize
              },
            ),
            _AIActionButton(
              icon: Icons.translate,
              label: '翻译',
              primaryColor: primaryColor,
              onTap: () {
                // TODO: AI translate
              },
            ),
            _AIActionButton(
              icon: Icons.lightbulb_outline,
              label: '见解',
              primaryColor: primaryColor,
              onTap: () {
                // TODO: AI insights
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AIActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color primaryColor;
  final VoidCallback onTap;

  const _AIActionButton({
    required this.icon,
    required this.label,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: primaryColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
