import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../data/models/ai_overview_model.dart';

/// Compact dashboard card showing multi-domain AI risk scores.
/// Tapping opens the full AI Insights screen.
class AiInsightsCard extends StatelessWidget {
  final AiOverviewModel overview;

  const AiInsightsCard({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      child: AnimatedTap(
        onTap: () => context.push('/ai/insights'),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.psychology_rounded,
                          color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI City Insights',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            'Multi-domain risk intelligence',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: overview.safetyStatus),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: AppColors.textLight),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.border),

              // Domain mini-bars
              if (overview.radarDomains.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No domain data available',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textLight),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: overview.radarDomains
                        .take(4)
                        .map((domain) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _MiniDomainBar(domain: domain),
                            ))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }
}

class _MiniDomainBar extends StatefulWidget {
  final RadarDomainModel domain;
  const _MiniDomainBar({required this.domain});

  @override
  State<_MiniDomainBar> createState() => _MiniDomainBarState();
}

class _MiniDomainBarState extends State<_MiniDomainBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.domain;
    final riskColor = d.isAtRisk ? AppColors.error : AppColors.success;

    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            d.domain,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) => Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (d.currentRatio * _anim.value).clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: riskColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            '${d.current.toStringAsFixed(0)}',
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: riskColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    switch (status.toLowerCase()) {
      case 'critical':
        color = AppColors.error;
        bg = AppColors.errorLight;
        break;
      case 'elevated':
        color = AppColors.warning;
        bg = AppColors.warningLight;
        break;
      default:
        color = AppColors.success;
        bg = AppColors.successLight;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
