import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/article_model.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_event.dart';
import '../../blocs/article/article_state.dart';
import '../../blocs/ai/ai_bloc.dart';
import '../../blocs/ai/ai_event.dart';
import '../../blocs/ai/ai_state.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../blocs/settings/settings_state.dart';
import '../../widgets/desktop/top_nav_bar.dart';
import '../../widgets/desktop/ai_toolkit_panel.dart';

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
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (maxScroll > 0) {
        setState(() {
          _readProgress = (currentScroll / maxScroll).clamp(0.0, 1.0);
        });
        // Update read progress in bloc
        context.read<ArticleBloc>().add(
          UpdateReadProgress(widget.articleId, _readProgress),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final secondaryColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return BlocBuilder<ArticleBloc, ArticleState>(
      builder: (context, articleState) {
        ArticleModel? article;
        if (articleState is ArticlesLoaded) {
          article = articleState.articles.where((a) => a.id == widget.articleId).firstOrNull;
        }

        if (article == null) {
          return Scaffold(
            backgroundColor: surfaceColor,
            body: Column(
              children: [
                TopNavBar(
                  showBackButton: true,
                  onBackPressed: () => context.go('/'),
                ),
                const Expanded(
                  child: Center(
                    child: Text('文章不存在'),
                  ),
                ),
              ],
            ),
          );
        }

        // At this point article is guaranteed non-null
        final currentArticle = article;

        // Mark as read
        if (!currentArticle.isRead) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<ArticleBloc>().add(MarkArticleRead(currentArticle.id, true));
          });
        }

        return Scaffold(
          backgroundColor: surfaceColor,
          body: Stack(
            children: [
              Column(
                children: [
                  TopNavBar(
                    showBackButton: true,
                    onBackPressed: () => context.go('/'),
                    actions: [
                      TopNavBarAction(
                        icon: currentArticle.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                        tooltip: currentArticle.isFavorite ? '取消收藏' : '收藏',
                        onTap: () {
                          context.read<ArticleBloc>().add(
                            MarkArticleFavorite(currentArticle.id, !currentArticle.isFavorite),
                          );
                        },
                      ),
                      TopNavBarAction(
                        icon: Icons.share,
                        tooltip: '分享',
                        onTap: () {
                          // TODO: Implement share
                        },
                      ),
                      BlocBuilder<SettingsBloc, SettingsState>(
                        builder: (context, settingsState) {
                          return TopNavBarAction(
                            icon: Icons.format_size,
                            tooltip: '字体大小',
                            onTap: () {
                              // TODO: Show font size dialog
                            },
                          );
                        },
                      ),
                      const TopNavBarDivider(),
                      TopNavBarAction(
                        icon: Icons.bolt,
                        tooltip: 'AI 助手',
                        onTap: () {
                          // Scroll to AI panel
                        },
                      ),
                      TopNavBarAction(
                        icon: Icons.translate,
                        tooltip: '翻译',
                        onTap: () {
                          context.read<AiBloc>().add(TranslateArticle(currentArticle));
                        },
                      ),
                      TopNavBarAction(
                        icon: Icons.volume_up,
                        tooltip: '朗读',
                        onTap: () {
                          context.read<AiBloc>().add(ReadArticleAloud(currentArticle));
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Article content
                          Expanded(
                            flex: 8,
                            child: _ArticleContent(
                              article: currentArticle,
                              textColor: textColor,
                              secondaryColor: secondaryColor,
                              primaryColor: primaryColor,
                            ),
                          ),

                          const SizedBox(width: AppSpacing.xl),

                          // AI Toolkit sidebar
                          Expanded(
                            flex: 4,
                            child: BlocProvider.value(
                              value: context.read<AiBloc>(),
                              child: BlocBuilder<AiBloc, AiState>(
                                builder: (context, aiState) {
                                  return AiToolkitPanel(article: currentArticle);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Reading progress bar
              Positioned(
                top: 0,
                left: 256,
                right: 0,
                height: 2,
                child: Container(
                  color: isDark
                      ? AppColors.darkOutlineVariant.withValues(alpha: 0.2)
                      : AppColors.outlineVariant.withValues(alpha: 0.2),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _readProgress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArticleContent extends StatelessWidget {
  final ArticleModel article;
  final Color textColor;
  final Color secondaryColor;
  final Color primaryColor;

  const _ArticleContent({
    required this.article,
    required this.textColor,
    required this.secondaryColor,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metadata
        Row(
          children: [
            if (article.publishedAt != null) ...[
              Text(
                _formatDate(article.publishedAt!),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: secondaryColor,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Text(
              '${article.readingTimeMinutes} 分钟阅读',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: secondaryColor,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Title
        SelectableText(
          article.title,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Author
        if (article.author != null && article.author!.isNotEmpty)
          Text(
            article.author!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: secondaryColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        const SizedBox(height: AppSpacing.xl),

        // Hero image
        if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Image.network(
              article.imageUrl!,
              width: double.infinity,
              height: 400,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 400,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurfaceContainerHigh
                    : AppColors.surfaceContainerHigh,
                child: const Center(
                  child: Icon(Icons.image_not_supported, size: 48),
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),

        // Body content
        _buildBodyContent(context),
      ],
    );
  }

  Widget _buildBodyContent(BuildContext context) {
    final content = article.content ?? article.description ?? '';
    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    // Parse HTML content
    final htmlContent = _parseHtml(content);

    return SelectableText(
      htmlContent,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        height: 1.8,
        color: textColor,
      ),
    );
  }

  String _parseHtml(String html) {
    // Simple HTML to plain text conversion
    return html
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'</p>'), '\n\n')
        .replaceAll(RegExp(r'</div>'), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  String _formatDate(DateTime date) {
    final months = [
      '一月', '二月', '三月', '四月', '五月', '六月',
      '七月', '八月', '九月', '十月', '十一月', '十二月'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
