import 'package:flutter/material.dart';

class ExamCategorySpec {
  final String id;
  final String label;
  final int? questionWeight;
  final int? studyHours;
  final IconData icon;

  const ExamCategorySpec({
    required this.id,
    required this.label,
    this.questionWeight,
    this.studyHours,
    this.icon = Icons.menu_book_rounded,
  });
}

enum PassRuleType { correctCount, percentage, germanPenalty }

class CountryProfile {
  final String id;
  final String countryCode;
  final String regionCode;
  final String flag;
  final String displayName;
  final String nativeName;
  final String licenseLabel;
  final String primaryLocale;
  final List<String> supportedLocales;
  final int fullExamQuestions;
  final int examMinutes;
  final PassRuleType passRuleType;
  final int passCorrectCount;
  final int passPercentage;
  final int maxPenaltyPoints;
  final bool failOnTwoFivePointErrors;
  final List<ExamCategorySpec> categories;
  final String examAuthority;
  final String formatNote;
  final bool hasHazardPerception;
  final int hazardPassScore;
  final int hazardMaxScore;

  const CountryProfile({
    required this.id,
    required this.countryCode,
    this.regionCode = '',
    required this.flag,
    required this.displayName,
    required this.nativeName,
    required this.licenseLabel,
    required this.primaryLocale,
    required this.supportedLocales,
    required this.fullExamQuestions,
    required this.examMinutes,
    required this.passRuleType,
    this.passCorrectCount = 0,
    this.passPercentage = 0,
    this.maxPenaltyPoints = 0,
    this.failOnTwoFivePointErrors = false,
    required this.categories,
    required this.examAuthority,
    required this.formatNote,
    this.hasHazardPerception = false,
    this.hazardPassScore = 0,
    this.hazardMaxScore = 0,
  });

  ExamCategorySpec? categoryById(String value) {
    for (final category in categories) {
      if (category.id == value) return category;
    }
    return null;
  }

  String categoryLabel(String value) => categoryById(value)?.label ?? value;

  String localizedFormatNote(String locale) {
    final byCountry = _formatTranslations[id];
    return byCountry?[locale] ?? byCountry?['en'] ?? formatNote;
  }


  String localizedCategoryLabel(String value, String locale) {
    final key = '|';
    final map = _categoryTranslations[locale] ?? const <String, String>{};
    return map['$id$key$value'] ?? categoryLabel(value);
  }

  int get totalStudyHours => categories.fold<int>(0, (sum, item) => sum + (item.studyHours ?? 0));

  String get contentLanguageName => switch (primaryLocale) {
        'tr' => 'Türkçe',
        'nl' => 'Nederlands',
        'de' => 'Deutsch',
        'en' => 'English',
        _ => primaryLocale.toUpperCase(),
      };

  String get assetSuffix => switch (id) {
        'tr' => 'tr',
        'nl' => 'nl',
        'de' => 'de',
        'us_ca' => 'en_us_ca',
        'gb' => 'en_gb',
        _ => id,
      };

  bool passed({
    required int total,
    required int correct,
    required int penaltyPoints,
    required int wrongFivePointQuestions,
  }) {
    return switch (passRuleType) {
      PassRuleType.correctCount => correct >= passCorrectCount,
      PassRuleType.percentage => total > 0 && ((correct * 100) / total) >= passPercentage,
      PassRuleType.germanPenalty =>
        penaltyPoints <= maxPenaltyPoints &&
            (!failOnTwoFivePointErrors || wrongFivePointQuestions < 2),
    };
  }

  String localizedCountryName(String locale) {
    final map = _countryNameTranslations[id];
    return map?[locale] ?? map?['en'] ?? nativeName;
  }

  String localizedLicenseLabel(String locale) {
    final map = _licenseTranslations[id];
    return map?[locale] ?? map?['en'] ?? licenseLabel;
  }

