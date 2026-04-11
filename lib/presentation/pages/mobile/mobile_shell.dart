import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../blocs/article/article_bloc.dart';
import '../../blocs/article/article_state.dart';
import '../../widgets/mobile/bottom_nav_bar.dart';

class MobileShell extends StatefulWidget {
  final Widget child;
  final String currentPath;

  const MobileShell({
    super.key,
    required this.child,
    this.currentPath = '/',
  });

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  int get _currentIndex {
    switch (widget.currentPath) {
      case '/':
        return 0;
      case '/explore':
        return 1;
      case '/bookmarks':
        return 2;
      case '/profile':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTopAppBar(context),
          _buildReadingProgressBar(),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
    );
  }

  Widget _buildReadingProgressBar() {
    return BlocBuilder<ArticleBloc, ArticleState>(
      builder: (context, state) {
        double progress = 0.0;
        if (state is ArticlesLoaded && state.articles.isNotEmpty) {
          final firstArticle = state.articles.first;
          progress = firstArticle.readProgress;
        }
        return Container(
          height: 2,
          color: AppColors.surfaceContainerHighest,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(color: AppColors.primary),
          ),
        );
      },
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.8)
        : AppColors.surface.withValues(alpha: 0.8);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
          Expanded(
            child: Text(
              'REAL READER',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
