import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_platform/universal_platform.dart';
import '../../presentation/pages/desktop/desktop_shell.dart';
import '../../presentation/pages/mobile/mobile_shell.dart';
import '../../presentation/pages/desktop/dashboard_page.dart';
import '../../presentation/pages/desktop/settings_page.dart';
import '../../presentation/pages/desktop/feed_list_page.dart';
import '../../presentation/pages/desktop/article_detail_page.dart';
import '../../presentation/pages/desktop/explore_page.dart' as desktop_explore;
import '../../presentation/pages/desktop/bookmarks_page.dart' as desktop_bookmarks;

final router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        final isDesktop = UniversalPlatform.isDesktop ||
            UniversalPlatform.isWindows ||
            UniversalPlatform.isMacOS;
        final currentPath = state.uri.path;
        if (isDesktop) {
          return DesktopShell(child: child);
        }
        return MobileShell(child: child, currentPath: currentPath);
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardPage(),
          ),
        ),
        GoRoute(
          path: '/explore',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: desktop_explore.ExplorePage(),
          ),
        ),
        GoRoute(
          path: '/bookmarks',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: desktop_bookmarks.BookmarksPage(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsPage(),
          ),
        ),
        GoRoute(
          path: '/category/:id',
          pageBuilder: (context, state) => NoTransitionPage(
            child: FeedListPage(
              categoryId: state.pathParameters['id'],
            ),
          ),
        ),
        GoRoute(
          path: '/feed/:id',
          pageBuilder: (context, state) => NoTransitionPage(
            child: FeedListPage(
              feedId: state.pathParameters['id'],
            ),
          ),
        ),
        GoRoute(
          path: '/article/:id',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: ArticleDetailPage(
              articleId: state.pathParameters['id']!,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
      ],
    ),
  ],
);
