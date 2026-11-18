import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../core/widgets/explore_services_sheet.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../bloc/home_cubit.dart';
import '../bloc/home_state.dart';
import '../widgets/emergency_alert_banner.dart';
import '../widgets/hero_banner_card.dart';
import '../widgets/home_header.dart';
import '../widgets/nearby_hospital_card.dart';
import '../widgets/recent_complaint_card.dart';
import '../widgets/services_grid_cards.dart';
import '../widgets/ai_insights_card.dart';
import '../widgets/ai_assistant_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().loadHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 900 : double.infinity),
              child: BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) {
                  if (state is HomeLoading || state is HomeInitial) return _buildLoading();
                  if (state is HomeError) return _buildError(state.message);
                  if (state is HomeLoaded) return _buildContent(context, state);
                  return const SizedBox.shrink();
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnimatedTap(
          onTap: () => context.push('/complaints/new'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.secondary, // Teal theme
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Report Issue',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 120),
          ShimmerList(count: 4),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
            const Gap(16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textMedium),
            ),
            const Gap(16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => context.read<HomeCubit>().loadHome(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HomeLoaded state) {
    final filteredHospitals = state.nearbyHospitals.where((h) {
      if (_searchQuery.isEmpty) return true;
      return h.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          h.address.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredComplaints = state.recentComplaints.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.location.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return RefreshIndicator(
      onRefresh: () => context.read<HomeCubit>().refresh(),
      color: AppColors.secondary,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header (Greeting, User Name, Notification Bell, Teal Avatar, Search Bar)
          HomeHeader(
            user: state.user,
            unreadCount: state.unreadNotifications,
            onNotificationTap: () => context.push('/notifications'),
            onProfileTap: () => context.go('/profile'),
            onSearch: (q) => setState(() => _searchQuery = q.trim()),
          ),

          const SizedBox(height: 14),

          // Emergency Alert Banner (Clickable -> EmergencyDetailsSheet)
          EmergencyAlertBanner(
            title: state.aiOverview != null
                ? 'Public Safety Alert • ${state.aiOverview!.safetyStatus}'
                : null,
            advisory: state.aiOverview?.safetyAdvisory,
          ),

          const SizedBox(height: 16),

          // Hero Banner (Together for a Better City, Clickable -> ExploreServicesSheet)
          const HeroBannerCard(),

          const SizedBox(height: 20),

          // Our Services Section
          _buildSectionHeader(
            title: 'Our Services',
            actionText: 'View All >',
            onAction: () => ExploreServicesSheet.show(context),
          ),
          const SizedBox(height: 10),
          const ServicesGridCards(),

          const SizedBox(height: 24),

          // AI City Insights Section
          _buildSectionHeader(
            title: 'AI City Insights',
            actionText: 'Full Report >',
            onAction: () => context.push('/ai/insights'),
          ),
          const SizedBox(height: 10),
          if (state.aiOverview != null)
            AiInsightsCard(overview: state.aiOverview!)
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology_outlined, color: AppColors.textLight, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI city intelligence is temporarily unavailable.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMedium),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // AI Assistant Banner
          const AiAssistantBanner(),

          const SizedBox(height: 24),

          // Nearby Hospitals Section (Clickable)
          _buildSectionHeader(
            title: 'Nearby Healthcare Facilities',
            actionText: 'View All >',
            onAction: () => context.push('/healthcare'),
          ),
          const SizedBox(height: 10),
          if (filteredHospitals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding, vertical: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_hospital_rounded, color: AppColors.secondary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'No nearby healthcare facilities are available right now.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 142,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
                itemCount: filteredHospitals.length,
                itemBuilder: (context, index) {
                  return NearbyHospitalCard(hospital: filteredHospitals[index]);
                },
              ),
            ),

          const SizedBox(height: 24),

          // Recent Complaints Section (Clickable)
          _buildSectionHeader(
            title: 'Recent Grievances',
            actionText: 'View All >',
            onAction: () => context.go('/reports'),
          ),
          const SizedBox(height: 10),
          if (filteredComplaints.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding, vertical: 12),
              child: Center(
                child: Text('No complaints matching your query.', style: GoogleFonts.inter(color: AppColors.textMedium)),
              ),
            )
          else
            ...filteredComplaints.map(
              (c) => RecentComplaintCard(complaint: c),
            ),

          const SizedBox(height: 90), // Bottom padding for FAB & nav bar
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionText,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
