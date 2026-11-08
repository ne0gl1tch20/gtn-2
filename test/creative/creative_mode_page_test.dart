import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/creative/creative_mode_page.dart';
import 'package:gtn_2/core/creative/creative_mode.dart';
import 'package:gtn_2/data/saves/save_data.dart';
import 'package:gtn_2/data/saves/save_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');

  testWidgets('Creative Mode screen persists a run and a correct guess', (tester) async {
    final directory =
        await Directory.systemTemp.createTemp('gtn2-creative-mode-widget-');
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProvider, null);
      await directory.delete(recursive: true);
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      pathProvider,
      (call) async => directory.path,
    );

    final initialStorage = SaveStorage(directory: directory, slot: 1);
    await initialStorage.save(
      SaveData(secret: 42, attempts: 0, gamesWon: 0),
    );

    await tester.pumpWidget(
      const MaterialApp(home: CreativeModePage(slot: 1)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enable Creative Mode'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start new run'));
    await tester.pumpAndSettle();

    final runningSave = await initialStorage.load();
    expect(runningSave?.creativeMode, isNotNull);
    final run = CreativeModeRuntime.resume(runningSave!.creativeMode!);
    expect(run, isNotNull);

    await tester.enterText(find.byType(TextField).last, run!.target.toString());
    await tester.tap(find.text('Submit guess'));
    await tester.pumpAndSettle();

    final completedSave = await initialStorage.load();
    final completedRun =
        CreativeModeRuntime.resume(completedSave!.creativeMode!);
    expect(completedRun, isNotNull);
    expect(completedRun!.completed, isTrue);
    expect(completedRun.correctGuesses, 1);
    expect(completedRun.attemptsUsed, 1);
  });
}
