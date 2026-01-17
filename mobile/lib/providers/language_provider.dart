import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/translation_service.dart';

enum AppLanguage { english, hindi, marathi }

class LanguageProvider extends ChangeNotifier {
  static const _prefsKey = 'preferred_language';

  AppLanguage _language = AppLanguage.english;
  AppLanguage get language => _language;

  String get displayName {
    switch (_language) {
      case AppLanguage.hindi:
        return 'हिंदी';
      case AppLanguage.marathi:
        return 'मराठी';
      case AppLanguage.english:
      default:
        return 'English';
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefsKey);
    if (value != null) {
      _language = _fromString(value);
      // Eagerly prepare model for the selected language if not English
      if (_language != AppLanguage.english) {
        _prepareModel(_language);
      }
      notifyListeners();
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    _language = language;
    notifyListeners();
    
    // Trigger model download/preparation in background
    if (language != AppLanguage.english) {
      _prepareModel(language);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _toString(language));
  }

  Future<void> _prepareModel(AppLanguage language) async {
    try {
      await TranslationService.instance.ensureModel(language);
    } catch (e) {
      debugPrint('Error preparing translation model: $e');
    }
  }

  AppLanguage _fromString(String value) {
    switch (value) {
      case 'hi':
        return AppLanguage.hindi;
      case 'mr':
        return AppLanguage.marathi;
      case 'en':
      default:
        return AppLanguage.english;
    }
  }

  String _toString(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.hindi:
        return 'hi';
      case AppLanguage.marathi:
        return 'mr';
      case AppLanguage.english:
      default:
        return 'en';
    }
  }

  Locale get locale {
    switch (_language) {
      case AppLanguage.hindi:
        return const Locale('hi');
      case AppLanguage.marathi:
        return const Locale('mr');
      case AppLanguage.english:
      default:
        return const Locale('en');
    }
  }
}
