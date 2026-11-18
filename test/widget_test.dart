import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city_app/app.dart';
import 'package:smart_city_app/core/constants/app_colors.dart';
import 'package:smart_city_app/core/api/api_config.dart';

void main() {
  test('ApiConfig default production base URL check', () {
    expect(ApiConfig.baseUrl, 'https://smartcity.techsparkventures.in/api/v1');
    expect(ApiConfig.isLocalDev, false);
  });

  test('AppColors Deep Navy & Teal theme verification (No Orange)', () {
    expect(AppColors.primary, const Color(0xFF16324F)); // Deep Navy
    expect(AppColors.secondary, const Color(0xFF0F766E)); // Teal
    expect(AppColors.background, const Color(0xFFF5F7FA)); // Cool Background
    expect(AppColors.cardLight, const Color(0xFFFFFFFF)); // Cards
    expect(AppColors.textDark, const Color(0xFF1E293B)); // Primary Text
    expect(AppColors.textMedium, const Color(0xFF64748B)); // Secondary Text
    expect(AppColors.success, const Color(0xFF16A34A)); // Success
    expect(AppColors.warning, const Color(0xFFD97706)); // Warning
    expect(AppColors.error, const Color(0xFFDC2626)); // Critical
  });

  testWidgets('SmartCityApp smoke test renders MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartCityApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
  });
}
