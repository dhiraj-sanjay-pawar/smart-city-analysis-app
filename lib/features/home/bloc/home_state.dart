import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/models/hospital_model.dart';
import '../../../data/models/dashboard_summary_model.dart';
import '../../../data/models/ai_overview_model.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final UserModel user;
  final List<ComplaintModel> recentComplaints;
  final List<HospitalModel> nearbyHospitals;
  final int unreadNotifications;
  final DashboardSummaryModel? dashboardSummary;
  final AiOverviewModel? aiOverview;

  const HomeLoaded({
    required this.user,
    required this.recentComplaints,
    required this.nearbyHospitals,
    required this.unreadNotifications,
    this.dashboardSummary,
    this.aiOverview,
  });

  HomeLoaded copyWith({
    UserModel? user,
    List<ComplaintModel>? recentComplaints,
    List<HospitalModel>? nearbyHospitals,
    int? unreadNotifications,
    DashboardSummaryModel? dashboardSummary,
    AiOverviewModel? aiOverview,
  }) {
    return HomeLoaded(
      user: user ?? this.user,
      recentComplaints: recentComplaints ?? this.recentComplaints,
      nearbyHospitals: nearbyHospitals ?? this.nearbyHospitals,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      dashboardSummary: dashboardSummary ?? this.dashboardSummary,
      aiOverview: aiOverview ?? this.aiOverview,
    );
  }

  @override
  List<Object?> get props => [
        user,
        recentComplaints,
        nearbyHospitals,
        unreadNotifications,
        dashboardSummary,
        aiOverview,
      ];
}

class HomeError extends HomeState {
  final String message;
  const HomeError({required this.message});
  @override
  List<Object?> get props => [message];
}
