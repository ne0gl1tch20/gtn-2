import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_engine.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/shop/permanent_shop_catalog.dart';
import 'package:gtn_2/shop/permanent_upgrade_shop_page.dart';
import 'package:gtn_2/shop/upgrade_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const engine = ProgressionEngine();

  setUpAll(() async {
    await UpgradeCatalog.load();
    await PermanentShopCatalog.load();
  });

  test('loads the exact GTN1 Prestige and Ultra shop items and prices', () {
    expect(
      PermanentShopCatalog.prestige.map((item) => item.id).toList(),
      ['prestige_auto_speed', 'prestige_luck_charm'],
    );
    expect(
      PermanentShopCatalog.prestige.map((item) => item.cost).toList(),
      [100, 250],
    );
    expect(
      PermanentShopCatalog.ultra.map((item) => item.id).toList(),
      [
        'ultra_universal_harmony',
        'ultra_infinite_multiplier',
        'ultra_flex_badge',
      ],
    );
    expect(
      PermanentShopCatalog.ultra.map((item) => item.cost).toList(),
      [500, 1000, 10000],
    );
  });

  testWidgets('Prestige hub exposes and purchases permanent shop items',
      (tester) async {
    var state = ProgressionState.initial.copyWith(
      prestige: BigNumber.fromInt(100),
    );
    await tester.pumpWidget(MaterialApp(
      home: PermanentUpgradeShopPage(
        progression: state,
        ultra: false,
        onPurchase: (_) async => state,
        onPurchaseShopItem: (item) async {
          state = engine.purchasePermanentShopItem(
            state,
            itemId: item.id,
            ultra: false,
          );
          return state;
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Prestige Shop'), findsOneWidget);
    expect(find.text('Quantum Auto-Guess'), findsOneWidget);
    final buy = find.text('Buy · 100 Prestige');
    await tester.ensureVisible(buy);
    await tester.tap(buy);
    await tester.pumpAndSettle();

    expect(state.prestige.toString(), '0');
    expect(state.prestigeShopPurchases, contains('prestige_auto_speed'));
    expect(find.text('Owned'), findsOneWidget);
  });

  testWidgets('Ultra hub exposes and purchases permanent Ultra shop items',
      (tester) async {
    var state = ProgressionState.initial.copyWith(
      ultra: BigNumber.fromInt(500),
    );
    await tester.pumpWidget(MaterialApp(
      home: PermanentUpgradeShopPage(
        progression: state,
        ultra: true,
        onPurchase: (_) async => state,
        onPurchaseShopItem: (item) async {
          state = engine.purchasePermanentShopItem(
            state,
            itemId: item.id,
            ultra: true,
          );
          return state;
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Ultra Shop'), findsOneWidget);
    expect(find.text('Universal Harmony'), findsOneWidget);
    final buy = find.text('Buy · 500 Ultra');
    await tester.ensureVisible(buy);
    await tester.tap(buy);
    await tester.pumpAndSettle();

    expect(state.ultra.toString(), '0');
    expect(state.ultraShopPurchases, contains('ultra_universal_harmony'));
    expect(find.text('Owned'), findsOneWidget);
  });
}
