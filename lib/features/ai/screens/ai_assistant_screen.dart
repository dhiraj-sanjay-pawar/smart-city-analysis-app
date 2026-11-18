import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/ai_chat_model.dart';
import '../bloc/ai_cubit.dart';
import '../bloc/ai_state.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<AiCubit>().initChat();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _inputController.clear();
    context.read<AiCubit>().sendMessage(text.trim());
    _scrollToBottom();
  }

  void _scrollToBottom({bool delayed = true}) {
    void scroll() {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    }
    if (delayed) {
      Future.delayed(const Duration(milliseconds: 120), scroll);
    } else {
      scroll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<AiCubit, AiState>(
              listener: (context, state) {
                if (state is AiChatState) {
                  _scrollToBottom();
                }
              },
              builder: (context, state) {
                if (state is AiChatState) {
                  return _buildChatBody(state);
                }
                return const _WelcomeScreen();
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart City Assistant',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              BlocBuilder<AiCubit, AiState>(
                builder: (context, state) {
                  final isTyping = state is AiChatState && state.isTyping;
                  return Text(
                    isTyping ? 'Thinking...' : 'AI Powered • City Intelligence',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: Colors.white60,
                      fontWeight: FontWeight.w400,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      ),
    );
  }

  Widget _buildChatBody(AiChatState state) {
    final messages = state.messages;

    return Column(
      children: [
        if (state.errorMessage != null)
          _ErrorBanner(
            message: state.errorMessage!,
            onDismiss: () => context.read<AiCubit>().clearChatError(),
          ),
        Expanded(
          child: messages.isEmpty
              ? const _WelcomeScreen()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding,
                    vertical: 16,
                  ),
                  itemCount: messages.length + (state.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length && state.isTyping) {
                      return const _TypingIndicator();
                    }
                    final msg = messages[index];
                    return _MessageBubble(
                      message: msg,
                      index: index,
                      onSuggestionTap: _sendMessage,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInputBar() {
    return BlocBuilder<AiCubit, AiState>(
      builder: (context, state) {
        final isTyping = state is AiChatState && state.isTyping;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _inputController,
                        focusNode: _focusNode,
                        maxLines: 3,
                        minLines: 1,
                        enabled: !isTyping,
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textDark),
                        decoration: InputDecoration(
                          hintText: 'Ask about traffic, safety, hospitals…',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: AppColors.textLight,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: isTyping ? null : _sendMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isTyping
                          ? AppColors.textLight
                          : AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: isTyping
                          ? null
                          : () => _sendMessage(_inputController.text),
                      icon: Icon(
                        isTyping ? Icons.hourglass_top_rounded : Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Welcome Screen (empty state) ─────────────────────────────────

class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen();

  static const List<String> _starters = [
    'What is the traffic situation near Jehan Circle?',
    'Is it safe to visit Gangapur Road tonight?',
    'Which hospitals have ICU beds available?',
    'What are the flood risk areas in Nashik?',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPadding,
        vertical: 24,
      ),
      children: [
        Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 36),
            )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(
              'Smart City Assistant',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
            const SizedBox(height: 6),
            Text(
              'Ask me anything about traffic, safety,\nhealthcare, or city events.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Try asking…',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight,
                  letterSpacing: 0.5,
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 10),
            ..._starters.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _StarterChip(
                    text: e.value,
                    index: e.key,
                    onTap: () => context.read<AiCubit>().sendMessage(e.value),
                  ),
                )),
          ],
        ),
      ],
    );
  }
}

// ── Message Bubble ───────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final AiChatMessage message;
  final int index;
  final ValueChanged<String> onSuggestionTap;

  const _MessageBubble({
    required this.message,
    required this.index,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final timeStr = DateFormat('HH:mm').format(message.timestamp);

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(right: 8, bottom: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 16),
              ),
            ],
            Flexible(
              child: Container(
                margin: EdgeInsets.only(
                  left: isUser ? 60 : 0,
                  right: isUser ? 0 : 60,
                  bottom: 4,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: isUser
                      ? null
                      : Border.all(color: AppColors.border),
                ),
                child: Text(
                  message.text,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isUser ? Colors.white : AppColors.textDark,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(
            left: isUser ? 0 : 46,
            right: isUser ? 4 : 0,
            bottom: 2,
          ),
          child: Text(
            timeStr,
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight),
          ),
        ),

        // Suggestion chips (assistant only)
        if (!isUser && message.suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 46, top: 6, bottom: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: message.suggestions
                  .map((s) => _SuggestionChip(
                        text: s,
                        onTap: () => onSuggestionTap(s),
                      ))
                  .toList(),
            ),
          ),

        const SizedBox(height: 10),
      ],
    )
        .animate(delay: Duration(milliseconds: index.clamp(0, 8) * 50))
        .fadeIn(duration: 300.ms)
        .slideY(
          begin: isUser ? 0.05 : -0.05,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ── Typing Indicator ─────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Container(
                  width: 7,
                  height: 7,
                  margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scaleXY(
                      begin: 0.5,
                      end: 1.2,
                      delay: Duration(milliseconds: i * 200),
                      duration: 600.ms,
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .scaleXY(
                      begin: 1.2,
                      end: 0.5,
                      duration: 600.ms,
                      curve: Curves.easeInOut,
                    ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

// ── Suggestion Chip ──────────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ── Starter Chip ─────────────────────────────────────────────────

class _StarterChip extends StatelessWidget {
  final String text;
  final int index;
  final VoidCallback onTap;

  const _StarterChip({
    required this.text,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  color: AppColors.secondary, size: 14),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textLight, size: 13),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 350 + index * 80))
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.1, end: 0, duration: 350.ms, curve: Curves.easeOutCubic);
  }
}

// ── Error Banner ─────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.screenPadding,
        10,
        AppDimensions.screenPadding,
        0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.error,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close_rounded,
                color: AppColors.error, size: 18),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).shake();
  }
}
