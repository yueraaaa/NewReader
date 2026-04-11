import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final double fontSize; // 14-24
  final double wordsPerMinute; // 200-600

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.fontSize = 18.0,
    this.wordsPerMinute = 200.0,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    double? fontSize,
    double? wordsPerMinute,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      wordsPerMinute: wordsPerMinute ?? this.wordsPerMinute,
    );
  }

  @override
  List<Object?> get props => [themeMode, fontSize, wordsPerMinute];
}
