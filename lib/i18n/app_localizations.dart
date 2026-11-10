import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  static const supportedLocales = <(String, String)>[
    ('en_us', 'English (US)'),
    ('en_gb', 'English (UK)'),
    ('fil_ph', 'Filipino'),
    ('zh_cn', '简体中文'),
    ('zh_tw', '繁體中文'),
    ('ja', '日本語'),
    ('ko', '한국어'),
    ('es', 'Español'),
    ('fr', 'Français'),
    ('de', 'Deutsch'),
    ('it', 'Italiano'),
    ('pt_pt', 'Português (Portugal)'),
    ('pt_br', 'Português (Brasil)'),
    ('ru', 'Русский'),
    ('hi_in', 'हिन्दी'),
    ('id', 'Bahasa Indonesia'),
    ('th', 'ไทย'),
    ('vi', 'Tiếng Việt'),
    ('tr', 'Türkçe'),
    ('pl', 'Polski'),
    ('uk', 'Українська'),
    ('nl', 'Nederlands'),
    ('ar', 'العربية'),
  ];

  static final ValueNotifier<Map<String, dynamic>> catalog =
      ValueNotifier<Map<String, dynamic>>(<String, dynamic>{});
  static String currentCode = 'en_us';

  static Future<void> load(String code) async {
    final safeCode = supportedLocales.any((locale) => locale.$1 == code)
        ? code
        : 'en_us';
    final english = await _read('en_us');
    final overlay = safeCode == 'en_us'
        ? <String, dynamic>{}
        : await _read(safeCode);
    currentCode = safeCode;
    catalog.value = <String, dynamic>{...english, ...overlay};
  }

  static Future<Map<String, dynamic>> _read(String code) async {
    try {
      final source = await rootBundle.loadString('assets/locales/$code.json');
      final decoded = jsonDecode(source);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on Exception {
      return <String, dynamic>{};
    }
  }

  static String text(String key, [String? fallback]) {
    final value = catalog.value[key];
    return value is String && value.isNotEmpty ? value : fallback ?? key;
  }
}
