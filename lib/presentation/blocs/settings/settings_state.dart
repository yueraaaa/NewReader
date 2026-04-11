import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final double fontSize; // 14-24
  final double wordsPerMinute; // 200-600
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String minimaxApiKey;
  final String minimaxGroupId;
  final bool isConfigValid;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.fontSize = 18.0,
    this.wordsPerMinute = 200.0,
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
    this.minimaxApiKey = '',
    this.minimaxGroupId = '',
    this.isConfigValid = false,
  });

  bool get hasSupabaseConfig => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  bool get hasMinimaxConfig => minimaxApiKey.isNotEmpty && minimaxGroupId.isNotEmpty;

  SettingsState copyWith({
    ThemeMode? themeMode,
    double? fontSize,
    double? wordsPerMinute,
    String? supabaseUrl,
    String? supabaseAnonKey,
    String? minimaxApiKey,
    String? minimaxGroupId,
    bool? isConfigValid,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      wordsPerMinute: wordsPerMinute ?? this.wordsPerMinute,
      supabaseUrl: supabaseUrl ?? this.supabaseUrl,
      supabaseAnonKey: supabaseAnonKey ?? this.supabaseAnonKey,
      minimaxApiKey: minimaxApiKey ?? this.minimaxApiKey,
      minimaxGroupId: minimaxGroupId ?? this.minimaxGroupId,
      isConfigValid: isConfigValid ?? this.isConfigValid,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        fontSize,
        wordsPerMinute,
        supabaseUrl,
        supabaseAnonKey,
        minimaxApiKey,
        minimaxGroupId,
        isConfigValid,
      ];
}
