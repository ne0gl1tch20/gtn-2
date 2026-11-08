import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/arcade/arcade_catalog.dart';
import 'package:gtn_2/arcade/arcade_reward_rules.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads all seven canonical GTN1 minigames in source order', () async {
    final games = await ArcadeCatalog.load();
    expect(games.map((game) => game.id).toList(), ArcadeCatalog.expectedIds);
    expect(games.first.name, 'Quick Guess');
    expect(games.first.rewardMultiplier, 2);
    expect(games[5].name, 'Math Blitz');
    expect(games[6].name, 'Memory Grid');
  });

  test('rejects duplicate or incomplete Arcade catalogs', () async {
    const invalid = '''
      {"schemaVersion":1,"minigames":[
        {"id":"quick_guess","name":"Quick Guess","description":"x","rewardMultiplier":2},
        {"id":"quick_guess","name":"Duplicate","description":"x","rewardMultiplier":2}
      ]}
    ''';
    await expectLater(
      ArcadeCatalog.load(loadAsset: (_) async => invalid),
      throwsFormatException,
    );
  });

  test('Nebula rewards use GTN1 time and score bonuses with a ten cap', () {
    expect(ArcadeRewardRules.calculateNebulaReward(0, 0), 1);
    expect(ArcadeRewardRules.calculateNebulaReward(60, 5), 4);
    expect(ArcadeRewardRules.calculateNebulaReward(600, 100), 10);
    expect(ArcadeRewardRules.calculateNebulaReward(-10, -5), 1);
  });

  test('Money rewards use GTN1 score and time inputs with a one-million cap', () {
    expect(ArcadeRewardRules.calculateMoneyReward(0, 0), 0);
    expect(ArcadeRewardRules.calculateMoneyReward(60, 5), 3000);
    expect(ArcadeRewardRules.calculateMoneyReward(600, 10000), 1000000);
    expect(ArcadeRewardRules.calculateMoneyReward(-10, -5), 0);
  });

  test('reaction test rejects early and negative reaction times', () {
    expect(ArcadeRewardRules.isReactionTestRewardEligible(250), isTrue);
    expect(ArcadeRewardRules.isReactionTestRewardEligible(9999), isFalse);
    expect(ArcadeRewardRules.isReactionTestRewardEligible(-1), isFalse);
  });
}