  String passRuleSummary(String locale) {
    return switch (id) {
      'tr' => switch (locale) {
          'tr' => 'En az 70 puan (35/50)',
          'nl' => 'Minimaal 70% (35/50)',
          'de' => 'Mindestens 70% (35/50)',
          _ => 'At least 70% (35/50)',
        },
      'nl' => switch (locale) {
          'tr' => 'En az 44/50 doğru',
          'nl' => 'Minimaal 44 van 50 goed',
          'de' => 'Mindestens 44 von 50 richtig',
          _ => 'At least 44 of 50 correct',
        },
      'de' => switch (locale) {
          'tr' => 'En fazla 10 hata puanı; iki 5 puanlık yanlış = başarısız',
          'nl' => 'Max. 10 strafpunten; twee foute 5-puntsvragen = gezakt',
          'de' => 'Max. 10 Fehlerpunkte; zwei falsche 5-Punkte-Fragen = nicht bestanden',
          _ => 'Max 10 penalty points; two wrong 5-point questions = fail',
        },
      'us_ca' => switch (locale) {
          'tr' => 'TeoriX çalışma hedefi: 30/36 doğru',
          'nl' => 'TeoriX-oefendoel: 30/36 goed',
          'de' => 'TeoriX-Übungsziel: 30/36 richtig',
          _ => 'TeoriX practice target: 30/36 correct',
        },
      'gb' => switch (locale) {
          'tr' => 'Çoktan seçmeli: 43/50 • Tehlike algısı: 44/75',
          'nl' => 'Meerkeuze: 43/50 • Gevaarherkenning: 44/75',
          'de' => 'Multiple Choice: 43/50 • Gefahrenwahrnehmung: 44/75',
          _ => 'Multiple choice: 43/50 • Hazard perception: 44/75',
        },
      _ => '',
    };
  }
}

const _countryNameTranslations = <String, Map<String, String>>{
  'tr': {'tr':'Türkiye','nl':'Turkije','de':'Türkei','en':'Türkiye'},
  'nl': {'tr':'Hollanda','nl':'Nederland','de':'Niederlande','en':'Netherlands'},
  'de': {'tr':'Almanya','nl':'Duitsland','de':'Deutschland','en':'Germany'},
  'gb': {'tr':'Birleşik Krallık','nl':'Verenigd Koninkrijk','de':'Vereinigtes Königreich','en':'United Kingdom'},
  'us_ca': {'tr':'ABD • California','nl':'VS • Californië','de':'USA • Kalifornien','en':'USA • California'},
};

const _licenseTranslations = <String, Map<String, String>>{
  'tr': {'tr':'B Sınıfı Ehliyet','nl':'Rijbewijs categorie B','de':'Führerschein Klasse B','en':'Category B licence'},
  'nl': {'tr':'B Sınıfı Ehliyet','nl':'Rijbewijs B','de':'Führerschein Klasse B','en':'Category B licence'},
  'de': {'tr':'B Sınıfı Ehliyet','nl':'Rijbewijs klasse B','de':'Führerscheinklasse B','en':'Class B licence'},
  'gb': {'tr':'Otomobil Teori Sınavı','nl':'Autotheorie-examen','de':'Pkw-Theorieprüfung','en':'Car Theory Test'},
  'us_ca': {'tr':'California Class C','nl':'California Class C','de':'California Class C','en':'California Class C'},
};

