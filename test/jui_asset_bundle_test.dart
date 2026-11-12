import 'package:flutter_test/flutter_test.dart';
import 'package:jarrlyyui_engine/jarrlyyui_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all bundled JUI baseline screens load from Flutter assets', () async {
    final loader = JuiAssetLoader(basePath: 'assets/jui');
    const screens = [
      'home',
      'more',
      'settings',
      'save_slots',
      'traits',
      'talents',
      'mutators',
      'relics',
      'home_base',
      'results',
    ];

    for (final screen in screens) {
      final document = await loader.loadScreen(screen);
      expect(document.screenId, screen);
    }
  });
}
