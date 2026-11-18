import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../data/models/complaint_model.dart';

class StatusBadge extends StatelessWidget {
  final ComplaintStatus status;
  final bool small;

  const StatusBadge({
    super.key,
    required this.status,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg, icon) = switch (status) {
      ComplaintStatus.submitted => (
          'Submitted',
          AppColors.statusSubmitted,
          AppColors.statusSubmittedLight,
          Icons.upload_rounded,
        ),
      ComplaintStatus.inProgress => (
          'In Progress',
          AppColors.statusInProgress,
          AppColors.statusInProgressLight,
          Icons.autorenew_rounded,
        ),
      ComplaintStatus.resolved => (
          'Resolved',
          AppColors.statusResolved,
          AppColors.statusResolvedLight,
          Icons.check_circle_rounded,
        ),
      ComplaintStatus.rejected => (
          'Rejected',
          AppColors.statusRejected,
          AppColors.statusRejectedLight,
          Icons.cancel_rounded,
        ),
    };

    final fontSize = small ? 10.0 : 11.5;
    final iconSize = small ? 10.0 : 12.0;
    final hPad = small ? 8.0 : 10.0;
    final vPad = small ? 3.0 : 5.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: iconSize),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// Generic colored badge (for categories, types, etc.)
class ColorBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final IconData? icon;
  final bool small;

  const ColorBadge({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.icon,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? color.withValues(alpha: 0.12);
    final fontSize = small ? 10.0 : 11.5;
    final iconSize = small ? 10.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: iconSize),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
