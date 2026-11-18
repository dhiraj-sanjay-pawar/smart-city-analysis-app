import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _slides = const [
    _OnboardingItem(
      image: 'assets/images/onboarding_traffic.png',
      tag: '🚦 Traffic Management',
      title: 'Smart Route Guidance\n& Live Traffic Telemetry',
      subtitle:
          'Navigate Nashik effortlessly with real-time congestion tracking, parking availability, and smooth pilgrimage corridors towards Ramkund and Tapovan.',
    ),
    _OnboardingItem(
      image: 'assets/images/onboarding_health.png',
      tag: '🏥 Healthcare Services',
      title: '24/7 Medical Camps\n& Hospital Bed Tracking',
      subtitle:
          'Locate nearby government and private hospitals, check live ICU bed availability, and access free medical camps and emergency ambulance services.',
    ),
    _OnboardingItem(
      image: 'assets/images/onboarding_crime.png',
      tag: '🛡️ Crime & Public Safety',
      title: 'Rapid Grievance Redressal\n& Citizen Protection',
      subtitle:
          'Report civic hazards, potholes, streetlighting, and security concerns with geotagged photo uploads and live municipal resolution tracking.',
    ),
    _OnboardingItem(
      image: 'assets/images/onboarding_waste.png',
      tag: '💧 Wastewater Management',
      title: 'River Godavari Monitoring\n& Drainage Telemetry',
      subtitle:
          'Stay informed with automated sensor observations tracking Godavari River water levels, environmental safety, and municipal sanitation telemetry.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 650;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 520 : double.infinity),
                child: Column(
                  children: [
                    // Top Bar (Logo & Skip button)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.location_city_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Smart City',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          if (!isLastPage)
                            TextButton(
                              onPressed: _finishOnboarding,
                              child: Text(
                                'Skip',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMedium,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Slides PageView
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _slides.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final item = _slides[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Hero image card
                                Expanded(
                                  flex: 5,
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: AppColors.border),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.08),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.asset(
                                            item.image,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: AppColors.primary,
                                              child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 48),
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.transparent,
                                                  AppColors.primaryDark.withValues(alpha: 0.7),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 16,
                                            left: 16,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppColors.secondary,
                                                borderRadius: BorderRadius.circular(30),
                                              ),
                                              child: Text(
                                                item.tag,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.96, 0.96)),
                                ),

                                const SizedBox(height: 16),

                                // Title & Subtitle
                                Expanded(
                                  flex: 5,
                                  child: SingleChildScrollView(
                                    physics: const ClampingScrollPhysics(),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.title,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textDark,
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          item.subtitle,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: AppColors.textMedium,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Bottom controls (Dots indicator and Next / Get Started button)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Dots Indicator
                          Row(
                            children: List.generate(_slides.length, (idx) {
                              final isActive = idx == _currentPage;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(right: 6),
                                width: isActive ? 26 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isActive ? AppColors.secondary : AppColors.borderWarm,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),

                          // Next / Get Started button
                          ElevatedButton(
                            onPressed: () {
                              if (!isLastPage) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                _finishOnboarding();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isLastPage ? 'Get Started' : 'Next',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_rounded, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingItem {
  final String image;
  final String tag;
  final String title;
  final String subtitle;

  const _OnboardingItem({
    required this.image,
    required this.tag,
    required this.title,
    required this.subtitle,
  });
}
