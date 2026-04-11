import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBackPressed;
  final String? title;
  final List<Widget>? actions;
  final bool showBackButton;

  const TopNavBar({
    super.key,
    this.onBackPressed,
    this.title,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.8)
        : AppColors.surface.withValues(alpha: 0.8);
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? AppColors.darkOutlineVariant.withValues(alpha: 0.15)
                    : AppColors.outlineVariant.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              // Left: Back button
              if (showBackButton && onBackPressed != null) ...[
                TextButton.icon(
                  onPressed: onBackPressed,
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text('返回列表'),
                  style: TextButton.styleFrom(
                    foregroundColor: textColor,
                  ),
                ),
              ] else if (title != null) ...[
                Text(
                  title!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const Spacer(),

              // Right: Action icons
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}

class TopNavBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const TopNavBarAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Tooltip(
      message: tooltip ?? '',
      child: IconButton(
        icon: Icon(icon, size: 24),
        onPressed: onTap,
        color: secondaryColor,
      ),
    );
  }
}

class TopNavBarDivider extends StatelessWidget {
  const TopNavBarDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 24,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: isDark
          ? AppColors.darkOutlineVariant.withValues(alpha: 0.3)
          : AppColors.outlineVariant.withValues(alpha: 0.3),
    );
  }
}
