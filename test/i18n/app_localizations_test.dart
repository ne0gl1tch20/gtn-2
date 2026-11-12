import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/i18n/app_localizations.dart';

void main() {
  testWidgets(
    'locale overlays preserve English fallback and reject unknown locales',
    (tester) async {
      await AppLocalizations.load('fil_ph');

      expect(AppLocalizations.currentCode, 'fil_ph');
      expect(AppLocalizations.text('settings'), 'Mga Setting');
      expect(
        AppLocalizations.text('web_ui_review_your_game_statistics'),
        'Review your game statistics',
      );

      await AppLocalizations.load('unsupported_locale');

      expect(AppLocalizations.currentCode, 'en_us');
      expect(AppLocalizations.text('settings'), 'Settings');
    },
  );
}
