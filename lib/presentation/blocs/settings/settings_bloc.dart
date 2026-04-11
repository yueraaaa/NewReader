import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/local/settings_local_datasource.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsLocalDatasource _settingsDatasource;

  SettingsBloc({SettingsLocalDatasource? settingsDatasource})
      : _settingsDatasource = settingsDatasource ?? SettingsLocalDatasource(),
        super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<UpdateFontSize>(_onUpdateFontSize);
    on<UpdateReadingSpeed>(_onUpdateReadingSpeed);
    on<UpdateSupabaseUrl>(_onUpdateSupabaseUrl);
    on<UpdateSupabaseAnonKey>(_onUpdateSupabaseAnonKey);
    on<UpdateMinimaxApiKey>(_onUpdateMinimaxApiKey);
    on<UpdateMinimaxGroupId>(_onUpdateMinimaxGroupId);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final themeModeStr = await _settingsDatasource.getSetting('theme_mode');
      final fontSizeStr = await _settingsDatasource.getSetting('font_size');
      final wordsPerMinuteStr =
          await _settingsDatasource.getSetting('words_per_minute');
      final supabaseUrl = await _settingsDatasource.getSetting('supabase_url');
      final supabaseAnonKey = await _settingsDatasource.getSetting('supabase_anon_key');
      final minimaxApiKey = await _settingsDatasource.getSetting('minimax_api_key');
      final minimaxGroupId = await _settingsDatasource.getSetting('minimax_group_id');

      ThemeMode themeMode = ThemeMode.system;
      if (themeModeStr != null) {
        switch (themeModeStr) {
          case 'light':
            themeMode = ThemeMode.light;
            break;
          case 'dark':
            themeMode = ThemeMode.dark;
            break;
          default:
            themeMode = ThemeMode.system;
        }
      }

      final fontSize = fontSizeStr != null ? double.tryParse(fontSizeStr) : null;
      final wordsPerMinute =
          wordsPerMinuteStr != null ? double.tryParse(wordsPerMinuteStr) : null;

      emit(SettingsState(
        themeMode: themeMode,
        fontSize: fontSize ?? 18.0,
        wordsPerMinute: wordsPerMinute ?? 200.0,
        supabaseUrl: supabaseUrl ?? '',
        supabaseAnonKey: supabaseAnonKey ?? '',
        minimaxApiKey: minimaxApiKey ?? '',
        minimaxGroupId: minimaxGroupId ?? '',
        isConfigValid: (supabaseUrl?.isNotEmpty ?? false) &&
                       (supabaseAnonKey?.isNotEmpty ?? false),
      ));
    } catch (e) {
      // Keep default state on error
    }
  }

  Future<void> _onUpdateThemeMode(
    UpdateThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      String themeModeStr;
      switch (event.themeMode) {
        case ThemeMode.light:
          themeModeStr = 'light';
          break;
        case ThemeMode.dark:
          themeModeStr = 'dark';
          break;
        default:
          themeModeStr = 'system';
      }
      await _settingsDatasource.setSetting('theme_mode', themeModeStr);
      emit(state.copyWith(themeMode: event.themeMode));
    } catch (e) {
      // Ignore error, state unchanged
    }
  }

  Future<void> _onUpdateFontSize(
    UpdateFontSize event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _settingsDatasource.setSetting('font_size', event.fontSize.toString());
      emit(state.copyWith(fontSize: event.fontSize));
    } catch (e) {
      // Ignore error, state unchanged
    }
  }

  Future<void> _onUpdateReadingSpeed(
    UpdateReadingSpeed event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _settingsDatasource.setSetting(
          'words_per_minute', event.wordsPerMinute.toString());
      emit(state.copyWith(wordsPerMinute: event.wordsPerMinute));
    } catch (e) {
      // Ignore error, state unchanged
    }
  }

  Future<void> _onUpdateSupabaseUrl(
    UpdateSupabaseUrl event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _settingsDatasource.setSetting('supabase_url', event.supabaseUrl);
      emit(state.copyWith(
        supabaseUrl: event.supabaseUrl,
        isConfigValid: event.supabaseUrl.isNotEmpty && state.supabaseAnonKey.isNotEmpty,
      ));
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _onUpdateSupabaseAnonKey(
    UpdateSupabaseAnonKey event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _settingsDatasource.setSetting('supabase_anon_key', event.supabaseAnonKey);
      emit(state.copyWith(
        supabaseAnonKey: event.supabaseAnonKey,
        isConfigValid: state.supabaseUrl.isNotEmpty && event.supabaseAnonKey.isNotEmpty,
      ));
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _onUpdateMinimaxApiKey(
    UpdateMinimaxApiKey event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _settingsDatasource.setSetting('minimax_api_key', event.minimaxApiKey);
      emit(state.copyWith(
        minimaxApiKey: event.minimaxApiKey,
        isConfigValid: event.minimaxApiKey.isNotEmpty && state.minimaxGroupId.isNotEmpty,
      ));
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _onUpdateMinimaxGroupId(
    UpdateMinimaxGroupId event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _settingsDatasource.setSetting('minimax_group_id', event.minimaxGroupId);
      emit(state.copyWith(
        minimaxGroupId: event.minimaxGroupId,
        isConfigValid: state.minimaxApiKey.isNotEmpty && event.minimaxGroupId.isNotEmpty,
      ));
    } catch (e) {
      // Ignore error
    }
  }
}
