import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'ai_event.dart';
import 'ai_state.dart';

class AiBloc extends Bloc<AiEvent, AiState> {
  final FlutterTts _flutterTts;
  // MinimaxService will be wired in Task 2b - stub for now
  // final MinimaxService _minimaxService;

  AiBloc({FlutterTts? flutterTts}) : _flutterTts = flutterTts ?? FlutterTts(), super(const AiState()) {
    _initTts();
    on<TranslateArticle>(_onTranslateArticle);
    on<SummarizeArticle>(_onSummarizeArticle);
    on<ReadArticleAloud>(_onReadArticleAloud);
    on<StopReadAloud>(_onStopReadAloud);
    on<ClearAiResults>(_onClearAiResults);
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _onTranslateArticle(
    TranslateArticle event,
    Emitter<AiState> emit,
  ) async {
    emit(state.copyWith(isTranslating: true, error: null));
    try {
      // TODO: Wire in MinimaxService from Task 2b
      // final result = await _minimaxService.translate(event.article);
      // emit(state.copyWith(isTranslating: false, translation: result));
      emit(state.copyWith(isTranslating: false, translation: 'Translation not yet implemented'));
    } catch (e) {
      emit(state.copyWith(isTranslating: false, error: e.toString()));
    }
  }

  Future<void> _onSummarizeArticle(
    SummarizeArticle event,
    Emitter<AiState> emit,
  ) async {
    emit(state.copyWith(isSummarizing: true, error: null));
    try {
      // TODO: Wire in MinimaxService from Task 2b
      // final result = await _minimaxService.summarize(event.article);
      // emit(state.copyWith(isSummarizing: false, summary: result));
      emit(state.copyWith(isSummarizing: false, summary: 'Summary not yet implemented'));
    } catch (e) {
      emit(state.copyWith(isSummarizing: false, error: e.toString()));
    }
  }

  Future<void> _onReadArticleAloud(
    ReadArticleAloud event,
    Emitter<AiState> emit,
  ) async {
    emit(state.copyWith(isReadingAloud: true, error: null));
    try {
      final text = '${event.article.title}. ${event.article.description ?? ''} ${event.article.content ?? ''}';
      await _flutterTts.speak(text);
      emit(state.copyWith(isReadingAloud: false));
    } catch (e) {
      emit(state.copyWith(isReadingAloud: false, error: e.toString()));
    }
  }

  Future<void> _onStopReadAloud(
    StopReadAloud event,
    Emitter<AiState> emit,
  ) async {
    await _flutterTts.stop();
    emit(state.copyWith(isReadingAloud: false));
  }

  Future<void> _onClearAiResults(
    ClearAiResults event,
    Emitter<AiState> emit,
  ) async {
    emit(const AiState());
  }

  @override
  Future<void> close() {
    _flutterTts.stop();
    return super.close();
  }
}
