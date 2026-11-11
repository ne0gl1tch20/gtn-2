import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarrlyyui_flutter/jarrlyyui_flutter.dart';
import 'package:jarrlyyui_language/jarrlyyui_language.dart';

void main() {
  const source = '''
screen "settings.test" version 1 {
  column gap 8 {
    text key "settings.title" style "headline"
    input id "guess.input" bind "guess.value" type integer label "Guess"
    toggle id "music.toggle" bind "settings.music" label "Music"
    button id "save.button" key "settings.save" action "settings.save"
      enabled bind "settings.canSave"
  }
}
''';

  testWidgets('renders native controls and resolves host values/actions', (
    tester,
  ) async {
    final parsed = JuiParser().parse(source);
    expect(parsed.isSuccess, isTrue);
    final document = parsed.document!;
    final changes = <JuiInputChange>[];
    final actions = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JuiRenderer(
            document: document,
            values: const {
              'guess.value': 12,
              'settings.music': true,
              'settings.canSave': true,
            },
            resolveText: (key) => switch (key) {
              'settings.title' => 'Settings',
              'settings.save' => 'Save',
              _ => key,
            },
            onInputChanged: changes.add,
            onAction: actions.add,
          ),
        ),
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );

    await tester.enterText(find.byType(TextField), '42');
    expect(changes.single.binding, 'guess.value');
    expect(changes.single.value, 42);

    await tester.tap(find.text('Save'));
    expect(actions, ['settings.save']);
  });

  testWidgets('disabled host action cannot be dispatched', (tester) async {
    final parsed = JuiParser().parse('''
screen "test" version 1 {
  button id "save" key "save" action "settings.save"
    enabled bind "settings.canSave"
}
''');
    final actions = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JuiRenderer(
            document: parsed.document!,
            values: const {'settings.canSave': false},
            onAction: actions.add,
          ),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(actions, isEmpty);
  });
}
