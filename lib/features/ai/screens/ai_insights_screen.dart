import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../data/models/ai_overview_model.dart';
import '../bloc/ai_cubit.dart';
import '../bloc/ai_state.dart';

class AiInsightsScreen extends StatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AiCubit>().loadOverview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'AI City Insights',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () => context.read<AiCubit>().loadOverview(),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        ),
      ),
      body: BlocBuilder<AiCubit, AiState>(
        builder: (context, state) {
          if (state is AiOverviewLoading) return _buildLoading();
          if (state is AiOverviewError) return _buildError(context, state.message);
          if (state is AiOverviewLoaded) return _buildContent(context, state.overview);
          // Initial state — trigger load
          return _buildLoading();
        },
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      children: [
        const SizedBox(height: 16),
        const AnimatedPlaceholder(height: 80, radius: 16),
        const SizedBox(height: 16),
        ...List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: AnimatedPlaceholder(height: 90, radius: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textMedium, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              onPressed: () => context.read<AiCubit>().loadOverview(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AiOverviewModel overview) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPadding,
        vertical: 20,
      ),
      children: [
        // Hero status card
        _buildStatusCard(overview),
        const SizedBox(height: 20),

        // Section header
        Text(
          'Multi-Domain Risk Analysis',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 4),
        Text(
          'Real-time city intelligence across all monitored domains.',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMedium),
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
        const SizedBox(height: 16),

        // Domain risk cards
        if (overview.radarDomains.isEmpty)
          _buildEmptyDomains()
        else
          ...overview.radarDomains
              .asMap()
              .entries
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _DomainRiskCard(domain: e.value, index: e.key),
                  )),

        const SizedBox(height: 20),

        // Safety prediction CTA
        _buildPredictCta(context),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStatusCard(AiOverviewModel overview) {
    final statusColor = _statusColor(overview.safetyStatus);
    final statusIcon = _statusIcon(overview.safetyStatus);
    final atRiskCount = overview.radarDomains.where((d) => d.isAtRisk).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'City Safety Status',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      overview.safetyStatus,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      overview.safetyStatus,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            overview.safetyAdvisory,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
          if (overview.radarDomains.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _StatChip(
                  label: '${overview.radarDomains.length} Domains',
                  icon: Icons.radar_rounded,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  label: '$atRiskCount At-Risk',
                  icon: Icons.warning_amber_rounded,
                  isAlert: atRiskCount > 0,
                ),
              ],
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08, end: 0, duration: 400.ms);
  }

  Widget _buildEmptyDomains() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.bar_chart_rounded, size: 48, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text(
            'No domain data available at this time.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.textMedium, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictCta(BuildContext context) {
    return AnimatedTap(
      onTap: () => context.push('/ai/predict'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shield_moon_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Safety Prediction',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Check area safety before you travel',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'critical':
        return AppColors.error;
      case 'elevated':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'critical':
        return Icons.warning_rounded;
      case 'elevated':
        return Icons.info_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }
}

// ── Domain Risk Card ─────────────────────────────────────────────

class _DomainRiskCard extends StatefulWidget {
  final RadarDomainModel domain;
  final int index;

  const _DomainRiskCard({required this.domain, required this.index});

  @override
  State<_DomainRiskCard> createState() => _DomainRiskCardState();
}

class _DomainRiskCardState extends State<_DomainRiskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _barController;
  late Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _barAnim = CurvedAnimation(parent: _barController, curve: Curves.easeOutCubic);
    Future.delayed(Duration(milliseconds: 200 + widget.index * 100), () {
      if (mounted) _barController.forward();
    });
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.domain;
    final riskColor = d.isAtRisk ? AppColors.error : AppColors.success;
    final riskBg = d.isAtRisk ? AppColors.errorLight : AppColors.successLight;
    final domainIcon = _domainIcon(d.domain);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: d.isAtRisk
              ? AppColors.error.withValues(alpha: 0.2)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: riskBg.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(domainIcon, color: riskColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.domain,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      d.isAtRisk ? 'Above threshold — elevated risk' : 'Within safe threshold',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: riskColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: riskBg,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${d.current.toStringAsFixed(0)} / ${d.fullMark.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Current bar
          _BarRow(
            label: 'Current',
            ratio: d.currentRatio,
            animation: _barAnim,
            color: riskColor,
          ),
          const SizedBox(height: 8),

          // Threshold bar
          _BarRow(
            label: 'Threshold',
            ratio: d.thresholdRatio,
            animation: _barAnim,
            color: AppColors.textLight,
            isDashed: true,
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 80))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.12, end: 0, duration: 350.ms);
  }

  IconData _domainIcon(String domain) {
    final d = domain.toLowerCase();
    if (d.contains('traffic') || d.contains('transit')) return Icons.traffic_rounded;
    if (d.contains('safety') || d.contains('crime')) return Icons.shield_rounded;
    if (d.contains('health')) return Icons.local_hospital_rounded;
    if (d.contains('water') || d.contains('waste')) return Icons.water_drop_rounded;
    if (d.contains('environment')) return Icons.eco_rounded;
    if (d.contains('energy')) return Icons.bolt_rounded;
    return Icons.analytics_rounded;
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double ratio;
  final Animation<double> animation;
  final Color color;
  final bool isDashed;

  const _BarRow({
    required this.label,
    required this.ratio,
    required this.animation,
    required this.color,
    this.isDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
            ),
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: (ratio * animation.value).clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDashed ? color.withValues(alpha: 0.4) : color,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '${(ratio * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isAlert;

  const _StatChip({
    required this.label,
    required this.icon,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isAlert ? const Color(0xFFFBBF24) : Colors.white70,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
