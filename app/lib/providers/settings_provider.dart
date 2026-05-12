import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AURA Social – Settings Provider
///
/// Person 4, Task (supporting)
/// Persistent settings dùng SharedPreferences.
/// Quản lý: theme mode, notification prefs, AI feature toggles.

class SettingsState {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool emotionalAnalysis;
  final bool behavioralTracking;
  final bool contentRecommendations;
  final bool soulConnectAI;
  final bool wellbeingGuard;

  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.notificationsEnabled = true,
    this.emotionalAnalysis = true,
    this.behavioralTracking = true,
    this.contentRecommendations = true,
    this.soulConnectAI = true,
    this.wellbeingGuard = true,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? emotionalAnalysis,
    bool? behavioralTracking,
    bool? contentRecommendations,
    bool? soulConnectAI,
    bool? wellbeingGuard,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emotionalAnalysis: emotionalAnalysis ?? this.emotionalAnalysis,
      behavioralTracking: behavioralTracking ?? this.behavioralTracking,
      contentRecommendations: contentRecommendations ?? this.contentRecommendations,
      soulConnectAI: soulConnectAI ?? this.soulConnectAI,
      wellbeingGuard: wellbeingGuard ?? this.wellbeingGuard,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 2; // default dark
    state = SettingsState(
      themeMode: ThemeMode.values[themeIndex],
      notificationsEnabled: prefs.getBool('notif_enabled') ?? true,
      emotionalAnalysis: prefs.getBool('ai_emotional') ?? true,
      behavioralTracking: prefs.getBool('ai_behavioral') ?? true,
      contentRecommendations: prefs.getBool('ai_content') ?? true,
      soulConnectAI: prefs.getBool('ai_soul') ?? true,
      wellbeingGuard: prefs.getBool('ai_wellbeing') ?? true,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_enabled', value);
  }

  Future<void> setEmotionalAnalysis(bool value) async {
    state = state.copyWith(emotionalAnalysis: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_emotional', value);
  }

  Future<void> setBehavioralTracking(bool value) async {
    state = state.copyWith(behavioralTracking: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_behavioral', value);
  }

  Future<void> setContentRecommendations(bool value) async {
    state = state.copyWith(contentRecommendations: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_content', value);
  }

  Future<void> setSoulConnectAI(bool value) async {
    state = state.copyWith(soulConnectAI: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_soul', value);
  }

  Future<void> setWellbeingGuard(bool value) async {
    state = state.copyWith(wellbeingGuard: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_wellbeing', value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

/// Convenient provider chỉ cho theme mode
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});
