import 'package:nsecure/core/localization/security_locale_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('locale controller persists Bahasa Indonesia and English', () async {
    final controller = SecurityLocaleController();

    await controller.setLanguageCode('id');
    expect(controller.locale?.languageCode, 'id');

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString(SecurityLocaleController.preferenceKey),
      'id',
    );

    await controller.setLanguageCode('en');
    expect(controller.locale?.languageCode, 'en');
    expect(
      preferences.getString(SecurityLocaleController.preferenceKey),
      'en',
    );

    controller.dispose();
  });

  test('locale controller ignores unsupported language codes', () async {
    final controller = SecurityLocaleController();

    await controller.setLanguageCode('id');
    await controller.setLanguageCode('fr');

    expect(controller.locale?.languageCode, 'id');
    controller.dispose();
  });

  test('locale normalization keeps id/en and falls back to English', () {
    expect(SecurityLocaleController.normalizeLanguageCode('id-ID'), 'id');
    expect(SecurityLocaleController.normalizeLanguageCode('en-US'), 'en');
    expect(SecurityLocaleController.normalizeLanguageCode('fr-FR'), 'en');
  });
}
