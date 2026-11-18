import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/models/complaint_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_animations.dart';

class ComplaintDetailsSheet extends StatelessWidget {
  final ComplaintModel complaint;

  const ComplaintDetailsSheet({super.key, required this.complaint});

  static void show(BuildContext context, ComplaintModel complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ComplaintDetailsSheet(complaint: complaint),
    );
  }

  Color _statusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.submitted: return const Color(0xFF6366F1);
      case ComplaintStatus.inProgress: return const Color(0xFFD97706);
      case ComplaintStatus.resolved: return AppColors.success;
      case ComplaintStatus.rejected: return AppColors.error;
    }
  }

  Color _statusBg(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.submitted: return const Color(0xFFEEF2FF);
      case ComplaintStatus.inProgress: return const Color(0xFFFEF3C7);
      case ComplaintStatus.resolved: return AppColors.successLight;
      case ComplaintStatus.rejected: return AppColors.errorLight;
    }
  }

  String _statusLabel(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.submitted: return 'Submitted';
      case ComplaintStatus.inProgress: return 'In Progress';
      case ComplaintStatus.resolved: return 'Resolved';
      case ComplaintStatus.rejected: return 'Rejected';
    }
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

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (complaint.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    complaint.imageUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.assignment_rounded, color: AppColors.primary),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          complaint.id,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMedium,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusBg(complaint.status),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            _statusLabel(complaint.status),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _statusColor(complaint.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      complaint.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📍 ${complaint.location}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMedium),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          Text(
            'Description',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            complaint.description,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark, height: 1.4),
          ),

          const SizedBox(height: 16),
          Text(
            'Resolution Timeline',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),

          ...complaint.statusHistory.map((history) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _statusColor(history.status),
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 32,
                        color: Colors.grey.shade200,
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _statusLabel(history.status),
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('dd MMM, hh:mm a').format(history.timestamp),
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          history.note,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMedium),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),
          AnimatedTap(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.textDark,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                'Close Details',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
