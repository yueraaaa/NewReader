import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_colors.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = info.version);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final secondaryColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;

    return Scaffold(
      backgroundColor: surfaceColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: secondaryColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: textColor),
                  onPressed: () => context.go('/'),
                ),
                const SizedBox(width: 16),
                Text(
                  '帮助中心',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HelpSection(
                    title: '添加订阅源',
                    content: '在侧边栏点击"探索"，使用 RSS/Atom URL 添加订阅源。支持 OPML 导入导出，方便迁移。',
                    icon: Icons.add_circle_outline,
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                  ),
                  const SizedBox(height: 24),
                  _HelpSection(
                    title: '阅读文章',
                    content: '点击任意订阅源查看文章列表，点击文章进入阅读视图。支持深色模式，可自定义字体大小和阅读速度。',
                    icon: Icons.article_outlined,
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                  ),
                  const SizedBox(height: 24),
                  _HelpSection(
                    title: 'AI 功能',
                    content: '在阅读界面可使用 AI 翻译和摘要功能。需要先在设置中配置 Minimax API Key。',
                    icon: Icons.auto_awesome_outlined,
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                  ),
                  const SizedBox(height: 24),
                  _HelpSection(
                    title: '云端同步',
                    content: '登录后，订阅源和阅读进度自动同步到云端。支持 Apple ID、GitHub 和邮箱登录。',
                    icon: Icons.cloud_sync_outlined,
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                  ),
                  const SizedBox(height: 24),
                  _HelpSection(
                    title: 'OPML 导入/导出',
                    content: '在设置页面可以导入 OPML 文件或导出当前订阅源列表，方便备份和迁移。',
                    icon: Icons.import_export,
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                  ),
                  const SizedBox(height: 48),
                  Center(
                    child: Text(
                      'Real Reader v$_version',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color textColor;
  final Color secondaryColor;

  const _HelpSection({
    required this.title,
    required this.content,
    required this.icon,
    required this.textColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: secondaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: textColor, size: 24),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(
                  fontSize: 15,
                  color: secondaryColor,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
