import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../blocs/settings/settings_event.dart';
import '../../blocs/settings/settings_state.dart';
import '../../blocs/feed/feed_bloc.dart';
import '../../blocs/feed/feed_state.dart';
import '../../../data/services/opml_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info section
          _buildUserInfo(context),

          const SizedBox(height: 32),

          // OPML section
          _buildSectionTitle(context, '订阅管理'),
          const SizedBox(height: 16),
          _buildOPMLSection(context),

          const SizedBox(height: 32),

          // Theme section
          _buildSectionTitle(context, '外观'),
          const SizedBox(height: 16),
          _buildThemeSection(context),

          const SizedBox(height: 32),

          // Sign out
          _buildSignOutButton(context),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reader',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '阅读器用户',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }

  Widget _buildOPMLSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('导入 OPML'),
            subtitle: const Text('从其他阅读器导入订阅'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showOPMLImportDialog();
            },
          ),
          Divider(
            height: 1,
            indent: 56,
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('导出 OPML'),
            subtitle: const Text('备份您的订阅列表'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showOPMLExportDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: const Text('主题模式'),
                subtitle: Text(_getThemeModeName(state.themeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showThemeModeDialog(context, state.themeMode);
                },
              ),
              Divider(
                height: 1,
                indent: 56,
                color: AppColors.outlineVariant.withValues(alpha: 0.2),
              ),
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('字体大小'),
                subtitle: Text('${state.fontSize.toInt()} px'),
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: state.fontSize,
                    min: 14,
                    max: 24,
                    divisions: 10,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(
                            UpdateFontSize(value),
                          );
                    },
                  ),
                ),
              ),
              Divider(
                height: 1,
                indent: 56,
                color: AppColors.outlineVariant.withValues(alpha: 0.2),
              ),
              ListTile(
                leading: const Icon(Icons.speed),
                title: const Text('阅读速度'),
                subtitle: Text('${state.wordsPerMinute.toInt()} 字/分钟'),
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: state.wordsPerMinute,
                    min: 200,
                    max: 600,
                    divisions: 8,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(
                            UpdateReadingSpeed(value),
                          );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          _showSignOutDialog(context);
        },
        icon: const Icon(Icons.logout),
        label: const Text('退出登录'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
    }
  }

  Future<void> _importOpml() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['opml', 'xml'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final opmlService = OpmlService();
        final importResult = opmlService.parseOpml(content);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Found ${importResult.feeds.length} feeds and ${importResult.categories.length} categories',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing OPML: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _exportOpml() async {
    try {
      final feedState = context.read<FeedBloc>().state;
      if (feedState is FeedsLoaded) {
        final opmlService = OpmlService();
        final opml = opmlService.exportToOpml(
          feedState.feeds,
          feedState.categories,
        );

        await Share.share(
          opml,
          subject: 'Real Reader Feeds Export',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting OPML: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showOPMLImportDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导入 OPML'),
        content: const Text('选择 OPML 文件导入订阅源'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _importOpml();
            },
            child: const Text('选择文件'),
          ),
        ],
      ),
    );
  }

  void _showOPMLExportDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导出 OPML'),
        content: const Text('将您的订阅源导出为 OPML 文件'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _exportOpml();
            },
            child: const Text('导出'),
          ),
        ],
      ),
    );
  }

  void _showThemeModeDialog(BuildContext context, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('选择主题模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('跟随系统'),
              value: ThemeMode.system,
              groupValue: currentMode,
              onChanged: (value) {
                context.read<SettingsBloc>().add(
                      UpdateThemeMode(value!),
                    );
                Navigator.pop(dialogContext);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('浅色模式'),
              value: ThemeMode.light,
              groupValue: currentMode,
              onChanged: (value) {
                context.read<SettingsBloc>().add(
                      UpdateThemeMode(value!),
                    );
                Navigator.pop(dialogContext);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('深色模式'),
              value: ThemeMode.dark,
              groupValue: currentMode,
              onChanged: (value) {
                context.read<SettingsBloc>().add(
                      UpdateThemeMode(value!),
                    );
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账户吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement sign out
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('退出登录功能开发中')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}
