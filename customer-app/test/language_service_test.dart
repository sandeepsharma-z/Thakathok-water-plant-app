import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thakathok/services/language_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('switching languages never keeps a stale translated value', () async {
    final service = LanguageService.instance;

    await service.setLanguage(AppLanguage.hindi);
    final hindi = service.tr('My Bookings');
    expect(hindi, isNot('My Bookings'));

    await service.setLanguage(AppLanguage.english);
    expect(service.tr(hindi), 'My Bookings');

    await service.setLanguage(AppLanguage.marathi);
    expect(service.tr(hindi), isNot(hindi));
    expect(service.tr(hindi), isNot('My Bookings'));
  });

  test('manual ordering hold is available in all languages', () async {
    const message =
        'Your ordering is temporarily on hold. Please contact Mahalakshmi Water Plant on 8080739807 to clear dues.';
    final service = LanguageService.instance;

    await service.setLanguage(AppLanguage.hindi);
    expect(service.tr(message), isNot(message));
    await service.setLanguage(AppLanguage.marathi);
    expect(service.tr(message), isNot(message));
    await service.setLanguage(AppLanguage.english);
    expect(service.tr(message), message);
  });
}
