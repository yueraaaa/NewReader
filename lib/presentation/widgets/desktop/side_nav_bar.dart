import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/category_model.dart';
import '../../blocs/feed/feed_bloc.dart';
import '../../blocs/feed/feed_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';

class SideNavBar extends StatelessWidget {
  final String currentPath;

  const SideNavBar({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final textSecondaryColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final logoColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      width: AppSpacing.sideNavWidth,
      color: bgColor,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Text(
            'REAL READER',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: logoColor,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'The Editorial Sanctuary',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textSecondaryColor,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Nav items
          _NavItem(
            icon: Icons.dashboard,
            label: '仪表盘',
            path: '/',
            isSelected: currentPath == '/',
            textColor: textColor,
            secondaryColor: textSecondaryColor,
          ),
          _NavItem(
            icon: Icons.explore,
            label: '探索',
            path: '/explore',
            isSelected: currentPath == '/explore',
            textColor: textColor,
            secondaryColor: textSecondaryColor,
          ),
          _NavItem(
            icon: Icons.bookmark,
            label: '收藏',
            path: '/bookmarks',
            isSelected: currentPath == '/bookmarks',
            textColor: textColor,
            secondaryColor: textSecondaryColor,
          ),
          _NavItem(
            icon: Icons.settings,
            label: '设置',
            path: '/settings',
            isSelected: currentPath == '/settings',
            textColor: textColor,
            secondaryColor: textSecondaryColor,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Categories section
          BlocBuilder<FeedBloc, FeedState>(
            builder: (context, state) {
              if (state is FeedsLoaded) {
                return _CategoriesSection(
                  categories: state.categories,
                  secondaryColor: textSecondaryColor,
                );
              }
              return const SizedBox.shrink();
            },
          ),

          const Spacer(),

          // Divider
          Divider(color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.md),

          // Account + Help
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return _NavItem(
                  icon: Icons.account_circle,
                  label: state.user.email ?? '账户',
                  path: '/settings',
                  isSelected: false,
                  textColor: textColor,
                  secondaryColor: textSecondaryColor,
                );
              }
              return _NavItem(
                icon: Icons.account_circle,
                label: '账户',
                path: '/settings',
                isSelected: false,
                textColor: textColor,
                secondaryColor: textSecondaryColor,
              );
            },
          ),
          _NavItem(
            icon: Icons.help,
            label: '帮助',
            path: '/help',
            isSelected: false,
            textColor: textColor,
            secondaryColor: textSecondaryColor,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final bool isSelected;
  final Color textColor;
  final Color secondaryColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.isSelected,
    required this.textColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBgColor = isDark
        ? AppColors.darkSurfaceContainerHigh.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.5);
    final selectedColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isSelected ? selectedBgColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go(path),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? selectedColor : secondaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? selectedColor : secondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  final List<CategoryModel> categories;
  final Color secondaryColor;

  const _CategoriesSection({
    required this.categories,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '分类',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: secondaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: () {
                  // TODO: add category dialog
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        ...categories.map((cat) => _CategoryItem(category: cat)),
      ],
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final CategoryModel category;

  const _CategoryItem({required this.category});

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go('/category/${category.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _parseColor(category.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