const _formatTranslations = <String, Map<String, String>>{
  'tr': {
    'tr':'MEB e-Sınav pratiği • 50 soru • 45 dakika • en az 70 puan',
    'nl':'MEB e-examen oefening • 50 vragen • 45 minuten • minimaal 70%',
    'de':'MEB E-Prüfung Übung • 50 Fragen • 45 Minuten • mindestens 70%',
    'en':'MEB e-exam practice • 50 questions • 45 minutes • at least 70%',
  },
  'nl': {
    'tr':'Hollanda B teori pratiği • 50 değerlendirilen soru • 30 dakika • 44 doğru hedefi',
    'nl':'Nederlands theorie-examen B • 50 meetellende vragen • 30 minuten • minimaal 44 goed',
    'de':'Niederländische Theorie B • 50 gewertete Fragen • 30 Minuten • mindestens 44 richtig',
    'en':'Netherlands category B theory practice • 50 scored questions • 30 minutes • 44 correct target',
  },
  'de': {
    'tr':'Almanya B sınıfı teori pratiği • 30 soru • hata puanı sistemi',
    'nl':'Duitse klasse B-theorie • 30 vragen • strafpuntensysteem',
    'de':'Ersterwerb Klasse B • 30 Fragen • Fehlerpunktesystem',
    'en':'Germany Class B theory practice • 30 questions • penalty-point scoring',
  },
  'gb': {
    'tr':'Büyük Britanya otomobil teori pratiği • 50 çoktan seçmeli • 57 dakika • ayrıca tehlike algısı',
    'nl':'Groot-Brittannië autotheorie • 50 meerkeuzevragen • 57 minuten • aparte gevaarherkenning',
    'de':'Großbritannien Pkw-Theorie • 50 Multiple-Choice-Fragen • 57 Minuten • separate Gefahrenwahrnehmung',
    'en':'Great Britain car theory • 50 multiple-choice • 57 minutes • separate hazard perception',
  },
  'us_ca': {
    'tr':'California Class C • TeoriX çalışma simülasyonu • güncel DMV el kitabı konuları',
    'nl':'California Class C • TeoriX oefensimulatie • actuele DMV-handboekonderwerpen',
    'de':'California Class C • TeoriX-Übungssimulation • aktuelle DMV-Handbuchthemen',
    'en':'California Class C • TeoriX practice simulation • current DMV handbook topics',
  },
};

