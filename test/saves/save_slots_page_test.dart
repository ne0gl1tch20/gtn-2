import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/data/saves/save_data.dart';
import 'package:gtn_2/saves/save_slots_page.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('unreadable save slots are not presented as empty slots', (
    tester,
  ) async {
    await tester.pumpWidget(
      M3EMaterialApp(
        data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
        fontFamily: 'Manrope',
        autoTheming: false,
        initialTheme: Brightness.dark,
        home: SaveSlotsPage(
          activeSlot: 1,
          onSelect: (_) async {},
          previewLoader: (slot) => slot == 1
              ? Future<SaveData?>.error(StateError('Preview failed'))
              : Future<SaveData?>.value(null),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Could not read save. Your data was not changed.'),
      findsOneWidget,
    );
    expect(find.text('Empty slot'), findsNWidgets(9));
    final firstSlotMenu = tester.widget<PopupMenuButton<String>>(
      find.byType(PopupMenuButton<String>).first,
    );
    expect(firstSlotMenu.enabled, isFalse);
  });
}
