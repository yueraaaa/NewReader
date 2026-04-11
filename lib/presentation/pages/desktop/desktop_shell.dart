import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../blocs/feed/feed_bloc.dart';
import '../../blocs/feed/feed_event.dart';
import '../../widgets/desktop/side_nav_bar.dart';
import '../../widgets/desktop/top_nav_bar.dart';
import '../../widgets/desktop/reading_progress_bar.dart';

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
  double _readingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    // Load feeds when shell initializes
    context.read<FeedBloc>().add(LoadFeeds());
  }

  void _updateReadingProgress(double progress) {
    setState(() {
      _readingProgress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(color: surfaceColor),

          // Side nav bar
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: SideNavBar(currentPath: widget.currentPath),
          ),

          // Reading progress bar
          ReadingProgressBar(progress: _readingProgress),

          // Main content
          Positioned(
            left: 256, // SideNavBar width
            top: 0,
            right: 0,
            bottom: 0,
            child: Column(
              children: [
                // Top nav bar
                const TopNavBar(showBackButton: false),

                // Page content
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
