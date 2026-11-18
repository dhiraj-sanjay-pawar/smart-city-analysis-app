import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../data/models/dashboard_summary_model.dart';

class DashboardKpiSection extends StatelessWidget {
  final DashboardSummaryModel summary;

  const DashboardKpiSection({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Live Smart City Telemetry',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    summary.cityName ?? 'Nashik',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 4 KPI Cards in 2x2 grid (or 4 columns on wide screens)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 500;
                final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // 1. Incidents / Complaints KPI
                    _buildKpiCard(
                      width: cardWidth,
                      title: 'Resolved Grievances',
                      value: '${summary.kpis.resolvedIncidents}',
                      subtitle: 'of ${summary.kpis.totalIncidents} Total',
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: AppColors.success,
                      bgColor: AppColors.successLight.withValues(alpha: 0.35),
                      onTap: () => context.go('/reports'),
                    ),

                    // 2. Traffic Congestion KPI
                    _buildKpiCard(
                      width: cardWidth,
                      title: 'Traffic Index',
                      value: '${summary.kpis.trafficCongestionIndex.toStringAsFixed(0)}%',
                      subtitle: summary.kpis.trafficCongestionIndex > 60 ? 'Heavy Congestion' : 'Moderate Flow',
                      icon: Icons.traffic_rounded,
                      iconColor: summary.kpis.trafficCongestionIndex > 60 ? AppColors.warning : AppColors.info,
                      bgColor: AppColors.infoLight.withValues(alpha: 0.4),
                      onTap: () => context.push('/traffic'),
                    ),

                    // 3. Healthcare Beds KPI
                    _buildKpiCard(
                      width: cardWidth,
                      title: 'Available Beds',
                      value: '${summary.kpis.availableBeds}',
                      subtitle: '${summary.kpis.totalHospitals} Facilities Active',
                      icon: Icons.local_hospital_outlined,
                      iconColor: AppColors.secondary,
                      bgColor: AppColors.accentLight.withValues(alpha: 0.35),
                      onTap: () => context.push('/healthcare'),
                    ),

                    // 4. Wastewater / Flood Telemetry KPI
                    _buildKpiCard(
                      width: cardWidth,
                      title: 'Water Level Status',
                      value: '${summary.kpis.wastewaterAlerts} Sensors',
                      subtitle: summary.kpis.wastewaterAlerts > 0 ? 'Waterlogging Watch' : 'Levels Normal',
                      icon: Icons.water_drop_outlined,
                      iconColor: summary.kpis.wastewaterAlerts > 0 ? AppColors.error : AppColors.secondary,
                      bgColor: (summary.kpis.wastewaterAlerts > 0 ? AppColors.errorLight : AppColors.infoLight).withValues(alpha: 0.4),
                      onTap: () => context.push('/wastewater'),
                    ),
                  ],
                );
              },
            ),

            if (summary.incidentsByCategory.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'Category Breakdown',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMedium),
              ),
              const SizedBox(height: 8),
              _buildCategoryBars(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return AnimatedTap(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: iconColor.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: iconColor.withValues(alpha: 0.7)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                color: AppColors.textMedium,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBars(BuildContext context) {
    final entries = summary.incidentsByCategory.entries.take(4).toList();
    final int maxVal = entries.fold(0, (max, e) => e.value > max ? e.value : max);

    return Column(
      children: entries.map((entry) {
        final double ratio = maxVal > 0 ? (entry.value / maxVal) : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  entry.key,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.value}',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMedium),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
