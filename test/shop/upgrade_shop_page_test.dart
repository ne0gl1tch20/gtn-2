import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_engine.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/shop/upgrade_catalog.dart';
import 'package:gtn_2/shop/upgrade_shop_page.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(UpgradeCatalog.load);

  testWidgets('10x buys the largest affordable upgrade prefix', (tester) async {
    final initial = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(200),
    );
    var purchasedLevels = 0;

    await tester.pumpWidget(
      M3EMaterialApp(
        data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
        fontFamily: 'Manrope',
        autoTheming: false,
        initialTheme: Brightness.light,
        home: UpgradeShopPage(
          progression: initial,
          onPurchase: (definition, {required levels}) async {
            purchasedLevels = levels;
            return const ProgressionEngine().purchaseUpgradeLevels(
              initial,
              definition,
              levels: levels,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('10×'));
    await tester.pumpAndSettle();
    expect(find.text('Upgrade · 100 Money'), findsOneWidget);

    await tester.tap(find.text('Upgrade · 100 Money'));
    await tester.pumpAndSettle();
    expect(purchasedLevels, 1);
  });
}