const _categoryTranslations = <String, Map<String, String>>{
  'tr': {
    'nl|Wetgeving':'Mevzuat','nl|Gebruik van de weg':'Yolun kullanımı','nl|Voorrang en voor laten gaan':'Geçiş hakkı ve öncelik','nl|Bijzondere wegen, weggedeelten, weggebruikers en manoeuvres':'Özel yollar ve manevralar','nl|Veilig rijden met het voertuig en reageren in noodsituaties':'Güvenli sürüş ve acil durumlar','nl|Verkeerstekens en aanwijzingen':'Trafik işaretleri ve talimatlar','nl|Verantwoorde verkeersdeelname en milieubewust rijden':'Sorumlu ve çevreci sürüş','nl|Voertuigkennis':'Araç bilgisi',
    'de|Gefahrenlehre':'Tehlike bilgisi','de|Verhalten im Straßenverkehr':'Trafikte davranış','de|Vorfahrt und Verkehrszeichen':'Geçiş hakkı ve işaretler','de|Umweltschutz':'Çevre koruma','de|Fahrzeugtechnik':'Araç tekniği','de|Geschwindigkeit und Abstand':'Hız ve takip mesafesi','de|Besondere Situationen':'Özel durumlar','de|Klasse B Zusatzstoff':'B sınıfı ek konular',
    'us_ca|Road Rules':'Yol kuralları','us_ca|Signs and Signals':'İşaretler ve sinyaller','us_ca|Safe Driving':'Güvenli sürüş','us_ca|Sharing the Road':'Yolu paylaşma','us_ca|Alcohol and Drugs':'Alkol ve maddeler','us_ca|Parking and Curb Rules':'Park ve kaldırım kuralları','us_ca|Collisions and Insurance':'Kazalar ve sigorta','us_ca|Driver Safety':'Sürücü güvenliği',
    'gb|Alertness':'Dikkat','gb|Attitude':'Tutum','gb|Safety and your vehicle':'Güvenlik ve araç','gb|Safety margins':'Güvenlik payları','gb|Hazard awareness':'Tehlike farkındalığı','gb|Vulnerable road users':'Savunmasız yol kullanıcıları','gb|Other types of vehicle':'Diğer araç türleri','gb|Vehicle handling':'Araç hakimiyeti','gb|Motorway rules':'Otoyol kuralları','gb|Rules of the road':'Yol kuralları','gb|Road and traffic signs':'Yol ve trafik işaretleri','gb|Documents':'Belgeler','gb|Incidents and first response':'Olaylar ve ilk müdahale',
  },
  'nl': {
    'tr|Trafik ve Cevre':'Verkeer en milieu','tr|Ilk Yardim':'Eerste hulp','tr|Arac Teknigi':'Voertuigtechniek','tr|Trafik Adabi':'Verkeersetiquette',
    'de|Gefahrenlehre':'Gevarenleer','de|Verhalten im Straßenverkehr':'Gedrag in het verkeer','de|Vorfahrt und Verkehrszeichen':'Voorrang en verkeerstekens','de|Umweltschutz':'Milieubescherming','de|Fahrzeugtechnik':'Voertuigtechniek','de|Geschwindigkeit und Abstand':'Snelheid en afstand','de|Besondere Situationen':'Bijzondere situaties','de|Klasse B Zusatzstoff':'Aanvullende stof klasse B',
    'us_ca|Road Rules':'Verkeersregels','us_ca|Signs and Signals':'Borden en signalen','us_ca|Safe Driving':'Veilig rijden','us_ca|Sharing the Road':'De weg delen','us_ca|Alcohol and Drugs':'Alcohol en drugs','us_ca|Parking and Curb Rules':'Parkeer- en stoeprandregels','us_ca|Collisions and Insurance':'Botsingen en verzekering','us_ca|Driver Safety':'Bestuurdersveiligheid',
    'gb|Alertness':'Oplettendheid','gb|Attitude':'Houding','gb|Safety and your vehicle':'Veiligheid en voertuig','gb|Safety margins':'Veiligheidsmarges','gb|Hazard awareness':'Gevaarherkenning','gb|Vulnerable road users':'Kwetsbare weggebruikers','gb|Other types of vehicle':'Andere voertuigen','gb|Vehicle handling':'Voertuigbeheersing','gb|Motorway rules':'Snelwegregels','gb|Rules of the road':'Verkeersregels','gb|Road and traffic signs':'Verkeerstekens','gb|Documents':'Documenten','gb|Incidents and first response':'Ongevallen en eerste reactie',
  },
  'de': {
    'tr|Trafik ve Cevre':'Verkehr und Umwelt','tr|Ilk Yardim':'Erste Hilfe','tr|Arac Teknigi':'Fahrzeugtechnik','tr|Trafik Adabi':'Verkehrsetikette',
    'nl|Wetgeving':'Gesetzgebung','nl|Gebruik van de weg':'Benutzung der Straße','nl|Voorrang en voor laten gaan':'Vorfahrt und Vorrang gewähren','nl|Bijzondere wegen, weggedeelten, weggebruikers en manoeuvres':'Besondere Straßen und Manöver','nl|Veilig rijden met het voertuig en reageren in noodsituaties':'Sicheres Fahren und Notfälle','nl|Verkeerstekens en aanwijzingen':'Verkehrszeichen und Anweisungen','nl|Verantwoorde verkeersdeelname en milieubewust rijden':'Verantwortungsvolles und umweltbewusstes Fahren','nl|Voertuigkennis':'Fahrzeugkenntnisse',
    'us_ca|Road Rules':'Verkehrsregeln','us_ca|Signs and Signals':'Zeichen und Signale','us_ca|Safe Driving':'Sicheres Fahren','us_ca|Sharing the Road':'Straße gemeinsam nutzen','us_ca|Alcohol and Drugs':'Alkohol und Drogen','us_ca|Parking and Curb Rules':'Park- und Bordsteinregeln','us_ca|Collisions and Insurance':'Unfälle und Versicherung','us_ca|Driver Safety':'Fahrersicherheit',
    'gb|Alertness':'Aufmerksamkeit','gb|Attitude':'Einstellung','gb|Safety and your vehicle':'Sicherheit und Fahrzeug','gb|Safety margins':'Sicherheitsabstände','gb|Hazard awareness':'Gefahrenwahrnehmung','gb|Vulnerable road users':'Gefährdete Verkehrsteilnehmer','gb|Other types of vehicle':'Andere Fahrzeugarten','gb|Vehicle handling':'Fahrzeugbeherrschung','gb|Motorway rules':'Autobahnregeln','gb|Rules of the road':'Verkehrsregeln','gb|Road and traffic signs':'Verkehrszeichen','gb|Documents':'Dokumente','gb|Incidents and first response':'Unfälle und Erstmaßnahmen',
  },
  'en': {
    'tr|Trafik ve Cevre':'Traffic & Environment','tr|Ilk Yardim':'First Aid','tr|Arac Teknigi':'Vehicle Technology','tr|Trafik Adabi':'Traffic Etiquette',
    'nl|Wetgeving':'Legislation','nl|Gebruik van de weg':'Use of the road','nl|Voorrang en voor laten gaan':'Right of way and yielding','nl|Bijzondere wegen, weggedeelten, weggebruikers en manoeuvres':'Special roads, road users and manoeuvres','nl|Veilig rijden met het voertuig en reageren in noodsituaties':'Safe driving and emergency response','nl|Verkeerstekens en aanwijzingen':'Traffic signs and directions','nl|Verantwoorde verkeersdeelname en milieubewust rijden':'Responsible and eco-conscious driving','nl|Voertuigkennis':'Vehicle knowledge',
    'de|Gefahrenlehre':'Hazard awareness','de|Verhalten im Straßenverkehr':'Road behaviour','de|Vorfahrt und Verkehrszeichen':'Right of way and traffic signs','de|Umweltschutz':'Environmental protection','de|Fahrzeugtechnik':'Vehicle technology','de|Geschwindigkeit und Abstand':'Speed and following distance','de|Besondere Situationen':'Special situations','de|Klasse B Zusatzstoff':'Class B supplementary topics',
    'us_ca|Road Rules':'Road Rules','us_ca|Signs and Signals':'Signs and Signals','us_ca|Safe Driving':'Safe Driving','us_ca|Sharing the Road':'Sharing the Road','us_ca|Alcohol and Drugs':'Alcohol and Drugs','us_ca|Parking and Curb Rules':'Parking and Curb Rules','us_ca|Collisions and Insurance':'Collisions and Insurance','us_ca|Driver Safety':'Driver Safety',
    'gb|Alertness':'Alertness','gb|Attitude':'Attitude','gb|Safety and your vehicle':'Safety and your vehicle','gb|Safety margins':'Safety margins','gb|Hazard awareness':'Hazard awareness','gb|Vulnerable road users':'Vulnerable road users','gb|Other types of vehicle':'Other types of vehicle','gb|Vehicle handling':'Vehicle handling','gb|Motorway rules':'Motorway rules','gb|Rules of the road':'Rules of the road','gb|Road and traffic signs':'Road and traffic signs','gb|Documents':'Documents','gb|Incidents and first response':'Incidents and first response',
  },
};

