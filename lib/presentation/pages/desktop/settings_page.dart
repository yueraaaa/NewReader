import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/services/opml_service.dart';
import '../../../data/datasources/local/feed_local_datasource.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../blocs/settings/settings_event.dart';
import '../../blocs/settings/settings_state.dart';
import '../../blocs/feed/feed_bloc.dart';
import '../../blocs/feed/feed_event.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final secondaryColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;

    return Scaffold(
      backgroundColor: surfaceColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              '设置',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: textColor,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Appearance section
            _SectionHeader(title: '外观', color: secondaryColor),
            const SizedBox(height: AppSpacing.md),
            BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceContainerLowest
                        : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Theme mode
                      _SettingRow(
                        title: '主题',
                        subtitle: _getThemeModeText(state.themeMode),
                        trailing: DropdownButton<ThemeMode>(
                          value: state.themeMode,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('跟随系统'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('浅色'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('深色'),
                            ),
                          ],
                          onChanged: (mode) {
                            if (mode != null) {
                              context.read<SettingsBloc>().add(UpdateThemeMode(mode));
                            }
                          },
                        ),
                      ),
                      const Divider(height: AppSpacing.xl),

                      // Font size
                      _SettingRow(
                        title: '正文字号',
                        subtitle: '${state.fontSize.toInt()} px',
                        trailing: SizedBox(
                          width: 200,
                          child: Slider(
                            value: state.fontSize,
                            min: 14,
                            max: 24,
                            divisions: 10,
                            onChanged: (value) {
                              context.read<SettingsBloc>().add(UpdateFontSize(value));
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // Reading section
            _SectionHeader(title: '阅读', color: secondaryColor),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerLowest
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: BlocBuilder<SettingsBloc, SettingsState>(
                builder: (context, state) {
                  return _SettingRow(
                    title: '阅读速度',
                    subtitle: '${state.wordsPerMinute.toInt()} 字/分钟',
                    trailing: SizedBox(
                      width: 200,
                      child: Slider(
                        value: state.wordsPerMinute,
                        min: 200,
                        max: 600,
                        divisions: 8,
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(UpdateReadingSpeed(value));
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Large Model Settings section
            _SectionHeader(title: '大模型设置', color: secondaryColor),
            const SizedBox(height: AppSpacing.md),
            BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceContainerLowest
                        : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ApiKeyInput(
                        label: 'API Key',
                        value: state.llmApiKey,
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(UpdateLlmApiKey(value));
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ApiKeyInput(
                        label: 'Base URL',
                        value: state.llmBaseUrl,
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(UpdateLlmBaseUrl(value));
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ApiKeyInput(
                        label: 'Model ID',
                        value: state.llmModelId,
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(UpdateLlmModelId(value));
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: state.llmConnectionStatus == LlmConnectionStatus.testing
                              ? null
                              : () {
                                  context.read<SettingsBloc>().add(TestLlmConnection());
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: state.llmConnectionStatus == LlmConnectionStatus.testing
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('测试中...'),
                                  ],
                                )
                              : const Text('保存并测试连接'),
                        ),
                      ),
                      // Connection status message
                      if (state.llmConnectionStatus != LlmConnectionStatus.idle) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: state.llmConnectionStatus == LlmConnectionStatus.success
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                state.llmConnectionStatus == LlmConnectionStatus.success
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: state.llmConnectionStatus == LlmConnectionStatus.success
                                    ? Colors.green
                                    : Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.llmConnectionMessage,
                                  style: TextStyle(
                                    color: state.llmConnectionStatus == LlmConnectionStatus.success
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // API Configuration section
            _SectionHeader(title: 'API 配置', color: secondaryColor),
            const SizedBox(height: AppSpacing.md),
            BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceContainerLowest
                        : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Supabase',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ApiKeyInput(
                        label: 'URL',
                        value: state.supabaseUrl,
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(UpdateSupabaseUrl(value));
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ApiKeyInput(
                        label: 'ANON KEY',
                        value: state.supabaseAnonKey,
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(UpdateSupabaseAnonKey(value));
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Minimax AI',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ApiKeyInput(
                        label: 'API Key',
                        value: state.minimaxApiKey,
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(UpdateMinimaxApiKey(value));
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ApiKeyInput(
                        label: 'Group ID',
                        value: state.minimaxGroupId,
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(UpdateMinimaxGroupId(value));
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // Data section
            _SectionHeader(title: '数据', color: secondaryColor),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerLowest
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Column(
                children: [
                  _SettingRow(
                    title: '导入 OPML',
                    subtitle: '从其他 RSS 阅读器导入订阅',
                    trailing: OutlinedButton.icon(
                      onPressed: () => _importOpml(context),
                      icon: const Icon(Icons.upload, size: 18),
                      label: const Text('导入'),
                    ),
                  ),
                  const Divider(height: AppSpacing.xl),
                  _SettingRow(
                    title: '导出 OPML',
                    subtitle: '备份您的订阅列表',
                    trailing: OutlinedButton.icon(
                      onPressed: () => _exportOpml(context),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('导出'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Account section
            _SectionHeader(title: '账户', color: secondaryColor),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerLowest
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthAuthenticated) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SettingRow(
                          title: '登录状态',
                          subtitle: state.user.email ?? state.user.name ?? '已登录',
                          trailing: Icon(
                            Icons.check_circle,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                          ),
                        ),
                        const Divider(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.read<AuthBloc>().add(AuthSignOut());
                            },
                            icon: const Icon(Icons.logout, size: 18),
                            label: const Text('退出登录'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark
                                  ? AppColors.darkError
                                  : AppColors.error,
                              side: BorderSide(
                                color: isDark
                                    ? AppColors.darkError
                                    : AppColors.error,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return _SettingRow(
                    title: '登录',
                    subtitle: '登录以同步您的订阅和阅读进度',
                    trailing: ElevatedButton(
                      onPressed: () {
                        // TODO: Navigate to login
                      },
                      child: const Text('登录'),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // About section
            _SectionHeader(title: '关于', color: secondaryColor),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerLowest
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SettingRow(
                    title: '版本',
                    subtitle: '1.0.0',
                  ),
                  const Divider(height: AppSpacing.xl),
                  _SettingRow(
                    title: 'Real Reader',
                    subtitle: 'The Editorial Sanctuary',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
    }
  }

  Future<void> _importOpml(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['opml', 'xml'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      final opmlService = OpmlService();
      final importResult = opmlService.parseOpml(content);

      if (importResult.feeds.isEmpty && importResult.categories.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OPML 文件为空或格式不正确')),
          );
        }
        return;
      }

      // Import categories first
      final feedLocalDatasource = FeedLocalDatasource();
      for (final category in importResult.categories) {
        await feedLocalDatasource.insertCategory(category);
      }

      // Import feeds
      for (final feed in importResult.feeds) {
        await feedLocalDatasource.insertFeed(feed);
      }

      // Refresh feed list
      if (context.mounted) {
        context.read<FeedBloc>().add(LoadFeeds());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '成功导入 ${importResult.feeds.length} 个订阅源和 ${importResult.categories.length} 个分类',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  Future<void> _exportOpml(BuildContext context) async {
    try {
      final feedLocalDatasource = FeedLocalDatasource();
      final feeds = await feedLocalDatasource.getAllFeeds();
      final categories = await feedLocalDatasource.getAllCategories();

      if (feeds.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('没有可导出的订阅源')),
          );
        }
        return;
      }

      final opmlService = OpmlService();
      final opmlContent = opmlService.exportToOpml(feeds, categories);

      // Save to temporary file and share
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = File('${directory.path}/real_reader_export_$timestamp.opml');
      await file.writeAsString(opmlContent);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Real Reader 订阅导出',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出 ${feeds.length} 个订阅源')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingRow({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final secondaryColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _ApiKeyInput extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _ApiKeyInput({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_ApiKeyInput> createState() => _ApiKeyInputState();
}

class _ApiKeyInputState extends State<_ApiKeyInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_ApiKeyInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text && widget.value != oldWidget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHigh;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final hintColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return SizedBox(
      height: 40,
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: TextStyle(fontSize: 13, color: textColor),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(fontSize: 12, color: hintColor),
          hintText: '请输入${widget.label}',
          hintStyle: TextStyle(fontSize: 12, color: hintColor.withValues(alpha: 0.6)),
          filled: true,
          fillColor: surfaceColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primary, width: 1),
          ),
        ),
      ),
    );
  }
}
