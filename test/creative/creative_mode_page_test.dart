import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/creative/creative_mode.dart';
import 'package:gtn_2/creative/creative_mode_page.dart';
import 'package:gtn_2/data/saves/save_data.dart';
import 'package:gtn_2/data/saves/save_storage.dart';

class _MemorySaveStorage extends SaveStorage {
  _MemorySaveStorage(this._save)
      : super(directory: Directory.systemTemp, slot: 1);

  SaveData? _save;

  @override
  Future<SaveData?> load() async => _save;

  @override
  Future<void> save(SaveData data) async {
    _save = data;
  }
}

Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    await tester.pump(const Duration(milliseconds: 25));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Creative Mode screen persists a run and a correct guess', (tester) async {
    final initialStorage =
        _MemorySaveStorage(SaveData(secret: 42, attempts: 0, gamesWon: 0));

    await tester.pumpWidget(
      MaterialApp(home: CreativeModePage(slot: 1, storage: initialStorage)),
    );
    await tester.pump();
    await pumpUntilFound(tester, find.text('Enable Creative Mode'));

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.tap(find.text('Start new run'));
    await tester.pump();
    await pumpUntilFound(tester, find.text('Run in progress'));

    final runningSave = await initialStorage.load();
    expect(runningSave?.creativeMode, isNotNull);
    final run = CreativeModeRuntime.resume(runningSave!.creativeMode!);
    expect(run, isNotNull);

    await tester.enterText(find.byType(TextField).last, run!.target.toString());
    await tester.tap(find.text('Submit guess'));
    await tester.pump();
    await pumpUntilFound(tester, find.text('Run complete'));

    final completedSave = await initialStorage.load();
    final completedRun =
        CreativeModeRuntime.resume(completedSave!.creativeMode!);
    expect(completedRun, isNotNull);
    expect(completedRun!.completed, isTrue);
    expect(completedRun.correctGuesses, 1);
    expect(completedRun.attemptsUsed, 1);
  });
}
