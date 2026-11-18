// ignore_for_file: prefer_initializing_formals
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../../data/repositories/hospital_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../../data/models/dashboard_summary_model.dart';
import '../../../data/models/ai_overview_model.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final AuthRepository _authRepository;
  final ComplaintRepository _complaintRepository;
  final HospitalRepository _hospitalRepository;
  final NotificationRepository _notificationRepository;
  final DashboardRepository _dashboardRepository;
  final AiRepository _aiRepository;

  HomeCubit({
    required AuthRepository authRepository,
    required ComplaintRepository complaintRepository,
    required HospitalRepository hospitalRepository,
    required NotificationRepository notificationRepository,
    DashboardRepository? dashboardRepository,
    AiRepository? aiRepository,
  })  : _authRepository = authRepository,
        _complaintRepository = complaintRepository,
        _hospitalRepository = hospitalRepository,
        _notificationRepository = notificationRepository,
        _dashboardRepository = dashboardRepository ?? DashboardRepository(),
        _aiRepository = aiRepository ?? AiRepository(),
        super(const HomeInitial());

  Future<void> loadHome() async {
    emit(const HomeLoading());
    try {
      final user = _authRepository.currentUser;
      if (user == null) {
        emit(const HomeError(message: 'User session not found. Please log in.'));
        return;
      }

      final results = await Future.wait([
        _complaintRepository.getRecentComplaints(userId: user.id, limit: 3),
        _hospitalRepository.getHomeHospitals(),
        _notificationRepository.getUnreadCount(),
        _dashboardRepository.getSummary(),
        _aiRepository.getCitizenOverview(),
      ]);

      emit(HomeLoaded(
        user: user,
        recentComplaints: results[0] as dynamic,
        nearbyHospitals: results[1] as dynamic,
        unreadNotifications: results[2] as int,
        dashboardSummary: results[3] as DashboardSummaryModel,
        aiOverview: results[4] as AiOverviewModel?,
      ));
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }

  Future<void> refresh() async {
    await loadHome();
  }

  void updateUnreadCount(int count) {
    if (state is HomeLoaded) {
      emit((state as HomeLoaded).copyWith(unreadNotifications: count));
    }
  }
}
