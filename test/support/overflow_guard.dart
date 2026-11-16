import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs a bounded UI action while collecting complete FlutterErrorDetails.
///
/// No exception types are filtered: layout, constraint, paint and lifecycle
/// errors all fail the UI gate. The diagnostic includes the relevant widget
/// and render-object details supplied by Flutter.
Future<void> runWithOverflowGuard(
  WidgetTester tester, {
  required String screen,
  required Size viewport,
  required Future<void> Function() action,
  Duration pumpDuration = const Duration(milliseconds: 120),
  int frames = 2,
}) async {
  if (frames < 1 || frames > 10) {
    throw ArgumentError.value(frames, 'frames', 'Must be between 1 and 10.');
  }

  final flutterErrors = <FlutterErrorDetails>[];
  final previousHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    flutterErrors.add(details);
    previousHandler?.call(details);
  };

  try {
    await action();
    for (var frame = 0; frame < frames; frame++) {
      await tester.pump(pumpDuration);
    }

    final exceptions = <String>[];
    for (var attempt = 0; attempt < 20; attempt++) {
      final exception = tester.takeException();
      if (exception == null) break;
      exceptions.add(
        exception is FlutterError
            ? exception.toStringDeep()
            : exception.toString(),
      );
    }

    if (flutterErrors.isNotEmpty || exceptions.isNotEmpty) {
      final details = flutterErrors
          .map((error) => error.toString())
          .join('\n--- additional FlutterErrorDetails ---\n');
      final pending = exceptions.join(
        '\n--- additional pending exception ---\n',
      );
      fail(
        '$screen raised ${flutterErrors.length} Flutter framework error(s) '
        'and ${exceptions.length} pending exception(s) at '
        '${viewport.width.toStringAsFixed(0)}x'
        '${viewport.height.toStringAsFixed(0)} logical pixels.\n'
        '$details\n$pending',
      );
    }
  } finally {
    FlutterError.onError = previousHandler;
  }
}
