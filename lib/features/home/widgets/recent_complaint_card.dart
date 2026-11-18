import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../core/widgets/complaint_details_sheet.dart';
import '../../../data/models/complaint_model.dart';

class RecentComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;

  const RecentComplaintCard({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    final isSubmitted = complaint.status == ComplaintStatus.submitted;
    final badgeColor = isSubmitted ? const Color(0xFF6366F1) : const Color(0xFFD97706);
    final badgeBgColor = isSubmitted ? const Color(0xFFEEF2FF) : const Color(0xFFFEF3C7);
    final badgeIcon = isSubmitted ? '↑ ' : '⏱ ';
    final badgeText = isSubmitted ? 'Submitted' : 'In Progress';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPadding,
        vertical: 5,
      ),
      child: AnimatedTap(
        onTap: () => ComplaintDetailsSheet.show(context, complaint),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Photo Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: complaint.imageUrl != null
                      ? Image.asset(complaint.imageUrl!, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.backgroundAlt,
                          child: const Icon(Icons.assignment_rounded, color: AppColors.primary),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Title, ID, Date, Location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.title,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${complaint.id} • ${DateFormat('dd MMM').format(complaint.submittedAt)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF0F766E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 12, color: AppColors.textLight),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            complaint.location,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: AppColors.textMedium,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Badge and Chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$badgeIcon$badgeText',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textLight,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
