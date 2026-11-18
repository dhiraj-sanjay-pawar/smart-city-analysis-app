import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── State ─────────────────────────────────────────────────────
class ThemeState extends Equatable {
  final ThemeMode themeMode;
  const ThemeState({this.themeMode = ThemeMode.light});

  bool get isDark => themeMode == ThemeMode.dark;

  ThemeState copyWith({ThemeMode? themeMode}) =>
      ThemeState(themeMode: themeMode ?? this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

// ── Cubit ─────────────────────────────────────────────────────
class ThemeCubit extends Cubit<ThemeState> {
  static const String _themeKey = 'theme_mode';

  ThemeCubit() : super(const ThemeState()) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_themeKey) ?? false;
      emit(ThemeState(
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      ));
    } catch (_) {
      // default to light
    }
  }

  Future<void> toggleTheme() async {
    final newMode = state.isDark ? ThemeMode.light : ThemeMode.dark;
    emit(state.copyWith(themeMode: newMode));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, newMode == ThemeMode.dark);
    } catch (_) {}
  }

  Future<void> setTheme(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, mode == ThemeMode.dark);
    } catch (_) {}
  }
}
