import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_config.dart';
import 'entitlement_service.dart';

class AdService {
  AdService._();
  static final instance = AdService._();

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _adsSupported = false;
  bool _started = false;

  static const _lastInterstitialKey = 'ads_last_interstitial_ms';
  static const _eligibleTransitionKey = 'ads_eligible_transition_count';
  static const _minimumInterstitialGap = Duration(minutes: 20);

  bool get _nativeSupported => !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (!_nativeSupported || _started) return;
    _started = true;
    await MobileAds.instance.initialize();
    await _requestConsent();
    _adsSupported = await ConsentInformation.instance.canRequestAds();
    if (_adsSupported) {
      await loadInterstitial();
      await loadRewarded();
    }
  }

  Future<void> _requestConsent() async {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          ConsentForm.loadAndShowConsentFormIfRequired((_) {
            if (!completer.isCompleted) completer.complete();
          });
        } else if (!completer.isCompleted) {
          completer.complete();
        }
      },
      (_) { if (!completer.isCompleted) completer.complete(); },
    );
    await completer.future.timeout(const Duration(seconds: 8), onTimeout: () {});
  }

  Future<bool> privacyOptionsRequired() async {
    if (!_adsSupported) return false;
    final status = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  Future<void> showPrivacyOptions() async {
    if (!_nativeSupported) return;
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((_) { if (!completer.isCompleted) completer.complete(); });
    await completer.future.timeout(const Duration(seconds: 8), onTimeout: () {});
  }

  Future<BannerAd?> createBanner() async {
    if (!_adsSupported) return null;
    if (await EntitlementService.instance.currentAdFree()) return null;
    if (!await ConsentInformation.instance.canRequestAds()) return null;
    final ad = BannerAd(
      size: AdSize.banner,
      adUnitId: AppConfig.bannerAdUnitId,
      listener: BannerAdListener(onAdFailedToLoad: (ad, _) => ad.dispose()),
      request: const AdRequest(),
    );
    await ad.load();
    return ad;
  }

  Future<void> loadInterstitial() async {
    if (!_adsSupported || await EntitlementService.instance.currentAdFree()) return;
    if (!await ConsentInformation.instance.canRequestAds()) return;
    InterstitialAd.load(
      adUnitId: AppConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  // TeoriX deliberately avoids surprise full-screen ads. This should only be
  // called at a natural transition (for example, starting another full exam).
  // Even then, it is rate-limited: first eligible transition is skipped and
  // at least 20 minutes must pass between displays.
  Future<bool> maybeShowInterstitialAtNaturalTransition() async {
    if (!_adsSupported || await EntitlementService.instance.currentAdFree()) return false;
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_eligibleTransitionKey) ?? 0) + 1;
    await prefs.setInt(_eligibleTransitionKey, count);

    if (count < 2) return false;
    final lastMs = prefs.getInt(_lastInterstitialKey) ?? 0;
    final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
    if (DateTime.now().difference(last) < _minimumInterstitialGap) return false;

    final ad = _interstitial;
    if (ad == null) {
      await loadInterstitial();
      return false;
    }

    _interstitial = null;
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) async {
        ad.dispose();
        await prefs.setInt(_lastInterstitialKey, DateTime.now().millisecondsSinceEpoch);
        await prefs.setInt(_eligibleTransitionKey, 0);
        if (!completer.isCompleted) completer.complete(true);
        loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(false);
        loadInterstitial();
      },
    );
    ad.show();
    return completer.future;
  }

  Future<void> loadRewarded() async {
    if (!_adsSupported) return;
    if (!await ConsentInformation.instance.canRequestAds()) return;
    RewardedAd.load(
      adUnitId: AppConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  Future<bool> showRewarded() async {
    if (!_adsSupported) return false;
    final ad = _rewarded;
    if (ad == null) {
      await loadRewarded();
      return false;
    }
    _rewarded = null;
    final completer = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(earned);
        loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(false);
        loadRewarded();
      },
    );
    ad.show(onUserEarnedReward: (_, __) => earned = true);
    return completer.future;
  }
}
