import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class SettingsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class UpdateThemeMode extends SettingsEvent {
  final ThemeMode themeMode;
  UpdateThemeMode(this.themeMode);
  @override
  List<Object?> get props => [themeMode];
}

class UpdateFontSize extends SettingsEvent {
  final double fontSize;
  UpdateFontSize(this.fontSize);
  @override
  List<Object?> get props => [fontSize];
}

class UpdateReadingSpeed extends SettingsEvent {
  final double wordsPerMinute;
  UpdateReadingSpeed(this.wordsPerMinute);
  @override
  List<Object?> get props => [wordsPerMinute];
}

class UpdateSupabaseUrl extends SettingsEvent {
  final String supabaseUrl;
  UpdateSupabaseUrl(this.supabaseUrl);
  @override
  List<Object?> get props => [supabaseUrl];
}

class UpdateSupabaseAnonKey extends SettingsEvent {
  final String supabaseAnonKey;
  UpdateSupabaseAnonKey(this.supabaseAnonKey);
  @override
  List<Object?> get props => [supabaseAnonKey];
}

class UpdateMinimaxApiKey extends SettingsEvent {
  final String minimaxApiKey;
  UpdateMinimaxApiKey(this.minimaxApiKey);
  @override
  List<Object?> get props => [minimaxApiKey];
}

class UpdateMinimaxGroupId extends SettingsEvent {
  final String minimaxGroupId;
  UpdateMinimaxGroupId(this.minimaxGroupId);
  @override
  List<Object?> get props => [minimaxGroupId];
}

class UpdateLlmApiKey extends SettingsEvent {
  final String llmApiKey;
  UpdateLlmApiKey(this.llmApiKey);
  @override
  List<Object?> get props => [llmApiKey];
}

class UpdateLlmBaseUrl extends SettingsEvent {
  final String llmBaseUrl;
  UpdateLlmBaseUrl(this.llmBaseUrl);
  @override
  List<Object?> get props => [llmBaseUrl];
}

class UpdateLlmModelId extends SettingsEvent {
  final String llmModelId;
  UpdateLlmModelId(this.llmModelId);
  @override
  List<Object?> get props => [llmModelId];
}

class TestLlmConnection extends SettingsEvent {}
