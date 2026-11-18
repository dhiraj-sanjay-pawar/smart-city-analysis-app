import 'package:equatable/equatable.dart';
import '../../../data/models/ai_overview_model.dart';
import '../../../data/models/ai_predict_model.dart';
import '../../../data/models/ai_chat_model.dart';

abstract class AiState extends Equatable {
  const AiState();
  @override
  List<Object?> get props => [];
}

// ── Overview States ───────────────────────────────────────────────
class AiInitial extends AiState {
  const AiInitial();
}

class AiOverviewLoading extends AiState {
  const AiOverviewLoading();
}

class AiOverviewLoaded extends AiState {
  final AiOverviewModel overview;
  const AiOverviewLoaded(this.overview);
  @override
  List<Object?> get props => [overview];
}

class AiOverviewError extends AiState {
  final String message;
  const AiOverviewError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Prediction States ─────────────────────────────────────────────
class AiPredictIdle extends AiState {
  const AiPredictIdle();
}

class AiPredictLoading extends AiState {
  const AiPredictLoading();
}

class AiPredictLoaded extends AiState {
  final AiPredictionResult result;
  const AiPredictLoaded(this.result);
  @override
  List<Object?> get props => [result];
}

class AiPredictError extends AiState {
  final String message;
  const AiPredictError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Chat States ───────────────────────────────────────────────────
class AiChatState extends AiState {
  final List<AiChatMessage> messages;
  final bool isTyping;
  final String? errorMessage;

  const AiChatState({
    this.messages = const [],
    this.isTyping = false,
    this.errorMessage,
  });

  AiChatState copyWith({
    List<AiChatMessage>? messages,
    bool? isTyping,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [messages, isTyping, errorMessage];
}
