import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/map/map_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/traffic/traffic_screen.dart';
import '../../features/healthcare/healthcare_screen.dart';
import '../../features/wastewater/wastewater_screen.dart';
import '../../features/complaints/screens/new_complaint_screen.dart';
import '../../features/ai/screens/ai_insights_screen.dart';
import '../../features/ai/screens/ai_assistant_screen.dart';
import '../../features/ai/screens/ai_predict_screen.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../widgets/app_animations.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final mobile = state.extra as String? ?? '';
        return OtpScreen(mobile: mobile);
      },
    ),
    GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),

    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => _MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/map',
          builder: (context, state) => MapScreen(
            selectedFacility: state.extra as Map<String, dynamic>?,
          ),
        ),
        GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
        GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      ],
    ),

    GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
    GoRoute(path: '/traffic', builder: (context, state) => const TrafficScreen()),
    GoRoute(path: '/healthcare', builder: (context, state) => const HealthcareScreen()),
    GoRoute(path: '/wastewater', builder: (context, state) => const WastewaterScreen()),
    GoRoute(path: '/ai/insights', builder: (context, state) => const AiInsightsScreen()),
    GoRoute(path: '/ai/assistant', builder: (context, state) => const AiAssistantScreen()),
    GoRoute(path: '/ai/predict', builder: (context, state) => const AiPredictScreen()),
    GoRoute(
      path: '/complaints/new',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return NewComplaintScreen(
          initialLat: extra?['lat'] as double?,
          initialLng: extra?['lng'] as double?,
          initialLocation: extra?['location'] as String?,
        );
      },
    ),
  ],
);

// ── Main Shell with Deep Navy & Teal Bottom Navigation ───────
class _MainShell extends StatelessWidget {
  final Widget child;
  const _MainShell({required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/map')) return 1;
    if (location.startsWith('/reports')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/home');
      case 1: context.go('/map');
      case 2: context.go('/reports');
      case 3: context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: AppStrings.navHome,
                  isActive: currentIndex == 0,
                  onTap: () => _onNavTap(context, 0),
                ),
                _NavItem(
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map_rounded,
                  label: AppStrings.navMap,
                  isActive: currentIndex == 1,
                  onTap: () => _onNavTap(context, 1),
                ),
                _NavItem(
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment_rounded,
                  label: AppStrings.navReports,
                  isActive: currentIndex == 2,
                  onTap: () => _onNavTap(context, 2),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: AppStrings.navProfile,
                  isActive: currentIndex == 3,
                  onTap: () => _onNavTap(context, 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.secondary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? AppColors.primary : AppColors.textLight,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
