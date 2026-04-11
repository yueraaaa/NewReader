import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ReadingProgressBar extends StatelessWidget {
  final double progress;

  const ReadingProgressBar({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final tintColor = isDark ? AppColors.darkPrimary : AppColors.surfaceTint;

    return Positioned(
      top: 0,
      left: 256, // SideNavBar width
      right: 0,
      height: 2,
      child: Container(
        color: isDark
            ? AppColors.darkOutlineVariant.withValues(alpha: 0.2)
            : AppColors.outlineVariant.withValues(alpha: 0.2),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, tintColor],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
