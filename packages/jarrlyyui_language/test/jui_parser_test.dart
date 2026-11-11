import 'package:jarrlyyui_language/jarrlyyui_language.dart';
import 'package:test/test.dart';

void main() {
  group('JuiParser', () {
    final parser = JuiParser();

    test('parses a minimal screen', () {
      final result = parser.parse('''
screen "sample.empty" version 1 {
}
''');
      expect(result.isSuccess, isTrue);
      expect(result.document!.id, 'sample.empty');
      expect(result.document!.children, isEmpty);
    });

    test('parses nested layout and preserves child order', () {
      final result = parser.parse('''
screen "sample.home" version 1 {
  column id "root" gap 12 {
    text id "title" key "home.title" style "headline"
    panel id "wallet" style "surface" {
      row gap 8 {
        text key "currency.money"
        text bind "wallet.moneyLabel" style "value"
      }
    }
  }
}
''');
      expect(result.isSuccess, isTrue, reason: result.diagnostics.toString());
      final root = result.document!.children.single;
      expect(root.kind, 'column');
      expect(root.children.map((node) => node.kind), ['text', 'panel']);
      expect(root.children.last.children.single.kind, 'row');
    });

    test('parses typed input and action bindings', () {
      final result = parser.parse('''
screen "sample.guess" version 1 {
  input id "guess.value" bind "guess.text" type integer
  button id "guess.submit" action "game.submitGuess" enabled bind "guess.canSubmit"
}
''');
      expect(result.isSuccess, isTrue, reason: result.diagnostics.toString());
      expect(result.document!.children.first.binding, 'guess.text');
      expect(result.document!.children.last.action, 'game.submitGuess');
      expect(
        result.document!.children.last.attributes['enabled'],
        'guess.canSubmit',
      );
    });

    test('supports comments and escaped strings', () {
      final result = parser.parse(r'''
// root screen
screen "sample.labels" version 1 {
  text id "quote" key "sample.quote" label "A \"quoted\" label"
}
''');
      expect(result.isSuccess, isTrue, reason: result.diagnostics.toString());
      expect(
        result.document!.children.single.attributes['label'],
        'A "quoted" label',
      );
    });

    test('rejects unsupported versions with a stable diagnostic', () {
      final result = parser.parse('''
screen "sample.future" version 2 {
}
''');
      expect(result.document, isNull);
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('JUI005_UNSUPPORTED_VERSION'),
      );
      expect(result.diagnostics.first.line, 1);
      expect(result.diagnostics.first.column, 32);
    });

    test('rejects unknown nodes', () {
      final result = parser.parse('''
screen "sample.unknown" version 1 {
  marquee id "moving"
}
''');
      expect(result.document, isNull);
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('JUI010_UNKNOWN_NODE'),
      );
    });

    test('rejects duplicate attributes', () {
      final result = parser.parse('''
screen "sample.duplicate-attribute" version 1 {
  column gap 8 gap 12 {
  }
}
''');
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('JUI011_DUPLICATE_ATTRIBUTE'),
      );
    });

    test('rejects duplicate IDs across nested nodes', () {
      final result = parser.parse('''
screen "sample.duplicate-id" version 1 {
  column id "same" {
    text id "same" key "title"
  }
}
''');
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('JUI020_DUPLICATE_ID'),
      );
    });

    test('rejects wrong property types and expressions', () {
      final badGap = parser.parse('''
screen "sample.bad-gap" version 1 {
  column gap "wide" {
  }
}
''');
      expect(badGap.document, isNull);
      expect(
        badGap.diagnostics.map((diagnostic) => diagnostic.code),
        contains('JUI001_UNEXPECTED_TOKEN'),
      );

      final expression = parser.parse('''
screen "sample.expression" version 1 {
  text key "title" + "!"
}
''');
      expect(expression.document, isNull);
      expect(
        expression.diagnostics.map((diagnostic) => diagnostic.code),
        contains('JUI001_UNEXPECTED_TOKEN'),
      );
    });

    test('rejects malformed string escapes', () {
      final result = parser.parse(r'''
screen "sample.escape" version 1 {
  text key "title" label "bad\qescape"
}
''');
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('JUI008_INVALID_ESCAPE'),
      );
    });

    test('does not return a partial document after any error', () {
      final result = parser.parse('''
screen "sample.partial" version 1 {
  text id "bad" label "missing key or bind"
}
''');
      expect(result.document, isNull);
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('JUI021_TEXT_SOURCE_REQUIRED'),
      );
    });

    test('enforces source size and nesting limits', () {
      final tooLarge = JuiParser(maxDocumentCharacters: 10).parse(
        'screen "sample" version 1 {}',
      );
      expect(
        tooLarge.diagnostics.map((diagnostic) => diagnostic.code),
        contains('JUI050_DOCUMENT_TOO_LARGE'),
      );

      final tooDeep = JuiParser(maxDepth: 1).parse('''
screen "sample.deep" version 1 {
  column {
    row {
      text key "title"
    }
  }
}
''');
      expect(
        tooDeep.diagnostics.map((diagnostic) => diagnostic.code),
        contains('JUI051_MAX_DEPTH'),
      );
    });
  });
}
