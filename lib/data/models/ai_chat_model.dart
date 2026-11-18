import 'package:equatable/equatable.dart';

/// Represents a single message in the chat history.
class AiChatMessage extends Equatable {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> suggestions; // only populated for assistant messages

  const AiChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestions = const [],
  });

  @override
  List<Object?> get props => [text, isUser, timestamp, suggestions];
}

/// Parsed response from POST /ai/chat.
/// Maps `data.reply`, `data.suggestions`, `data.provider`, `data.timestamp`.
class AiChatResponse extends Equatable {
  final String reply;
  final List<String> suggestions;
  final String provider;
  final String timestamp;

  const AiChatResponse({
    required this.reply,
    required this.suggestions,
    required this.provider,
    required this.timestamp,
  });

  /// Parses from the `data` map (ApiClient unwraps top-level `data`).
  factory AiChatResponse.fromData(Map<String, dynamic> data) {
    final List<String> suggestionList = [];
    final rawSuggestions = data['suggestions'];
    if (rawSuggestions is List) {
      for (final s in rawSuggestions) {
        if (s is String && s.isNotEmpty) suggestionList.add(s);
      }
    }

    return AiChatResponse(
      reply: data['reply']?.toString() ?? '',
      suggestions: suggestionList,
      provider: data['provider']?.toString() ?? 'Smart City AI',
      timestamp: data['timestamp']?.toString() ?? '',
    );
  }

  /// Convert to an [AiChatMessage] for the chat history.
  AiChatMessage toMessage() => AiChatMessage(
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
        suggestions: suggestions,
      );

  @override
  List<Object?> get props => [reply, suggestions, provider, timestamp];
}
