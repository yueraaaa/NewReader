import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../blocs/feed/feed_bloc.dart';
import '../../blocs/feed/feed_state.dart';
import '../../blocs/feed/feed_event.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_event.dart';
import '../../blocs/article/article_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';

class DesktopShell extends StatefulWidget {
  final Widget child;
  final String currentPath;

  const DesktopShell({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  String? _selectedFeedId;
  String? _selectedCategoryId;
  double _readingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    context.read<FeedBloc>().add(LoadFeeds());
  }

  void _updateReadingProgress(double progress) {
    setState(() {
      _readingProgress = progress;
    });
  }

  void _selectFeed(String feedId) {
    setState(() {
      _selectedFeedId = feedId;
      _selectedCategoryId = null;
    });
    context.read<ArticleBloc>().add(LoadArticles(feedId: feedId));
  }

  void _selectCategory(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedFeedId = null;
    });
    context.read<ArticleBloc>().add(LoadArticles(categoryId: categoryId));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow;
    final borderColor = isDark
        ? AppColors.darkOutlineVariant.withValues(alpha: 0.3)
        : AppColors.outlineVariant.withValues(alpha: 0.3);
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final secondaryColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Scaffold(
      body: Column(
        children: [
          // Reading progress bar
          Container(
            height: 2,
            color: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHigh,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _readingProgress,
              child: Container(
                height: 2,
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
            ),
          ),
          // Main content: Left nav + Middle list + Right detail
          Expanded(
            child: Row(
              children: [
                // Left: SideNavBar (256px fixed)
                SizedBox(
                  width: 256,
                  child: _DesktopSideNav(
                    currentPath: widget.currentPath,
                    onFeedSelected: _selectFeed,
                    onCategorySelected: _selectCategory,
                  ),
                ),
                // Vertical divider
                Container(width: 0.5, color: borderColor),
                // Middle: Article List Pane (show on dashboard or when feed/category selected)
                if (_selectedFeedId != null || _selectedCategoryId != null || widget.currentPath == '/') ...[
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 200, maxWidth: 400),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          border: Border(
                            right: BorderSide(color: borderColor, width: 0.5),
                          ),
                        ),
                        child: _ArticleListPane(
                          selectedFeedId: _selectedFeedId,
                          selectedCategoryId: _selectedCategoryId,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                        ),
                      ),
                    ),
                  ),
                  // Vertical divider
                  Container(width: 0.5, color: borderColor),
                ],
                // Right: Article Detail (flexible)
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollUpdateNotification) {
                        final scrollExtent = notification.metrics.maxScrollExtent;
                        final currentScroll = notification.metrics.pixels;
                        if (scrollExtent > 0) {
                          _updateReadingProgress(currentScroll / scrollExtent);
                        }
                      }
                      return false;
                    },
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopSideNav extends StatelessWidget {
  final String currentPath;
  final void Function(String feedId) onFeedSelected;
  final void Function(String categoryId) onCategorySelected;

  const _DesktopSideNav({
    required this.currentPath,
    required this.onFeedSelected,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final secondaryColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
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
              color: secondaryColor,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Nav items
          _SideNavItem(
            icon: Icons.dashboard,
            label: '仪表盘',
            isSelected: currentPath == '/',
            textColor: textColor,
            secondaryColor: secondaryColor,
            onTap: () => context.go('/'),
          ),
          _SideNavItem(
            icon: Icons.explore,
            label: '探索',
            isSelected: currentPath == '/explore',
            textColor: textColor,
            secondaryColor: secondaryColor,
            onTap: () => context.go('/explore'),
          ),
          _SideNavItem(
            icon: Icons.bookmark,
            label: '收藏',
            isSelected: currentPath == '/bookmarks',
            textColor: textColor,
            secondaryColor: secondaryColor,
            onTap: () => context.go('/bookmarks'),
          ),
          _SideNavItem(
            icon: Icons.settings,
            label: '设置',
            isSelected: currentPath == '/settings',
            textColor: textColor,
            secondaryColor: secondaryColor,
            onTap: () => context.go('/settings'),
          ),

          // Divider between settings and categories
          Divider(color: isDark
              ? AppColors.darkOutlineVariant.withValues(alpha: 0.3)
              : AppColors.outlineVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 4),

          // Categories + Feeds (scrollable)
          Expanded(
            child: SingleChildScrollView(
              child: BlocBuilder<FeedBloc, FeedState>(
                builder: (context, state) {
                  if (state is FeedsLoaded) {
                    return _CategoriesSection(
                      categories: state.categories,
                      feeds: state.feeds,
                      secondaryColor: secondaryColor,
                      textColor: textColor,
                      primaryColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                      onFeedSelected: onFeedSelected,
                      onCategorySelected: onCategorySelected,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),

          // Divider
          Divider(color: isDark
              ? AppColors.darkOutlineVariant.withValues(alpha: 0.3)
              : AppColors.outlineVariant.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.md),

          // Account + Help
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return _SideNavItem(
                  icon: Icons.account_circle,
                  label: state.user.email ?? '账户',
                  isSelected: false,
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                  onTap: () => context.go('/settings'),
                );
              }
              return _SideNavItem(
                icon: Icons.account_circle,
                label: '账户',
                isSelected: false,
                textColor: textColor,
                secondaryColor: secondaryColor,
                onTap: () => context.go('/settings'),
              );
            },
          ),
          _SideNavItem(
            icon: Icons.help,
            label: '帮助',
            isSelected: currentPath == '/help',
            textColor: textColor,
            secondaryColor: secondaryColor,
            onTap: () => context.go('/help'),
          ),
        ],
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color textColor;
  final Color secondaryColor;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.textColor,
    required this.secondaryColor,
    required this.onTap,
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
          onTap: onTap,
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

class _CategoriesSection extends StatelessWidget {
  final List categories;
  final List feeds;
  final Color secondaryColor;
  final Color textColor;
  final Color primaryColor;
  final void Function(String feedId) onFeedSelected;
  final void Function(String categoryId) onCategorySelected;

  const _CategoriesSection({
    required this.categories,
    required this.feeds,
    required this.secondaryColor,
    required this.textColor,
    required this.primaryColor,
    required this.onFeedSelected,
    required this.onCategorySelected,
  });

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddCategoryDialog(),
    );
  }

  List<Widget> _buildCategoryList(List categories, List feeds) {
    // Deduplicate categories by name, sort so "未分类" comes first
    final seenNames = <String>{};
    final processedCategories = <Widget>[];

    // First pass: add "未分类" if exists
    for (final cat in categories) {
      if (cat.name == '未分类') {
        if (!seenNames.contains(cat.name)) {
          seenNames.add(cat.name);
          final categoryFeeds = feeds.where((f) => f.categoryId == cat.id).toList();
          processedCategories.add(_CategoryItem(
            category: cat,
            feeds: categoryFeeds,
            secondaryColor: secondaryColor,
            textColor: textColor,
            primaryColor: primaryColor,
            allCategories: categories,
            onFeedSelected: onFeedSelected,
            isCompact: true,
          ));
        }
        break;
      }
    }

    // Second pass: add remaining categories
    for (final cat in categories) {
      if (seenNames.contains(cat.name)) continue;
      seenNames.add(cat.name);

      final categoryFeeds = feeds.where((f) => f.categoryId == cat.id).toList();
      processedCategories.add(_CategoryItem(
        category: cat,
        feeds: categoryFeeds,
        secondaryColor: secondaryColor,
        textColor: textColor,
        primaryColor: primaryColor,
        allCategories: categories,
        onFeedSelected: onFeedSelected,
        isCompact: cat.name == '未分类',
      ));
    }
    return processedCategories;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerTextColor = isDark
        ? const Color(0xFF9a9a9a)
        : const Color(0xFF717782);

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '分类',
                  style: TextStyle(
                    fontSize: 13,
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
          const SizedBox(height: 4),
          ..._buildCategoryList(categories, feeds),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatefulWidget {
  final dynamic category;
  final List feeds;
  final Color secondaryColor;
  final Color textColor;
  final Color primaryColor;
  final List allCategories;
  final void Function(String feedId) onFeedSelected;
  final bool isCompact;

  const _CategoryItem({
    required this.category,
    required this.feeds,
    required this.secondaryColor,
    required this.textColor,
    required this.primaryColor,
    required this.allCategories,
    required this.onFeedSelected,
    this.isCompact = false,
  });

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
  bool _expanded = true;

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  void _showRenameCategoryDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.category.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名分类'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: '分类名称')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<FeedBloc>().add(UpdateCategory(widget.category.id, controller.text.trim()));
                Navigator.pop(ctx);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除分类'),
        content: Text('确定要删除分类 "${widget.category.name}" 吗？该分类下的订阅源将移至"未分类"。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<FeedBloc>().add(DeleteCategory(widget.category.id));
              Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = _parseColor(widget.category.color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          hoverColor: isDark
              ? AppColors.darkSurfaceContainerHigh.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_more : Icons.chevron_right,
                  size: 18,
                  color: widget.secondaryColor,
                ),
                const SizedBox(width: 8),
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
                      fontSize: widget.isCompact ? 12 : 14,
                      fontWeight: FontWeight.w500,
                      color: widget.secondaryColor,
                    ),
                  ),
                ),
                if (widget.category.name != '未分类')
                  PopupMenuButton<String>(
                    tooltip: null,
                    icon: Icon(Icons.more_vert, size: 16, color: widget.secondaryColor),
                    itemBuilder: (context) => [
                      _buildMenuItem('rename', '重命名', widget.secondaryColor),
                      _buildMenuItem('delete', '删除', widget.secondaryColor),
                    ],
                    onSelected: (value) {
                      if (value == 'rename') {
                        _showRenameCategoryDialog(context);
                      } else if (value == 'delete') {
                        _showDeleteCategoryDialog(context);
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...widget.feeds.map((feed) => _FeedItemWithMenu(
                feed: feed,
                secondaryColor: widget.secondaryColor,
                allCategories: widget.feeds,
                onFeedSelected: widget.onFeedSelected,
              )),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, String label, Color textColor) {
    return PopupMenuItem<String>(
      value: value,
      height: 36,
      child: Text(
        label,
        style: TextStyle(fontSize: 13, color: textColor),
      ),
    );
  }
}

class _ArticleListPane extends StatefulWidget {
  final String? selectedFeedId;
  final String? selectedCategoryId;
  final Color textColor;
  final Color secondaryColor;

  const _ArticleListPane({
    required this.selectedFeedId,
    required this.selectedCategoryId,
    required this.textColor,
    required this.secondaryColor,
  });

  @override
  State<_ArticleListPane> createState() => _ArticleListPaneState();
}

class _ArticleListPaneState extends State<_ArticleListPane> {
  String _selectedFilter = '全部';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
    });
  }

  void _showAddFeedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: BlocProvider.of<FeedBloc>(this.context),
        child: _AddFeedDialog(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) {
          return '刚刚';
        }
        return '${diff.inMinutes}分钟前';
      }
      return '${diff.inHours}小时前';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.8)
        : AppColors.surface.withValues(alpha: 0.8);
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark
        ? AppColors.darkOutlineVariant.withValues(alpha: 0.3)
        : AppColors.outlineVariant.withValues(alpha: 0.3);
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final secondaryColor = widget.secondaryColor;

    return Column(
      children: [
        // TopAppBar for middle pane
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: headerBg,
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 0.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    '今日精选',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.textColor,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => _showAddFeedDialog(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            '添加订阅',
                            style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Search bar (smaller)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(color: widget.textColor, fontSize: 13),
              decoration: InputDecoration(
                hintText: '搜索文章',
                hintStyle: TextStyle(color: widget.secondaryColor, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: widget.secondaryColor, size: 16),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ),
        // Filter buttons (smaller)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _FilterChip(
                label: '全部',
                isSelected: _selectedFilter == '全部',
                primaryColor: primaryColor,
                onTap: () => setState(() => _selectedFilter = '全部'),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: '未读',
                isSelected: _selectedFilter == '未读',
                primaryColor: primaryColor,
                onTap: () => setState(() => _selectedFilter = '未读'),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: '长文',
                isSelected: _selectedFilter == '长文',
                primaryColor: primaryColor,
                onTap: () => setState(() => _selectedFilter = '长文'),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: '已读',
                isSelected: _selectedFilter == '已读',
                primaryColor: primaryColor,
                onTap: () => setState(() => _selectedFilter = '已读'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Article list
        Expanded(
          child: BlocBuilder<ArticleBloc, ArticleState>(
            builder: (context, state) {
              if (state is ArticlesLoaded) {
                // Filter articles based on search query and read status
                var filteredArticles = state.articles;
                if (_searchQuery.isNotEmpty) {
                  filteredArticles = filteredArticles.where((article) {
                    return article.title.toLowerCase().contains(_searchQuery) ||
                        (article.description?.toLowerCase().contains(_searchQuery) ?? false);
                  }).toList();
                }
                // Filter by read status
                if (_selectedFilter == '未读') {
                  filteredArticles = filteredArticles.where((a) => !a.isRead).toList();
                } else if (_selectedFilter == '已读') {
                  filteredArticles = filteredArticles.where((a) => a.isRead).toList();
                } else if (_selectedFilter == '长文') {
                  filteredArticles = filteredArticles.where((a) => a.readingTimeMinutes >= 5).toList();
                }
                if (filteredArticles.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_outlined, size: 48, color: secondaryColor),
                        const SizedBox(height: 16),
                        Text(
                          '暂无文章',
                          style: TextStyle(color: secondaryColor),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredArticles.length,
                  separatorBuilder: (_, __) => Divider(color: borderColor, height: 1),
                  itemBuilder: (context, index) {
                    final article = filteredArticles[index];
                    return InkWell(
                      onTap: () {
                        if (!article.isRead) {
                          context.read<ArticleBloc>().add(MarkArticleRead(article.id, true));
                        }
                        context.go('/article/${article.id}');
                      },
                      child: Opacity(
                        opacity: article.isRead ? 0.5 : 1.0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _formatDate(article.publishedAt ?? article.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: secondaryColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  InkWell(
                                    onTap: () {
                                      context.read<ArticleBloc>().add(
                                        MarkArticleFavorite(article.id, !article.isFavorite),
                                      );
                                    },
                                    child: Icon(
                                      article.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                                      size: 18,
                                      color: article.isFavorite ? primaryColor : secondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      article.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: widget.textColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                article.description ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryColor,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
              if (state is ArticleLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rss_feed, size: 48, color: secondaryColor),
                    const SizedBox(height: 16),
                    Text(
                      '选择一个订阅源',
                      style: TextStyle(color: secondaryColor),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _nameController = TextEditingController();
  String _selectedColor = '#E53935';
  bool _loading = false;
  String? _error;

  final List<String> _colorOptions = [
    '#E53935', // red
    '#FF7043', // deep orange
    '#FF9800', // orange
    '#FFEB3B', // yellow
    '#4CAF50', // green
    '#00BCD4', // cyan
    '#2196F3', // blue
    '#9C27B0', // purple
    '#E91E63', // pink
    '#795548', // brown
    '#607D8B', // blue grey
    '#0061A4', // dark blue
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
      title: Text('新建分类', style: TextStyle(color: textColor, fontSize: 16, fontStyle: FontStyle.normal)),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                labelText: '分类名称',
                labelStyle: TextStyle(color: secondaryColor, fontSize: 14),
                hintText: '例如：科技前沿',
                hintStyle: TextStyle(color: secondaryColor.withValues(alpha: 0.5), fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),
            Text('选择颜色', style: TextStyle(color: secondaryColor, fontSize: 12)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colorOptions.map((color) {
                final parsed = Color(int.parse(color.replaceFirst('#', '0xFF')));
                final isSelected = color == _selectedColor;
                return InkWell(
                  onTap: () => setState(() => _selectedColor = color),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: parsed,
                      border: isSelected
                          ? Border.all(color: textColor, width: 2)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
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

class _FeedItemWithMenu extends StatelessWidget {
  final dynamic feed;
  final Color secondaryColor;
  final List allCategories;
  final void Function(String feedId) onFeedSelected;

  const _FeedItemWithMenu({
    required this.feed,
    required this.secondaryColor,
    required this.allCategories,
    required this.onFeedSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onFeedSelected(feed.id),
      child: Padding(
        padding: const EdgeInsets.only(left: 48, right: 16, top: 6, bottom: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                feed.title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: secondaryColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: null,
              icon: Icon(Icons.more_vert, size: 16, color: secondaryColor),
              itemBuilder: (context) => [
                _buildMenuItem('rename', '重命名', secondaryColor),
                _buildMenuItem('move', '移动分组', secondaryColor),
                _buildMenuItem('delete', '删除', secondaryColor),
              ],
              onSelected: (value) {
                if (value == 'rename') {
                  _showRenameFeedDialog(context);
                } else if (value == 'move') {
                  _showMoveFeedDialog(context);
                } else if (value == 'delete') {
                  _showDeleteFeedDialog(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameFeedDialog(BuildContext context) {
    final controller = TextEditingController(text: feed.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名订阅源'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: '名称')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<FeedBloc>().add(UpdateFeed(feed.id, title: controller.text.trim()));
                Navigator.pop(ctx);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showMoveFeedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('移动分组'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: allCategories.map<Widget>((cat) {
              return ListTile(
                title: Text(cat.name),
                onTap: () {
                  context.read<FeedBloc>().add(UpdateFeed(feed.id, categoryId: cat.id));
                  Navigator.pop(ctx);
                },
                trailing: cat.id == feed.categoryId ? const Icon(Icons.check) : null,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ],
      ),
    );
  }

  void _showDeleteFeedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除订阅源'),
        content: Text('确定要删除 "${feed.title}" 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<ArticleBloc>().add(DeleteArticlesByFeedId(feed.id));
              context.read<FeedBloc>().add(DeleteFeed(feed.id));
              Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, String label, Color textColor) {
    return PopupMenuItem<String>(
      value: value,
      height: 36,
      child: Text(
        label,
        style: TextStyle(fontSize: 13, color: textColor),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color primaryColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isSelected
        ? primaryColor.withValues(alpha: 0.15)
        : (isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHigh);
    final textColor = isSelected
        ? primaryColor
        : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _AddFeedDialog extends StatefulWidget {
  @override
  State<_AddFeedDialog> createState() => _AddFeedDialogState();
}

class _AddFeedDialogState extends State<_AddFeedDialog> {
  final _urlController = TextEditingController();
  String? _selectedCategoryId;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _addFeed() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = '请输入 RSS 订阅源地址');
      return;
    }
    setState(() => _loading = true);

    // Listen to FeedBloc state changes
    final feedBloc = context.read<FeedBloc>();
    late StreamSubscription subscription;

    subscription = feedBloc.stream.listen((state) {
      if (state is FeedsLoaded) {
        // Success - feeds were loaded, subscription is added
        subscription.cancel();
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('订阅添加成功'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (state is FeedError) {
        subscription.cancel();
        setState(() {
          _loading = false;
          _error = state.message;
        });
      }
    });

    feedBloc.add(AddFeed(url, categoryId: _selectedCategoryId));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final secondaryColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return AlertDialog(
      backgroundColor: surfaceColor,
      title: Text('添加订阅', style: TextStyle(color: textColor, fontSize: 16, fontStyle: FontStyle.normal)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _urlController,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'RSS 订阅源地址',
                labelStyle: TextStyle(color: secondaryColor, fontSize: 14),
                hintText: '例如：https://example.com/feed.xml',
                hintStyle: TextStyle(color: secondaryColor.withValues(alpha: 0.5), fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            Text('选择分类（可选）', style: TextStyle(color: secondaryColor, fontSize: 12)),
            const SizedBox(height: 6),
            BlocBuilder<FeedBloc, FeedState>(
              builder: (context, state) {
                if (state is FeedsLoaded) {
                  // Deduplicate categories by name, filter out "未分类" from the list
                  final seenNames = <String>{};
                  final uniqueCategories = state.categories
                      .where((cat) {
                        if (cat.name == '未分类') return false;
                        if (seenNames.contains(cat.name)) return false;
                        seenNames.add(cat.name);
                        return true;
                      })
                      .toList();
                  return Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: secondaryColor.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String?>(
                      value: _selectedCategoryId,
                      hint: Text('未分类', style: TextStyle(color: secondaryColor, fontSize: 14)),
                      isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: surfaceColor,
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('未分类', style: TextStyle(color: textColor, fontSize: 14)),
                        ),
                        ...uniqueCategories.map((cat) => DropdownMenuItem<String?>(
                              value: cat.id,
                              child: Text(cat.name, style: TextStyle(color: textColor, fontSize: 14)),
                            )),
                      ],
                      onChanged: (value) => setState(() => _selectedCategoryId = value),
                    ),
                  );
                }
                return const SizedBox();
              },
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
          onPressed: _loading ? null : _addFeed,
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('添加'),
        ),
      ],
    );
  }
}
