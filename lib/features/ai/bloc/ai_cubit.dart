import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../../data/models/ai_predict_model.dart';
import '../../../data/models/ai_chat_model.dart';
import 'ai_state.dart';

/// Cubit that manages all citizen-facing AI feature states.
///
/// Three logical "sub-cubits" share this one cubit because each screen
/// is entered independently; state isolation is achieved via typed states.
class AiCubit extends Cubit<AiState> {
  final AiRepository _aiRepository;

  AiCubit({AiRepository? aiRepository})
      : _aiRepository = aiRepository ?? AiRepository(),
        super(const AiInitial());

  // ── Overview ────────────────────────────────────────────────────

  Future<void> loadOverview() async {
    emit(const AiOverviewLoading());
    try {
      final overview = await _aiRepository.getCitizenOverview();
      if (overview == null) {
        emit(const AiOverviewError('Could not load AI city insights at this time.'));
      } else {
        emit(AiOverviewLoaded(overview));
      }
    } catch (e) {
      emit(AiOverviewError(_friendly(e)));
    }
  }

  // ── Prediction ──────────────────────────────────────────────────

  void resetPrediction() => emit(const AiPredictIdle());

  Future<void> predict(AiPredictRequest request) async {
    emit(const AiPredictLoading());
    try {
      final result = await _aiRepository.simulatePrediction(request);
      emit(AiPredictLoaded(result));
    } catch (e) {
      emit(AiPredictError(_friendly(e)));
    }
  }

  // ── Chat ────────────────────────────────────────────────────────

  void initChat() {
    emit(const AiChatState());
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final currentState = state is AiChatState
        ? state as AiChatState
        : const AiChatState();

    // Add user message immediately
    final userMsg = AiChatMessage(
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );
    emit(currentState.copyWith(
      messages: [...currentState.messages, userMsg],
      isTyping: true,
      clearError: true,
    ));

    try {
      final response = await _aiRepository.sendChatMessage(trimmed);
      final chatState = state as AiChatState;
      emit(chatState.copyWith(
        messages: [...chatState.messages, response.toMessage()],
        isTyping: false,
      ));
    } catch (e) {
      final chatState = state is AiChatState
          ? state as AiChatState
          : const AiChatState();
      emit(chatState.copyWith(
        isTyping: false,
        errorMessage: _friendly(e),
      ));
    }
  }

  void clearChatError() {
    if (state is AiChatState) {
      emit((state as AiChatState).copyWith(clearError: true));
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────

  String _friendly(Object e) {
    final msg = e.toString();
    if (msg.contains('ApiException')) {
      final start = msg.indexOf(']:') + 2;
      if (start > 1 && start < msg.length) return msg.substring(start).trim();
    }
    if (msg.contains('SocketException') || msg.contains('Network')) {
      return 'No internet connection. Please check your network and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
