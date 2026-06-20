import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/feed_model.dart';
import '../../blocs/feed/feed_bloc.dart';
import '../../blocs/feed/feed_event.dart';
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

          // Categories + Feeds section
          BlocBuilder<FeedBloc, FeedState>(
            builder: (context, state) {
              if (state is FeedsLoaded) {
                return _CategoriesWithFeedsSection(
                  categories: state.categories,
                  feeds: state.feeds,
                  secondaryColor: textSecondaryColor,
                  textColor: textColor,
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected ? selectedBgColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go(path),
          hoverColor: isDark
              ? AppColors.darkSurfaceContainerHigh.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.5),
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

class _CategoriesWithFeedsSection extends StatelessWidget {
  final List<CategoryModel> categories;
  final List<FeedModel> feeds;
  final Color secondaryColor;
  final Color textColor;

  const _CategoriesWithFeedsSection({
    required this.categories,
    required this.feeds,
    required this.secondaryColor,
    required this.textColor,
  });

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddCategoryDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final headerTextColor = isDark
        ? const Color(0xFF9a9a9a)
        : const Color(0xFF717782);

    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '分类',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: headerTextColor,
                    letterSpacing: 1.5,
                  ),
                ),
                InkWell(
                  onTap: () => _showAddCategoryDialog(context),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.add,
                      size: 18,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Categories with their feeds
          ...categories.map((cat) {
            final categoryFeeds = feeds.where((f) => f.categoryId == cat.id).toList();
            if (categoryFeeds.isEmpty) return const SizedBox.shrink();
            return _CategoryWithFeedsItem(
              category: cat,
              feeds: categoryFeeds,
              textColor: textColor,
              secondaryColor: secondaryColor,
            );
          }),
        ],
      ),
    );
  }
}

class _CategoryWithFeedsItem extends StatefulWidget {
  final CategoryModel category;
  final List<FeedModel> feeds;
  final Color textColor;
  final Color secondaryColor;

  const _CategoryWithFeedsItem({
    required this.category,
    required this.feeds,
    required this.textColor,
    required this.secondaryColor,
  });

  @override
  State<_CategoryWithFeedsItem> createState() => _CategoryWithFeedsItemState();
}

class _CategoryWithFeedsItemState extends State<_CategoryWithFeedsItem> {
  bool _expanded = true;

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = _parseColor(widget.category.color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          hoverColor: isDark
              ? AppColors.darkSurfaceContainerHigh.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_more : Icons.chevron_right,
                  size: 18,
                  color: widget.secondaryColor,
                ),
                const SizedBox(width: 8),
                // Gradient dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        categoryColor.withValues(alpha: 0.9),
                        categoryColor,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.category.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: widget.secondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Feeds under this category
        if (_expanded)
          ...widget.feeds.map((feed) => _FeedItem(
                feed: feed,
                secondaryColor: widget.secondaryColor,
              )),
      ],
    );
  }
}

class _FeedItem extends StatelessWidget {
  final FeedModel feed;
  final Color secondaryColor;

  const _FeedItem({required this.feed, required this.secondaryColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => context.go('/feed/${feed.id}'),
      hoverColor: isDark
          ? AppColors.darkSurfaceContainerHigh.withValues(alpha: 0.5)
          : Colors.white.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(left: 48, right: 16, top: 6, bottom: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                feed.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: secondaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _nameController = TextEditingController();
  String _selectedColor = '#0061A4';
  bool _loading = false;
  String? _error;

  final List<String> _colorOptions = [
    '#0061A4', // blue
    '#b1c8e8', // light blue
    '#4a607c', // steel blue
    '#713700', // orange
    '#ffdcc6', // light orange
    '#00497d', // dark blue
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '请输入分类名称');
      return;
    }
    setState(() => _loading = true);

    try {
      context.read<FeedBloc>().add(AddCategory(name, _selectedColor));
      // Allow BLoC to process and emit new state before closing dialog
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '添加失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final secondaryColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return AlertDialog(
      backgroundColor: surfaceColor,
      title: Text('新建分类', style: TextStyle(color: textColor)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: '分类名称',
                labelStyle: TextStyle(color: secondaryColor),
                hintText: '例如：科技前沿',
                hintStyle: TextStyle(color: secondaryColor.withValues(alpha: 0.5)),
              ),
            ),
            const SizedBox(height: 20),
            Text('选择颜色', style: TextStyle(color: secondaryColor, fontSize: 12)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colorOptions.map((color) {
                final parsed = Color(int.parse(color.replaceFirst('#', '0xFF')));
                final isSelected = color == _selectedColor;
                return InkWell(
                  onTap: () => setState(() => _selectedColor = color),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: parsed,
                      border: isSelected
                          ? Border.all(color: textColor, width: 2)
                          : null,
                    ),
                    child: isSelected
                        ? Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _nameController.text.isEmpty ? '分类预览' : _nameController.text,
                  style: TextStyle(color: secondaryColor, fontSize: 13),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消', style: TextStyle(color: secondaryColor)),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _addCategory,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('创建'),
        ),
      ],
    );
  }
}
