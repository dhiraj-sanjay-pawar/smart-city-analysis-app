import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../core/widgets/explore_services_sheet.dart';

class HeroBannerCard extends StatefulWidget {
  const HeroBannerCard({super.key});

  @override
  State<HeroBannerCard> createState() => _HeroBannerCardState();
}

class _BannerItem {
  final String tag;
  final String title;
  final String subtitle;
  final String imagePath;
  final String buttonText;
  final VoidCallback Function(BuildContext context) onAction;

  const _BannerItem({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.buttonText,
    required this.onAction,
  });
}

class _HeroBannerCardState extends State<HeroBannerCard> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  final List<_BannerItem> _banners = [
    _BannerItem(
      tag: '🌿 Smart City Nashik',
      title: 'Nashik Kumbh Mela\nCitizen Command',
      subtitle: 'Unified Real-time Monitoring & Citizen Services',
      imagePath: 'assets/images/banner_kumbh_smart_city.png',
      buttonText: 'Explore Services',
      onAction: (ctx) => () => ExploreServicesSheet.show(ctx),
    ),
    _BannerItem(
      tag: '🚦 Live Transit',
      title: 'Smart Traffic &\nLive Route Guidance',
      subtitle: 'Real-time Flow, Congestion & Parking Alerts',
      imagePath: 'assets/images/banner_traffic_routes.png',
      buttonText: 'View Routes',
      onAction: (ctx) => () => ctx.push('/traffic'),
    ),
    _BannerItem(
      tag: '🏥 24x7 Healthcare',
      title: 'Emergency Medical\n& Hospital Camps',
      subtitle: 'Live Bed Availability & Rapid Emergency Aid',
      imagePath: 'assets/images/banner_emergency_health.png',
      buttonText: 'Find Hospitals',
      onAction: (ctx) => () => ctx.push('/healthcare'),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Start at an offset so backwards swipe also works, or standard 0 with loop
    _pageController = PageController(initialPage: 0);
    _startTimer();
  }

  void _startTimer() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % _banners.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _resetTimer() {
    _startTimer();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      child: Container(
        height: 185,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // PageView for 1 -> 2 -> 3 loop
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification) {
                    _autoScrollTimer?.cancel();
                  } else if (notification is ScrollEndNotification) {
                    _resetTimer();
                  }
                  return false;
                },
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _banners.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final banner = _banners[index];
                    return _buildBannerSlide(context, banner);
                  },
                ),
              ),

              // Pagination Dots at bottom
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_banners.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 5,
                      width: isActive ? 20 : 6,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerSlide(BuildContext context, _BannerItem banner) {
    return Stack(
      children: [
        // Background Image with safe fallback
        Positioned.fill(
          child: Image.asset(
            banner.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              'assets/images/hero_banner.png',
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Gradient Overlay for high-contrast readable typography
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFF0F172A).withValues(alpha: 0.85),
                  const Color(0xFF0F172A).withValues(alpha: 0.45),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tag pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Text(
                  banner.tag,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Headline
              Text(
                banner.title,
                style: GoogleFonts.poppins(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),

              const SizedBox(height: 4),

              // Subtitle
              Text(
                banner.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              // Action button
              AnimatedTap(
                onTap: banner.onAction(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        banner.buttonText,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6), // Spacing for dots
            ],
          ),
        ),
      ],
    );
  }
}
