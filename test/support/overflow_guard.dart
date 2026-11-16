import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps bounded frames and fails with the full Flutter diagnostic for any
/// framework exception, including RenderFlex and viewport overflows.
///
/// No exception types are filtered: layout, constraint, paint and lifecycle
/// errors all fail the UI gate.
Future<void> expectNoLayoutException(
  WidgetTester tester, {
  required String screen,
  required Size viewport,
  Duration pumpDuration = const Duration(milliseconds: 120),
  int frames = 2,
}) async {
  if (frames < 1 || frames > 10) {
    throw ArgumentError.value(frames, 'frames', 'Must be between 1 and 10.');
  }

  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(pumpDuration);
  }

  final diagnostics = <String>[];
  for (var attempt = 0; attempt < 20; attempt++) {
    final exception = tester.takeException();
    if (exception == null) break;
    diagnostics.add(
      exception is FlutterError
          ? exception.toStringDeep()
          : exception.toString(),
    );
  }

  if (diagnostics.isNotEmpty) {
    fail(
      '$screen raised ${diagnostics.length} Flutter exception(s) at '
      '${viewport.width.toStringAsFixed(0)}x'
      '${viewport.height.toStringAsFixed(0)} logical pixels.\n'
      '${diagnostics.join('\n--- additional Flutter exception ---\n')}',
    );
  }
}
