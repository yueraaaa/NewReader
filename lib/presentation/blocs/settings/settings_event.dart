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
