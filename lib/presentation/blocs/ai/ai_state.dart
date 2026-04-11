import 'package:equatable/equatable.dart';

class AiState extends Equatable {
  final bool isTranslating;
  final bool isSummarizing;
  final bool isReadingAloud;
  final String? translation;
  final String? summary;
  final String? error;

  const AiState({
    this.isTranslating = false,
    this.isSummarizing = false,
    this.isReadingAloud = false,
    this.translation,
    this.summary,
    this.error,
  });

  AiState copyWith({
    bool? isTranslating,
    bool? isSummarizing,
    bool? isReadingAloud,
    String? translation,
    String? summary,
    String? error,
  }) {
    return AiState(
      isTranslating: isTranslating ?? this.isTranslating,
      isSummarizing: isSummarizing ?? this.isSummarizing,
      isReadingAloud: isReadingAloud ?? this.isReadingAloud,
      translation: translation ?? this.translation,
      summary: summary ?? this.summary,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [isTranslating, isSummarizing, isReadingAloud, translation, summary, error];
}
