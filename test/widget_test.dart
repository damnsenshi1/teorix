import 'package:flutter_test/flutter_test.dart';
import 'package:teorix/core/app_config.dart';
import 'package:teorix/models/country_profile.dart';

void main() {
  test('app config has stable product ids', () {
    expect(AppConfig.plusLifetimeProductId, 'teorix_plus_lifetime');
    expect(AppConfig.proMonthlyProductId, 'teorix_pro_monthly');
    expect(AppConfig.proYearlyProductId, 'teorix_pro_yearly');
  });

  test('country packs expose all four supported study languages', () {
    expect(CountryCatalog.all.length, 5);
    for (final country in CountryCatalog.all) {
      expect(country.supportedLocales.toSet(), {'tr', 'nl', 'de', 'en'});
      for (final locale in country.supportedLocales) {
        expect(country.localizedCountryName(locale).trim(), isNotEmpty);
        expect(country.localizedLicenseLabel(locale).trim(), isNotEmpty);
        expect(country.passRuleSummary(locale).trim(), isNotEmpty);
      }
    }
  });
}
