import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/design/expressive_widgets.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('shared application surfaces use Material 3 Expressive widgets',
      (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      M3EMaterialApp(
        title: 'GTN2 expressive test',
        data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
        fontFamily: 'Manrope',
        autoTheming: false,
        initialTheme: Brightness.light,
        home: Scaffold(
          appBar: const GtnExpressiveAppBar(titleText: 'Expressive'),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const GtnExpressiveCard(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('M3E surface'),
                ),
              ),
              M3EButton.filled(
                onPressed: () {},
                child: const Text('Continue'),
              ),
              GtnExpressiveTextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Guess'),
              ),
              const GtnExpressiveSwitchTile(
                title: Text('Expressive switch'),
                value: true,
                onChanged: null,
              ),
              GtnExpressiveChoiceChip(
                label: 'Selected',
                selected: true,
                onSelected: (_) {},
              ),
              GtnExpressiveDropdown<String>(
                initialValue: 'classic',
                items: const [
                  DropdownMenuItem(value: 'classic', child: Text('Classic')),
                  DropdownMenuItem(value: 'hard', child: Text('Hard')),
                ],
                onChanged: (_) {},
                decoration: const InputDecoration(labelText: 'Difficulty'),
              ),
              M3EButton.text(
                onPressed: () => GtnExpressiveDialog.show<void>(
                  context,
                  builder: (_) => const GtnExpressiveDialog(
                    title: Text('M3E dialog'),
                    content: Text('Dialog content'),
                  ),
                ),
                child: const Text('Show dialog'),
              ),
              const M3EProgressIndicator.linearWavy(value: 0.5),
              M3ESlider(value: 0.5, onChanged: (_) {}),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(M3EAppBar), findsOneWidget);
    expect(find.byType(M3ECard), findsOneWidget);
    expect(find.byType(M3EButton), findsOneWidget);
    expect(find.byType(M3ETextField), findsOneWidget);
    expect(find.byType(M3ESwitch), findsOneWidget);
    expect(find.byType(M3EChip), findsOneWidget);
    expect(find.byType(M3EDropdownMenu<String>), findsOneWidget);
    expect(find.byType(M3EProgressIndicator), findsOneWidget);
    expect(find.byType(M3ESlider), findsOneWidget);

    await tester.tap(find.text('Show dialog'));
    await tester.pumpAndSettle();
    expect(find.byType(M3EDialog), findsOneWidget);
    expect(find.text('M3E dialog'), findsOneWidget);
    controller.dispose();
  });
}
