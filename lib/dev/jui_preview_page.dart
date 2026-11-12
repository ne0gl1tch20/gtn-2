import 'package:material_ui/material_ui.dart';
import 'package:jarrlyyui_engine/jarrlyyui_engine.dart';

/// Developer-only preview of the APK-bundled JUI baseline.
///
/// This preview deliberately does not connect JUI actions to gameplay services.
/// Production host integration must register and validate each action separately.
class JuiPreviewPage extends StatefulWidget {
  const JuiPreviewPage({super.key});

  @override
  State<JuiPreviewPage> createState() => _JuiPreviewPageState();
}

class _JuiPreviewPageState extends State<JuiPreviewPage> {
  static const _screens = <String>{
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
  };

  final JuiAssetLoader _loader = JuiAssetLoader(basePath: 'assets/jui');
  String _screenId = 'home';
  late Future<JuiDocument> _document;

  @override
  void initState() {
    super.initState();
    _document = _loader.loadScreen(_screenId);
  }

  void _openScreen(String screenId) {
    if (!_screens.contains(screenId)) {
      _showNotice('Unknown JUI screen: $screenId');
      return;
    }
    setState(() {
      _screenId = screenId;
      _document = _loader.loadScreen(screenId);
    });
  }

  Future<void> _handleAction(
    String actionId,
    Map<String, Object?> arguments,
  ) async {
    if (actionId == 'navigation.open') {
      final route = arguments['route'];
      if (route is String) _openScreen(route);
      return;
    }
    if (actionId == 'navigation.back') {
      if (_screenId == 'home') {
        Navigator.of(context).maybePop();
      } else {
        _openScreen('home');
      }
      return;
    }

    // Game, save and progression actions intentionally remain disconnected.
    _showNotice('Preview only: $actionId');
  }

  Future<void> _handleInput(String inputId, String value) async {
    _showNotice('Preview input received: $inputId');
  }

  void _showNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('JUI Preview · $_screenId')),
      body: SafeArea(
        child: FutureBuilder<JuiDocument>(
          future: _document,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load bundled JUI screen: ${snapshot.error}'),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: JuiRenderer(
                document: snapshot.data!,
                state: const {
                  'player': {
                    'displayName': 'Preview Player',
                    'levelLabel': 'Level 1',
                  },
                },
                onAction: _handleAction,
                onInput: _handleInput,
              ),
            );
          },
        ),
      ),
    );
  }
}
