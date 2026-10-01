import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityLocaleController extends ChangeNotifier {
  SecurityLocaleController();

  static const preferenceKey = 'security.locale.language_code';
  static const supportedLanguageCodes = <String>{'id', 'en'};

  Locale? _locale;

  Locale? get locale => _locale;

  String get effectiveLanguageCode {
    final explicit = _locale?.languageCode;
    if (explicit != null) return explicit;
    return normalizeLanguageCode(
      WidgetsBinding.instance.platformDispatcher.locale.languageCode,
    );
  }

  static String normalizeLanguageCode(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('_', '-');
    final primary = normalized.split('-').first;
    return supportedLanguageCodes.contains(primary) ? primary : 'en';
  }

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final languageCode = preferences.getString(preferenceKey);
      if (languageCode != null && supportedLanguageCodes.contains(languageCode)) {
        _locale = Locale(languageCode);
        notifyListeners();
      }
    } on Object {
      // Locale preference is presentation-only. Storage failure must never block
      // Security authentication or operational workflows.
    }
  }

  Future<void> setLanguageCode(String languageCode) async {
    final normalized = normalizeLanguageCode(languageCode);
    if (!supportedLanguageCodes.contains(
      languageCode.trim().toLowerCase().replaceAll('_', '-').split('-').first,
    )) {
      return;
    }
    final next = Locale(normalized);
    if (_locale?.languageCode == normalized) return;

    _locale = next;
    notifyListeners();

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(preferenceKey, normalized);
    } on Object {
      // Keep the selected locale for the current session even when preference
      // persistence is unavailable.
    }
  }
}

class SecurityLocaleScope extends InheritedNotifier<SecurityLocaleController> {
  const SecurityLocaleScope({
    required SecurityLocaleController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static SecurityLocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SecurityLocaleScope>();
    assert(scope != null, 'SecurityLocaleScope is missing above this context.');
    return scope!.notifier!;
  }
}
