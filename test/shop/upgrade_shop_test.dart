import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_engine.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/shop/upgrade_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const engine = ProgressionEngine();

  setUpAll(UpgradeCatalog.load);

  test('canonical catalog contains eleven unique source upgrade definitions', () {
    final ids = UpgradeCatalog.all.map((item) => item.definition.id).toSet();
    expect(ids.length, 11);
    expect(UpgradeCatalog.all.length, 11);
  });

  test('only the source upgrades with wired effects are offered for purchase', () {
    expect(
      UpgradeCatalog.availableForGameplay.map((item) => item.definition.id).toSet(),
      {'reward_multiplier', 'better_range'},
    );
  });

  test('reward multiplier purchase spends the exact canonical cost', () {
    final upgrade = UpgradeCatalog.byId('reward_multiplier').definition;
    final state = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(100),
    );
    final result = engine.purchaseUpgrade(state, upgrade);
    expect(result.money.toString(), '0');
    expect(result.upgrades['reward_multiplier'], 1);
  });

  test('better range purchase respects its source cap and exact cost', () {
    final upgrade = UpgradeCatalog.byId('better_range').definition;
    final state = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(500),
    );
    final result = engine.purchaseUpgrade(state, upgrade);
    expect(result.money.toString(), '0');
    expect(result.upgrades['better_range'], 1);
  });

  test('unaffordable canonical upgrade purchase leaves state unchanged', () {
    final upgrade = UpgradeCatalog.byId('reward_multiplier').definition;
    final state = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(99),
    );
    expect(engine.purchaseUpgrade(state, upgrade), same(state));
  });
}
