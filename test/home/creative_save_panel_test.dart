import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/game/game_engine.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/home/creative_save_panel.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('Creative Save panel renders source sections and applies range', (
    tester,
  ) async {
    (int, int)? appliedRange;
    String? appliedKey;
    String? appliedValue;
    await tester.view.setPhysicalSize(const Size(900, 1200));
    await tester.view.setDevicePixelRatio(1);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      M3EMaterialApp(
        data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
        fontFamily: 'Manrope',
        autoTheming: false,
        initialTheme: Brightness.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: CreativeSavePanel(
              game: const GameState(
                secret: 42,
                attempts: 8,
                isComplete: false,
                minimum: 1,
                maximum: 100,
              ),
              progression: ProgressionState.initial,
              onRange: (minimum, maximum) async {
                appliedRange = (minimum, maximum);
                return true;
              },
              onValue: (key, value) async {
                appliedKey = key;
                appliedValue = value;
                return true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CREATIVE SAVE'), findsOneWidget);
    expect(find.text('Creative Tools'), findsOneWidget);
    expect(find.text('Game values'), findsOneWidget);
    expect(find.text('Upgrade levels'), findsOneWidget);
    expect(find.text('Prestige upgrades'), findsOneWidget);
    expect(find.text('Ultra upgrades'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Range minimum'), '20');
    await tester.enterText(find.widgetWithText(TextField, 'Range maximum'), '500');
    await tester.tap(find.text('Apply range'));
    await tester.pumpAndSettle();
    expect(appliedRange, (20, 500));
    expect(find.text('Creative Save updated.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Money'), '12.5K');
    await tester.tap(find.text('Set money'));
    await tester.pumpAndSettle();
    expect(appliedKey, 'money');
    expect(appliedValue, '12.5K');
  });
}
