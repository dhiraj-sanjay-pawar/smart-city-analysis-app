import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_animations.dart';

class ExploreServicesSheet extends StatelessWidget {
  const ExploreServicesSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExploreServicesSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = [
      _ServiceItem('Traffic Management', 'Live road status & parking', Icons.directions_car_rounded, const Color(0xFF0284C7), '/traffic'),
      _ServiceItem('Healthcare Services', 'Hospitals, camps & 24/7 care', Icons.medical_services_rounded, const Color(0xFF0F766E), '/healthcare'),
      _ServiceItem('Wastewater & Drainage', 'Waterlogging & sewage issues', Icons.water_damage_rounded, const Color(0xFF2563EB), '/wastewater'),
      _ServiceItem('File a Grievance', 'Report public civic issues', Icons.campaign_rounded, const Color(0xFF0F766E), '/complaints/new'),
      _ServiceItem('Smart City Map', 'Interactive GIS city map', Icons.map_rounded, const Color(0xFF059669), '/map'),
      _ServiceItem('My Reports', 'Track grievance timeline', Icons.assignment_rounded, const Color(0xFF7C3AED), '/reports'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: AppDimensions.screenPadding,
        right: AppDimensions.screenPadding,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Smart City Services',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            'Explore citizen amenities & civic grievance channels',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMedium),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemBuilder: (context, i) {
              final s = services[i];
              return AnimatedTap(
                onTap: () {
                  Navigator.pop(context);
                  context.push(s.route);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: s.color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: s.color.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: s.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(s.icon, color: s.color, size: 20),
                      ),
                      const Spacer(),
                      Text(
                        s.title,
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        s.subtitle,
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMedium),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ServiceItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  _ServiceItem(this.title, this.subtitle, this.icon, this.color, this.route);
}
