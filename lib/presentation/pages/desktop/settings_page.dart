import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../blocs/settings/settings_event.dart';
import '../../blocs/settings/settings_state.dart';
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
                      onPressed: () {
                        // TODO: Implement OPML import
                      },
                      icon: const Icon(Icons.upload, size: 18),
                      label: const Text('导入'),
                    ),
                  ),
                  const Divider(height: AppSpacing.xl),
                  _SettingRow(
                    title: '导出 OPML',
                    subtitle: '备份您的订阅列表',
                    trailing: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement OPML export
                      },
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
  final bool isPassword;

  const _ApiKeyInput({
    required this.label,
    required this.value,
    required this.onChanged,
    this.isPassword = false,
  });

  @override
  State<_ApiKeyInput> createState() => _ApiKeyInputState();
}

class _ApiKeyInputState extends State<_ApiKeyInput> {
  late TextEditingController _controller;
  bool _obscureText = true;

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
        obscureText: widget.isPassword && _obscureText,
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
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: hintColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}
