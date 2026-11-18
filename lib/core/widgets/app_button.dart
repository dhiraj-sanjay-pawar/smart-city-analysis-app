import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

enum AppButtonVariant { primary, secondary, outlined, danger, ghost }
enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final height = switch (size) {
      AppButtonSize.small => AppDimensions.buttonHeightSm,
      AppButtonSize.medium => AppDimensions.buttonHeight,
      AppButtonSize.large => 56.0,
    };

    final fontSize = switch (size) {
      AppButtonSize.small => 13.0,
      AppButtonSize.medium => 15.0,
      AppButtonSize.large => 16.0,
    };

    final padding = switch (size) {
      AppButtonSize.small => const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      AppButtonSize.medium => const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      AppButtonSize.large => const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    };

    return switch (variant) {
      AppButtonVariant.primary => _buildElevated(
          context,
          bg: AppColors.primary,
          fg: Colors.white,
          height: height,
          fontSize: fontSize,
          padding: padding,
        ),
      AppButtonVariant.secondary => _buildElevated(
          context,
          bg: AppColors.secondary,
          fg: Colors.white,
          height: height,
          fontSize: fontSize,
          padding: padding,
        ),
      AppButtonVariant.danger => _buildElevated(
          context,
          bg: AppColors.error,
          fg: Colors.white,
          height: height,
          fontSize: fontSize,
          padding: padding,
        ),
      AppButtonVariant.outlined => _buildOutlined(
          context,
          height: height,
          fontSize: fontSize,
          padding: padding,
        ),
      AppButtonVariant.ghost => _buildGhost(
          context,
          height: height,
          fontSize: fontSize,
          padding: padding,
        ),
    };
  }

  Widget _buildContent(double fontSize) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == AppButtonVariant.outlined
                ? AppColors.primary
                : Colors.white,
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: fontSize + 2),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: fontSize + 2),
        ],
      ],
    );
  }

  Widget _buildElevated(
    BuildContext context, {
    required Color bg,
    required Color fg,
    required double height,
    required double fontSize,
    required EdgeInsets padding,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          elevation: 0,
          disabledBackgroundColor: bg.withValues(alpha: 0.5),
        ),
        child: _buildContent(fontSize),
      ),
    );
  }

  Widget _buildOutlined(
    BuildContext context, {
    required double height,
    required double fontSize,
    required EdgeInsets padding,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        child: _buildContent(fontSize),
      ),
    );
  }

  Widget _buildGhost(
    BuildContext context, {
    required double height,
    required double fontSize,
    required EdgeInsets padding,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: padding,
        ),
        child: _buildContent(fontSize),
      ),
    );
  }
}
