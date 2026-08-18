class AppConfig {
  static const appName = 'TeoriX';
  static const developerName = 'Senshi Labs';

  // Supabase values are injected at build time. The app remains local-first
  // when they are empty, so development/testing does not depend on a backend.
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
  );

  // RevenueCat public SDK keys. Never place secret REST keys in the app.
  static const revenueCatAndroidKey = String.fromEnvironment('REVENUECAT_ANDROID_API_KEY', defaultValue: '');
  static const revenueCatIosKey = String.fromEnvironment('REVENUECAT_IOS_API_KEY', defaultValue: '');
  static const revenueCatWebKey = String.fromEnvironment('REVENUECAT_WEB_API_KEY', defaultValue: '');

  // RevenueCat entitlement identifiers.
  static const plusEntitlementId = 'plus';
  static const proEntitlementId = 'pro';

  // Store product identifiers. Prices are never hard-coded in production UI;
  // RevenueCat/Google Play/App Store return localized price strings.
  static const plusLifetimeProductId = 'teorix_plus_lifetime';
  static const proMonthlyProductId = 'teorix_pro_monthly';
  static const proYearlyProductId = 'teorix_pro_yearly';

  // Google official test ad units are used unless dart-defines replace them.
  static const bannerAdUnitId = String.fromEnvironment(
    'ADMOB_BANNER_ID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111',
  );
  static const interstitialAdUnitId = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  );
  static const rewardedAdUnitId = String.fromEnvironment(
    'ADMOB_REWARDED_ID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  );

  static const freeDailyExamLimit = 3;
  static const freeDailyTeacherLimit = 3;
  static const proDailyTeacherFairUse = 40;
  static const maxRewardedExamBonusesPerDay = 3;
  static const maxRewardedTeacherBonusesPerDay = 5;

  // Debug-only suggested launch prices. Production prices come from the store.
  static String debugSuggestedPlus(String countryId) => switch (countryId) {
        'tr' => '₺299,99',
        'gb' => '£9.99',
        'us_ca' => r'$11.99',
        _ => '€11.99',
      };

  static String debugSuggestedMonthly(String countryId) => switch (countryId) {
        'tr' => '₺129,99',
        'gb' => '£4.99',
        'us_ca' => r'$5.99',
        _ => '€5.49',
      };

  static String debugSuggestedYearly(String countryId) => switch (countryId) {
        'tr' => '₺899,99',
        'gb' => '£34.99',
        'us_ca' => r'$39.99',
        _ => '€39.99',
      };
}
