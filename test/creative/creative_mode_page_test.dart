import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/creative/creative_mode.dart';
import 'package:gtn_2/creative/creative_mode_page.dart';
import 'package:gtn_2/data/saves/save_data.dart';
import 'package:gtn_2/data/saves/save_storage.dart';

class _MemorySaveStorage extends SaveStorage {
  _MemorySaveStorage(this.value) : super(directory: Directory.systemTemp);

  SaveData? value;

  @override
  Future<SaveData?> load() async => value;

  @override
  Future<void> save(SaveData data) async {
    value = data;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Creative Mode persists a run and a correct guess without real disk I/O',
      (tester) async {
    final storage = _MemorySaveStorage(
      SaveData(secret: 42, attempts: 0, gamesWon: 0),
    );

    await tester.pumpWidget(
      MaterialApp(home: CreativeModePage(slot: 1, storage: storage)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enable Creative Mode'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start new run'));
    await tester.pumpAndSettle();
    expect(find.text('Run in progress'), findsOneWidget);

    final runningSave = storage.value!;
    expect(runningSave.creativeMode, isNotNull);
    final run = CreativeModeRuntime.resume(runningSave.creativeMode!);
    expect(run, isNotNull);

    await tester.enterText(find.byType(TextField).last, run!.target.toString());
    await tester.tap(find.text('Submit guess'));
    await tester.pumpAndSettle();

    expect(find.text('Run complete'), findsOneWidget);
    final completedRun =
        CreativeModeRuntime.resume(storage.value!.creativeMode!);
    expect(completedRun, isNotNull);
    expect(completedRun!.completed, isTrue);
    expect(completedRun.correctGuesses, 1);
    expect(completedRun.attemptsUsed, 1);
  });
}
