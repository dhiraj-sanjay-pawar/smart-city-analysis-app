import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/hospital_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_animations.dart';

class HospitalDetailsSheet extends StatelessWidget {
  final HospitalModel hospital;

  const HospitalDetailsSheet({super.key, required this.hospital});

  static void show(BuildContext context, HospitalModel hospital) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HospitalDetailsSheet(hospital: hospital),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          // Drag handle
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

          // Header row with optional image
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hospital.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    hospital.imageUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFBF1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Color(0xFF0F766E),
                    size: 32,
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: hospital.isOpen24Hours ? AppColors.successLight : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            hospital.isOpen24Hours ? 'OPEN 24/7' : (hospital.type == HospitalType.medicalCamp ? 'FREE CAMP' : 'CLINIC'),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: hospital.isOpen24Hours ? AppColors.success : const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${hospital.rating}',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hospital.name,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📍 ${hospital.distanceKm} km • ${hospital.typeLabel}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.place_outlined, color: AppColors.textMedium, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hospital.address,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          // Timings
          if (hospital.timings != null) ...[
            Row(
              children: [
                const Icon(Icons.access_time_rounded, color: AppColors.textMedium, size: 20),
                const SizedBox(width: 10),
                Text(
                  hospital.timings!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Specialties
          Text(
            'Specialties & Services',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: hospital.specialties.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.backgroundAlt,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  s,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textDark),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: AnimatedTap(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calling ${hospital.name} (${hospital.phone})...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Call Center',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedTap(
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/map', extra: {
                      'title': hospital.name,
                      'location': hospital.address,
                      'type': hospital.type == HospitalType.medicalCamp ? 'Medical Camp' : 'Hospital',
                      'category': '➕ Hospitals',
                      'details': '${hospital.typeLabel} • ${hospital.availableBeds} beds available • 24/7 Emergency Support • Tel: ${hospital.phone}',
                    });
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF0F766E), width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_rounded, color: Color(0xFF0F766E), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Directions',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
