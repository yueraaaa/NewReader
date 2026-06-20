import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/article_model.dart';
import '../../blocs/ai/ai_bloc.dart';
import '../../blocs/ai/ai_event.dart';
import '../../blocs/ai/ai_state.dart';

class AiToolkitPanel extends StatelessWidget {
  final ArticleModel article;

  const AiToolkitPanel({
    super.key,
    required this.article,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.darkSurfaceContainerLow
        : AppColors.surfaceContainerLow;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final secondaryColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      width: 160,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.bolt,
                size: 16,
                color: primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'AI 助手',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // AI Buttons
          BlocBuilder<AiBloc, AiState>(
            builder: (context, state) {
              return Column(
                children: [
                  _AiButton(
                    icon: Icons.summarize,
                    label: '摘要',
                    isLoading: state.isSummarizing,
                    onTap: () {
                      context.read<AiBloc>().add(SummarizeArticle(article));
                    },
                  ),
                  const SizedBox(height: 6),
                  _AiButton(
                    icon: Icons.translate,
                    label: '翻译',
                    isLoading: state.isTranslating,
                    onTap: () {
                      context.read<AiBloc>().add(TranslateArticle(article));
                    },
                  ),
                  const SizedBox(height: 6),
                  _AiButton(
                    icon: Icons.volume_up,
                    label: '朗读',
                    isLoading: state.isReadingAloud,
                    onTap: () {
                      context.read<AiBloc>().add(ReadArticleAloud(article));
                    },
                  ),
                ],
              );
            },
          ),

          // Results display
          BlocBuilder<AiBloc, AiState>(
            builder: (context, state) {
              if (state.error != null) {
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkErrorContainer : AppColors.errorContainer)
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Text(
                      state.error!,
                      style: TextStyle(
                        color: isDark ? AppColors.darkOnErrorContainer : AppColors.onErrorContainer,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }

              if (state.summary != null) {
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: _AiResultSection(
                    title: '摘要结果',
                    content: state.summary!,
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                  ),
                );
              }

              if (state.translation != null) {
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: _AiResultSection(
                    title: '翻译结果',
                    content: state.translation!,
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

class _AiButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _AiButton({
    required this.icon,
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final bgColor = isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHigh;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryColor,
                  ),
                )
              else
                Icon(icon, size: 14, color: primaryColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiResultSection extends StatelessWidget {
  final String title;
  final String content;
  final Color textColor;
  final Color secondaryColor;

  const _AiResultSection({
    required this.title,
    required this.content,
    required this.textColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: secondaryColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurfaceContainerLowest
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: SelectableText(
            content,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
