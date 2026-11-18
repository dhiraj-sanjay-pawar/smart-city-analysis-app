import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/complaint_repository.dart';
import 'data/repositories/dashboard_repository.dart';
import 'data/repositories/hospital_repository.dart';
import 'data/repositories/map_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/reports_repository.dart';
import 'data/repositories/traffic_repository.dart';
import 'data/repositories/wastewater_repository.dart';
import 'data/repositories/ai_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/home/bloc/home_cubit.dart';
import 'features/map/bloc/map_cubit.dart';
import 'features/ai/bloc/ai_cubit.dart';

class SmartCityApp extends StatelessWidget {
  final AuthRepository? authRepository;

  const SmartCityApp({super.key, this.authRepository});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => authRepository ?? AuthRepository()),
        RepositoryProvider<ComplaintRepository>(create: (_) => ComplaintRepository()),
        RepositoryProvider<DashboardRepository>(create: (_) => DashboardRepository()),
        RepositoryProvider<HospitalRepository>(create: (_) => HospitalRepository()),
        RepositoryProvider<NotificationRepository>(create: (_) => NotificationRepository()),
        RepositoryProvider<TrafficRepository>(create: (_) => TrafficRepository()),
        RepositoryProvider<WastewaterRepository>(create: (_) => WastewaterRepository()),
        RepositoryProvider<MapRepository>(create: (_) => MapRepository()),
        RepositoryProvider<ReportsRepository>(create: (_) => ReportsRepository()),
        RepositoryProvider<AiRepository>(create: (_) => AiRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
          BlocProvider<AuthBloc>(
            create: (ctx) => AuthBloc(
              authRepository: ctx.read<AuthRepository>(),
            )..add(const AuthCheckRequested()),
          ),
          BlocProvider<HomeCubit>(
            create: (ctx) => HomeCubit(
              authRepository: ctx.read<AuthRepository>(),
              complaintRepository: ctx.read<ComplaintRepository>(),
              hospitalRepository: ctx.read<HospitalRepository>(),
              notificationRepository: ctx.read<NotificationRepository>(),
              dashboardRepository: ctx.read<DashboardRepository>(),
              aiRepository: ctx.read<AiRepository>(),
            ),
          ),
          BlocProvider<MapCubit>(
            create: (ctx) => MapCubit(
              mapRepository: ctx.read<MapRepository>(),
            )..loadMapFeatures(),
          ),
          BlocProvider<AiCubit>(
            create: (ctx) => AiCubit(
              aiRepository: ctx.read<AiRepository>(),
            ),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp.router(
              title: 'SmartCity Citizen App',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeState.themeMode,
              routerConfig: appRouter,
            );
          },
        ),
      ),
    );
  }
}