class CountryCatalog {
  static const turkey = CountryProfile(
    id: 'tr',
    countryCode: 'TR',
    flag: '🇹🇷',
    displayName: 'Türkiye',
    nativeName: 'Türkiye',
    licenseLabel: 'B Sınıfı Ehliyet',
    primaryLocale: 'tr',
    supportedLocales: ['tr', 'nl', 'de', 'en'],
    fullExamQuestions: 50,
    examMinutes: 45,
    passRuleType: PassRuleType.correctCount,
    passCorrectCount: 35,
    categories: [
      ExamCategorySpec(id: 'Trafik ve Cevre', label: 'Trafik ve Çevre', questionWeight: 23, studyHours: 16, icon: Icons.traffic_rounded),
      ExamCategorySpec(id: 'Ilk Yardim', label: 'İlk Yardım', questionWeight: 12, studyHours: 8, icon: Icons.medical_services_rounded),
      ExamCategorySpec(id: 'Arac Teknigi', label: 'Araç Tekniği', questionWeight: 9, studyHours: 6, icon: Icons.build_rounded),
      ExamCategorySpec(id: 'Trafik Adabi', label: 'Trafik Adabı', questionWeight: 6, studyHours: 4, icon: Icons.groups_rounded),
    ],
    examAuthority: 'MEB',
    formatNote: '50 soru • 45 dakika • 70 puan barajı',
  );

