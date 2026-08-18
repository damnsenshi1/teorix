import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/country_profile.dart';

class AppSettingsService extends ChangeNotifier {
  AppSettingsService._();
  static final instance = AppSettingsService._();

  static const _countryKey = 'app_country_v11';
  static const _localeKey = 'app_locale_v12';
  static const _contentLocaleKey = 'content_locale_v12';
  static const _onboardingKey = 'app_onboarding_v11';
  static const _profileNameKey = 'profile_name_v4';
  static const _accountChoiceKey = 'account_choice_v122';

  String _countryId = 'tr';
  String _locale = 'tr';
  String _contentLocale = 'tr';
  bool _onboardingComplete = false;
  bool _accountChoiceComplete = false;
  String _profileName = '';

  String get countryId => _countryId;
  String get locale => _locale;
  String get contentLocale => _contentLocale;
  bool get onboardingComplete => _onboardingComplete;
  bool get accountChoiceComplete => _accountChoiceComplete;
  String get profileName => _profileName;
  CountryProfile get country => CountryCatalog.byId(_countryId);

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _countryId = prefs.getString(_countryKey) ?? 'tr';
    final profile = CountryCatalog.byId(_countryId);
    _locale = prefs.getString(_localeKey) ?? profile.primaryLocale;
    _contentLocale = prefs.getString(_contentLocaleKey) ?? profile.primaryLocale;
    if (!profile.supportedLocales.contains(_contentLocale)) _contentLocale = profile.primaryLocale;
    _onboardingComplete = prefs.getBool(_onboardingKey) ?? false;
    _accountChoiceComplete = prefs.getBool(_accountChoiceKey) ?? false;
    final savedName = (prefs.getString(_profileNameKey) ?? '').trim();
    _profileName = savedName == 'Senshi' ? '' : savedName;
  }

  Future<void> setCountry(String id, {bool resetLocaleToPrimary = true}) async {
    final profile = CountryCatalog.byId(id);
    _countryId = profile.id;
    if (resetLocaleToPrimary) {
      _locale = profile.primaryLocale;
      _contentLocale = profile.primaryLocale;
    } else if (!profile.supportedLocales.contains(_contentLocale)) {
      _contentLocale = profile.primaryLocale;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_countryKey, _countryId);
    await prefs.setString(_localeKey, _locale);
    await prefs.setString(_contentLocaleKey, _contentLocale);
    notifyListeners();
  }

  Future<void> setLocale(String locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale);
    notifyListeners();
  }

  Future<void> setContentLocale(String locale) async {
    final profile = country;
    _contentLocale = profile.supportedLocales.contains(locale) ? locale : profile.primaryLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_contentLocaleKey, _contentLocale);
    notifyListeners();
  }


  Future<void> setProfileName(String value) async {
    _profileName = value.trim();
    final prefs = await SharedPreferences.getInstance();
    if (_profileName.isEmpty) {
      await prefs.remove(_profileNameKey);
    } else {
      await prefs.setString(_profileNameKey, _profileName);
    }
    notifyListeners();
  }

  Future<void> completeAccountChoice() async {
    _accountChoiceComplete = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_accountChoiceKey, true);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    notifyListeners();
  }
}
