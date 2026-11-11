# jarrlyyui_language

A standalone, pure-Dart tokenizer, parser and validator for the version 1 `.jui` declarative UI language.

This package intentionally has no Flutter dependency. It is not imported by GTN2 and does not participate in gameplay or production rendering. The parser can be developed and tested independently while the GTN2 parity port continues.

## Example

~~~jui
screen "game.home" version 1 {
  column id "root" gap 16 {
    text key "home.title" style "headline"
    input id "guess.input" bind "guess.text" type integer
    button id "guess.submit" key "guess.submit" action "game.submitGuess"
  }
}
~~~

## Usage

~~~dart
import 'package:jarrlyyui_language/jarrlyyui_language.dart';

final result = JuiParser().parse(source);
if (!result.isSuccess) {
  for (final diagnostic in result.diagnostics) {
    print(diagnostic);
  }
  return;
}

final document = result.document!;
~~~

The parser returns an immutable syntax tree only when syntax and local semantic checks pass. It does not resolve host bindings, load assets, render Flutter widgets, execute expressions or dispatch actions.

## v1 boundaries

- Block-based syntax with no embedded expressions or code execution.
- Stable source spans and diagnostic codes.
- Bounded source length, nesting depth and node count.
- Unique IDs and node-specific attribute contracts.
- Host bindings and actions are validated later by the Flutter host.
- No WebView, JavaScript engine, filesystem access or network access.

Run the package tests with:

~~~sh
dart pub get
dart analyze
dart test
~~~

The package-specific workflow runs independently from GTN2's Android and Windows application builds.