  static const netherlands = CountryProfile(
    id: 'nl',
    countryCode: 'NL',
    flag: '🇳🇱',
    displayName: 'Hollanda',
    nativeName: 'Nederland',
    licenseLabel: 'Rijbewijs B',
    primaryLocale: 'nl',
    supportedLocales: ['tr', 'nl', 'de', 'en'],
    fullExamQuestions: 50,
    examMinutes: 30,
    passRuleType: PassRuleType.correctCount,
    passCorrectCount: 44,
    categories: [
      ExamCategorySpec(id: 'Gebruik van de weg', label: 'Gebruik van de weg', icon: Icons.traffic_rounded),
      ExamCategorySpec(id: 'Voorrang en voor laten gaan', label: 'Voorrang en voor laten gaan', icon: Icons.add_road_rounded),
      ExamCategorySpec(id: 'Bijzondere wegen, weggedeelten, weggebruikers en manoeuvres', label: 'Bijzondere wegen & manoeuvres', icon: Icons.route_rounded),
      ExamCategorySpec(id: 'Veilig rijden met het voertuig en reageren in noodsituaties', label: 'Veilig rijden & noodsituaties', icon: Icons.health_and_safety_rounded),
      ExamCategorySpec(id: 'Verkeerstekens en aanwijzingen', label: 'Verkeerstekens & aanwijzingen', icon: Icons.signpost_rounded),
      ExamCategorySpec(id: 'Verantwoorde verkeersdeelname en milieubewust rijden', label: 'Verantwoord & milieubewust rijden', icon: Icons.eco_rounded),
      ExamCategorySpec(id: 'Wetgeving', label: 'Wetgeving', icon: Icons.gavel_rounded),
      ExamCategorySpec(id: 'Voertuigkennis', label: 'Voertuigkennis', icon: Icons.build_rounded),
    ],
    examAuthority: 'CBR',
    formatNote: 'TeoriX: 50 puanlanan soru • CBR: toplam 52 (2 test sorusu puana dahil değil) • 30 dk • 44/50',
  );

  static const germany = CountryProfile(
    id: 'de',
    countryCode: 'DE',
    flag: '🇩🇪',
    displayName: 'Almanya',
    nativeName: 'Deutschland',
    licenseLabel: 'Führerscheinklasse B',
    primaryLocale: 'de',
    supportedLocales: ['tr', 'nl', 'de', 'en'],
    fullExamQuestions: 30,
    examMinutes: 30,
    passRuleType: PassRuleType.germanPenalty,
    maxPenaltyPoints: 10,
    failOnTwoFivePointErrors: true,
    categories: [
      ExamCategorySpec(id: 'Gefahrenlehre', label: 'Gefahrenlehre', questionWeight: 3, icon: Icons.warning_rounded),
      ExamCategorySpec(id: 'Verhalten im Straßenverkehr', label: 'Verhalten im Straßenverkehr', questionWeight: 3, icon: Icons.traffic_rounded),
      ExamCategorySpec(id: 'Vorfahrt und Verkehrszeichen', label: 'Vorfahrt & Verkehrszeichen', questionWeight: 3, icon: Icons.signpost_rounded),
      ExamCategorySpec(id: 'Umweltschutz', label: 'Umweltschutz', questionWeight: 3, icon: Icons.eco_rounded),
      ExamCategorySpec(id: 'Fahrzeugtechnik', label: 'Fahrzeugtechnik', questionWeight: 3, icon: Icons.build_rounded),
      ExamCategorySpec(id: 'Geschwindigkeit und Abstand', label: 'Geschwindigkeit & Abstand', questionWeight: 3, icon: Icons.speed_rounded),
      ExamCategorySpec(id: 'Besondere Situationen', label: 'Besondere Situationen', questionWeight: 2, icon: Icons.route_rounded),
      ExamCategorySpec(id: 'Klasse B Zusatzstoff', label: 'Klasse-B-Zusatzstoff', questionWeight: 10, icon: Icons.directions_car_rounded),
    ],
    examAuthority: 'TÜV / DEKRA',
    formatNote: 'Ersterwerb Klasse B: 30 Fragen • max. 10 Fehlerpunkte • Übungstimer 30 Min.',
  );

