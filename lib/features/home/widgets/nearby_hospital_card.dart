import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../core/widgets/hospital_details_sheet.dart';
import '../../../data/models/hospital_model.dart';

class NearbyHospitalCard extends StatelessWidget {
  final HospitalModel hospital;

  const NearbyHospitalCard({super.key, required this.hospital});

  @override
  Widget build(BuildContext context) {
    final isMedicalCamp = hospital.type == HospitalType.medicalCamp;
    final isFirstAid = hospital.type == HospitalType.firstAid;

    final badgeText = isMedicalCamp
        ? 'Free'
        : (hospital.isOpen24Hours ? '24/7' : 'Open');
    final tagText = isMedicalCamp
        ? 'Medical Camp'
        : (isFirstAid ? 'First Aid' : (hospital.type == HospitalType.government ? 'Government' : 'Hospital'));

    final Color tagColor = isMedicalCamp
        ? const Color(0xFF0F766E)
        : (isFirstAid ? const Color(0xFFDC2626) : const Color(0xFF2563EB));

    return AnimatedTap(
      onTap: () => HospitalDetailsSheet.show(context, hospital),
      child: Container(
        width: 310,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Image / Visual Container
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 82,
                height: 106,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hospital.imageUrl != null && hospital.imageUrl!.isNotEmpty)
                      Image.asset(
                        hospital.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                      )
                    else
                      _buildPlaceholder(),

                    // Subtle gradient overlay for readability
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        color: Colors.black.withValues(alpha: 0.55),
                        child: Text(
                          '${hospital.distanceKm} km',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Right Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Tags Row
                  Row(
                    children: [
                      // Type tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tagText,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: tagColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Status / 24/7 pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Rating
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                          const SizedBox(width: 2),
                          Text(
                            hospital.rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // Facility Name
                  Text(
                    hospital.name,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 3),

                  // Address Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: AppColors.textLight),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          hospital.address,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMedium,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Bottom info: Available beds & action
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.hotel_rounded, size: 12, color: AppColors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              '${hospital.availableBeds} beds free',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: AppColors.textMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFEFF6FF),
      child: const Center(
        child: Icon(
          Icons.local_hospital_rounded,
          color: Color(0xFF0284C7),
          size: 36,
        ),
      ),
    );
  }
}
