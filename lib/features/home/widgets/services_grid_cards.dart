import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_animations.dart';

class ServicesGridCards extends StatelessWidget {
  const ServicesGridCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 650;
          final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // 1. Traffic Management
              _ServiceCard(
                width: cardWidth,
                title: 'Traffic Management',
                subtitle: 'Real-time routes, congestion & parking',
                icon: Icons.directions_car_rounded,
                iconColor: const Color(0xFF0284C7),
                iconBgColor: const Color(0xFFE0F2FE),
                imagePath: 'assets/images/service_traffic_card.png',
                fallbackPath: 'assets/images/service_traffic.png',
                onTap: () => context.push('/traffic'),
              ),

              // 2. Healthcare Services
              _ServiceCard(
                width: cardWidth,
                title: 'Healthcare Services',
                subtitle: 'Hospitals, ICU beds & medical camps',
                icon: Icons.local_hospital_rounded,
                iconColor: const Color(0xFF0F766E),
                iconBgColor: const Color(0xFFCCFBF1),
                imagePath: 'assets/images/service_health_card.png',
                fallbackPath: 'assets/images/service_healthcare.png',
                onTap: () => context.push('/healthcare'),
              ),

              // 3. Crime & Complaints
              _ServiceCard(
                width: cardWidth,
                title: 'Crime & Complaints',
                subtitle: 'Civic grievances, public safety & alerts',
                icon: Icons.shield_rounded,
                iconColor: const Color(0xFF16324F),
                iconBgColor: const Color(0xFFE2E8F0),
                imagePath: 'assets/images/service_crime_card.png',
                fallbackPath: 'assets/images/cat_crime.png',
                onTap: () => context.go('/reports'),
              ),

              // 4. Wastewater Management
              _ServiceCard(
                width: cardWidth,
                title: 'Wastewater Management',
                subtitle: 'Godavari river levels & drainage telemetry',
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFF0284C7),
                iconBgColor: const Color(0xFFE0F2FE),
                imagePath: 'assets/images/service_waste_card.png',
                fallbackPath: 'assets/images/cat_wastewater.png',
                onTap: () => context.push('/wastewater'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final double width;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String imagePath;
  final String fallbackPath;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.imagePath,
    required this.fallbackPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTap(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon and Arrow Row
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: iconColor, size: 18),
                        ),
                        const Spacer(),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: iconBgColor.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_forward_rounded, color: iconColor, size: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Subtitle
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textMedium,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Image Thumbnail with safe fallback
              SizedBox(
                width: double.infinity,
                height: 84,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    fallbackPath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