  static const unitedKingdom = CountryProfile(
    id: 'gb',
    countryCode: 'GB',
    flag: '🇬🇧',
    displayName: 'Birleşik Krallık',
    nativeName: 'United Kingdom',
    licenseLabel: 'Car Theory Test',
    primaryLocale: 'en',
    supportedLocales: ['tr', 'nl', 'de', 'en'],
    fullExamQuestions: 50,
    examMinutes: 57,
    passRuleType: PassRuleType.correctCount,
    passCorrectCount: 43,
    hasHazardPerception: true,
    hazardPassScore: 44,
    hazardMaxScore: 75,
    categories: [
      ExamCategorySpec(id: 'Alertness', label: 'Alertness', icon: Icons.visibility_rounded),
      ExamCategorySpec(id: 'Attitude', label: 'Attitude', icon: Icons.psychology_rounded),
      ExamCategorySpec(id: 'Safety and your vehicle', label: 'Safety & vehicle', icon: Icons.build_rounded),
      ExamCategorySpec(id: 'Safety margins', label: 'Safety margins', icon: Icons.social_distance_rounded),
      ExamCategorySpec(id: 'Hazard awareness', label: 'Hazard awareness', icon: Icons.warning_rounded),
      ExamCategorySpec(id: 'Vulnerable road users', label: 'Vulnerable road users', icon: Icons.directions_bike_rounded),
      ExamCategorySpec(id: 'Other types of vehicle', label: 'Other vehicles', icon: Icons.local_shipping_rounded),
      ExamCategorySpec(id: 'Vehicle handling', label: 'Vehicle handling', icon: Icons.directions_car_rounded),
      ExamCategorySpec(id: 'Motorway rules', label: 'Motorway rules', icon: Icons.route_rounded),
      ExamCategorySpec(id: 'Rules of the road', label: 'Rules of the road', icon: Icons.traffic_rounded),
      ExamCategorySpec(id: 'Road and traffic signs', label: 'Road & traffic signs', icon: Icons.signpost_rounded),
      ExamCategorySpec(id: 'Documents', label: 'Documents', icon: Icons.description_rounded),
      ExamCategorySpec(id: 'Incidents and first response', label: 'Incidents & first response', icon: Icons.health_and_safety_rounded),
    ],
    examAuthority: 'DVSA',
    formatNote: 'Great Britain car theory • 50 multiple-choice / 57 min / 43 pass • separate hazard perception 44/75',
  );

  static const california = CountryProfile(
    id: 'us_ca',
    countryCode: 'US',
    regionCode: 'CA',
    flag: '🇺🇸',
    displayName: 'ABD • California',
    nativeName: 'United States • California',
    licenseLabel: 'California Class C',
    primaryLocale: 'en',
    supportedLocales: ['tr', 'nl', 'de', 'en'],
    fullExamQuestions: 36,
    examMinutes: 30,
    passRuleType: PassRuleType.correctCount,
    passCorrectCount: 30,
    categories: [
      ExamCategorySpec(id: 'Road Rules', label: 'Road Rules', icon: Icons.traffic_rounded),
      ExamCategorySpec(id: 'Signs and Signals', label: 'Signs & Signals', icon: Icons.signpost_rounded),
      ExamCategorySpec(id: 'Safe Driving', label: 'Safe Driving', icon: Icons.health_and_safety_rounded),
      ExamCategorySpec(id: 'Sharing the Road', label: 'Sharing the Road', icon: Icons.directions_bike_rounded),
      ExamCategorySpec(id: 'Alcohol and Drugs', label: 'Alcohol & Drugs', icon: Icons.no_drinks_rounded),
      ExamCategorySpec(id: 'Parking and Curb Rules', label: 'Parking & Curb Rules', icon: Icons.local_parking_rounded),
      ExamCategorySpec(id: 'Collisions and Insurance', label: 'Collisions & Insurance', icon: Icons.car_crash_rounded),
      ExamCategorySpec(id: 'Driver Safety', label: 'Driver Safety', icon: Icons.shield_rounded),
    ],
    examAuthority: 'California DMV',
    formatNote: 'California Class C • TeoriX practice simulation • current DMV handbook topics',
  );

  static const all = [turkey, netherlands, germany, unitedKingdom, california];

  static CountryProfile byId(String id) => all.firstWhere(
        (c) => c.id == id,
        orElse: () => turkey,
      );
}
