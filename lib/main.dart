import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/api/api_config.dart';
import 'data/repositories/auth_repository.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize central API configuration and auth session
  await ApiConfig.init();
  final authRepository = AuthRepository();
  await authRepository.init();

  // Allow multi-device orientations (portrait and landscape) for phones, tablets & desktops
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // System UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(SmartCityApp(authRepository: authRepository));
}
