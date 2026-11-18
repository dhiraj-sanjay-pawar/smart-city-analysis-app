import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Reusable animation utilities for the SmartCity app.
/// Centralises animation curves, durations, and effect presets
/// so every screen stays consistent without duplicating code.

class AppAnimations {
  AppAnimations._();

  // ── Standard durations ────────────────────────────────────────
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 450);
  static const Duration splash = Duration(milliseconds: 600);

  // ── Curves ────────────────────────────────────────────────────
  static const Curve enter = Curves.easeOutCubic;
  static const Curve elastic = Curves.elasticOut;
  static const Curve easeOut = Curves.easeOut;

  // ── Stagger gap between list items ────────────────────────────
  static Duration stagger(int index, {int baseMs = 60}) =>
      Duration(milliseconds: index * baseMs);
}

// ─────────────────────────────────────────────────────────────────
// Fade + slide-up for cards, list items, sections
// ─────────────────────────────────────────────────────────────────
extension AnimationExtensions on Widget {
  /// Standard fade + slide-up card entrance.
  Widget cardEntrance({int index = 0, double slideY = 0.15}) {
    return animate(delay: AppAnimations.stagger(index))
        .fadeIn(duration: AppAnimations.normal, curve: AppAnimations.enter)
        .slideY(
          begin: slideY,
          end: 0,
          duration: AppAnimations.normal,
          curve: AppAnimations.enter,
        );
  }

  /// Horizontal slide for notifications, lists.
  Widget slideEntrance({int index = 0}) {
    return animate(delay: AppAnimations.stagger(index))
        .fadeIn(duration: AppAnimations.fast)
        .slideX(begin: 0.12, end: 0, duration: AppAnimations.normal, curve: AppAnimations.enter);
  }

  /// Scale pop for icons and badges.
  Widget scalePop({int delay = 0}) {
    return animate(delay: Duration(milliseconds: delay))
        .scale(duration: AppAnimations.splash, curve: AppAnimations.elastic);
  }
}

// ─────────────────────────────────────────────────────────────────
// Animated tap feedback wrapper
// ─────────────────────────────────────────────────────────────────
class AnimatedTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  const AnimatedTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
  });

  @override
  State<AnimatedTap> createState() => _AnimatedTapState();
}

class _AnimatedTapState extends State<AnimatedTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.forward();
  void _onTapUp(_) {
    _controller.reverse();
    widget.onTap?.call();
  }
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Pulsing widget (for SOS button, emergency indicators)
// ─────────────────────────────────────────────────────────────────
class PulseWidget extends StatelessWidget {
  final Widget child;
  final Duration duration;
  const PulseWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 1.06, duration: duration, curve: Curves.easeInOut);
  }
}

// ─────────────────────────────────────────────────────────────────
// Shimmer loading placeholder (reusable)
// ─────────────────────────────────────────────────────────────────
class AnimatedPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const AnimatedPlaceholder({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(radius),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: const Duration(milliseconds: 1200), color: Colors.white38);
  }
}

// ─────────────────────────────────────────────────────────────────
// Success animation widget
// ─────────────────────────────────────────────────────────────────
class SuccessAnimation extends StatelessWidget {
  final Color color;
  final double size;

  const SuccessAnimation({
    super.key,
    this.color = const Color(0xFF16A34A),
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
      ),
      child: Icon(Icons.check_circle_rounded, color: color, size: size * 0.6),
    )
        .animate()
        .scale(duration: const Duration(milliseconds: 600), curve: Curves.elasticOut)
        .fadeIn(duration: const Duration(milliseconds: 300));
  }
}

// ─────────────────────────────────────────────────────────────────
// Animated status badge
// ─────────────────────────────────────────────────────────────────
class AnimatedStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;
  final IconData icon;
  final bool small;

  const AnimatedStatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.icon,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: small ? 10 : 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: small ? 10 : 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 250));
  }
}

// ─────────────────────────────────────────────────────────────────
// Empty state widget
// ─────────────────────────────────────────────────────────────────
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: const Color(0xFF94A3B8))
                .animate()
                .scale(duration: const Duration(milliseconds: 500), curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF94A3B8),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ).animate().fadeIn(duration: const Duration(milliseconds: 400)),
      ),
    );
  }
}
