import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../data/models/user_model.dart';

class HomeHeader extends StatelessWidget {
  final UserModel user;
  final int unreadCount;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;
  final Function(String)? onSearch;

  const HomeHeader({
    super.key,
    required this.user,
    required this.unreadCount,
    required this.onNotificationTap,
    required this.onProfileTap,
    this.onSearch,
  });

  String _displayName() {
    final trimmed = user.name.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'citizen') {
      return 'Citizen';
    }
    return trimmed.split(' ').first;
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? AppStrings.goodMorning
        : (hour < 17 ? AppStrings.goodAfternoon : AppStrings.goodEvening);
    return '$timeGreeting, ${_displayName()}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: AppDimensions.screenPadding,
        right: AppDimensions.screenPadding,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Profile row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greetingText(),
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Welcome to Nashik Smart City Portal',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  // Bell notification icon with badge
                  AnimatedTap(
                    onTap: onNotificationTap,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: AppColors.textDark,
                            size: 22,
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              child: Center(
                                child: Text(
                                  '$unreadCount',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // User Avatar Circle (Teal with initials)
                  AnimatedTap(
                    onTap: onProfileTap,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F766E), // Teal
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user.initials,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search bar (Modern, rounded, no filter button)
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.secondary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: onSearch,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                    decoration: InputDecoration(
                      hintText: 'Search services, hospitals, routes, alerts...',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
