import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/localization.dart';

class SettingsProvider extends ChangeNotifier {
  bool notificationsEnabled = true;
  String language = 'English';
  bool isDarkMode = false;
  String geminiApiKey = '';

  AppLocalization get l10n => AppLocalization(language);

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    language = prefs.getString('language') ?? 'English';
    isDarkMode = prefs.getBool('isDarkMode') ?? false;
    geminiApiKey = prefs.getString('geminiApiKey') ?? AppConstants.geminiApiKey;
    notifyListeners();
  }

  Future<void> setGeminiApiKey(String value) async {
    geminiApiKey = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('geminiApiKey', value);
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    language = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    notifyListeners();
  }
}
