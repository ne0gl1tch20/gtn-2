# jarrlyyui_engine Parser Conformance Corpus

**Status:** Design/test vectors only. No GTN2 runtime dependency.
**Specification:** `JARRLYYUI_LANGUAGE_V1.md`

This corpus turns the version 1 language rules into explicit parser expectations. When the pure-Dart parser is implemented, each vector should become a golden or rejection test. Source locations below are 1-based.

## 1. Valid documents

### V001 — minimal screen

~~~jui
screen "sample.empty" version 1 {
}
~~~

Expected: one `ScreenNode` with ID `sample.empty`, language version 1 and an empty child list.

### V002 — nested layout and localized text

~~~jui
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
~~~

Expected: preserve child order; parse numeric gaps as finite numbers; preserve symbolic localization and binding identifiers without resolving them in the parser.

### V003 — typed input and action

~~~jui
screen "sample.guess" version 1 {
  input id "guess.value" bind "guess.text" type integer
  button id "guess.submit" action "game.submitGuess" enabled bind "guess.canSubmit"
}
~~~

Expected: syntax tree contains an input node with writable binding `guess.text` and an action node with action identifier `game.submitGuess`. Host registration and type compatibility are semantic-validation responsibilities, not parser responsibilities.

### V004 — comments and escaped strings

~~~jui
// Root screen
screen "sample.labels" version 1 {
  text id "quote" label "A \"quoted\" label"
}
~~~

Expected: comments are ignored; the label decodes to `A "quoted" label`. Source spans still refer to the original encoded source.

## 2. Invalid documents

Each invalid vector must fail closed: no renderable partial AST is returned.

### E001 — unsupported language version

~~~jui
screen "sample.future" version 2 {
}
~~~

Expected diagnostic: `JUI005_UNSUPPORTED_VERSION` at line 1, column 32 (the version literal).

### E002 — unknown node

~~~jui
screen "sample.unknown" version 1 {
  marquee id "moving"
}
~~~

Expected diagnostic: `JUI010_UNKNOWN_NODE` at line 2, column 3.

### E003 — unclosed block

~~~jui
screen "sample.unclosed" version 1 {
  column {
    text key "home.title"
}
~~~

Expected diagnostic: `JUI002_UNCLOSED_BLOCK` at end of file, pointing to the opening block that remains unclosed.

### E004 — duplicate attribute

~~~jui
screen "sample.duplicate-attribute" version 1 {
  column gap 8 gap 12 {
  }
}
~~~

Expected diagnostic: `JUI011_DUPLICATE_ATTRIBUTE` at the second `gap` token.

### E005 — duplicate ID

~~~jui
screen "sample.duplicate-id" version 1 {
  text id "same" key "first"
  button id "same" action "sample.confirm"
}
~~~

Expected semantic diagnostic: `JUI020_DUPLICATE_ID` at the second ID declaration. Parsing may succeed, but semantic validation must reject the screen.

### E006 — wrong attribute type

~~~jui
screen "sample.bad-gap" version 1 {
  column gap "wide" {
  }
}
~~~

Expected diagnostic: `JUI001_UNEXPECTED_TOKEN` or the dedicated typed-value diagnostic selected by the final parser implementation. It must identify the string token where a number is required.

### E007 — forbidden expression

~~~jui
screen "sample.expression" version 1 {
  text bind "wallet.money" + "!"
}
~~~

Expected diagnostic: reject the `+` token. Version 1 has no expression or interpolation syntax.

### E008 — malformed string escape

~~~jui
screen "sample.escape" version 1 {
  text label "bad\qescape"
}
~~~

Expected diagnostic: reject the unsupported escape at the escaped character and do not silently drop it.

## 3. Semantic validation vectors

These documents are syntactically valid but require host/bundle metadata to validate.

| Vector | Source feature | Host/bundle setup | Expected result |
|---|---|---|---|
| S001 | `text bind "wallet.moneyLabel"` | Read-only string binding registered | Accept |
| S002 | `text bind "wallet.secret"` | Binding not registered | `JUI030_UNKNOWN_BINDING` |
| S003 | `input bind "guess.text"` | Writable string binding registered | Accept |
| S004 | `input bind "wallet.money"` | Only read-only numeric binding registered | `JUI032_BINDING_NOT_WRITABLE` |
| S005 | `button action "game.submitGuess"` | Action registered with matching contract | Accept |
| S006 | `button action "save.writeRaw"` | Action not in host allowlist | `JUI031_UNKNOWN_ACTION` |
| S007 | `image asset "images/logo.png"` | Asset exists and hash matches manifest | Accept |
| S008 | `image asset "../private/save.json"` | Path escapes bundle root | `JUI040_INVALID_ASSET` |
| S009 | `text key "missing.translation"` | Key absent from declared locale catalog | `JUI041_UNKNOWN_LOCALIZATION_KEY` |

## 4. Determinism and limits

The parser must produce the same AST and source spans for identical UTF-8 bytes on Android, Windows and desktop Dart test runners.

Initial implementation limits (subject to benchmark confirmation):

- Maximum source document: 256 KiB.
- Maximum nesting depth: 32.
- Maximum AST nodes per screen: 2,048.
- Maximum decoded string: 4,096 Unicode code points.
- Maximum identifier length: 128 ASCII characters.
- Maximum numeric layout value: finite and between 0 and 4,096.
- Maximum diagnostics returned per document: 100, with one terminal truncation diagnostic if exceeded.

Limit violations must be explicit diagnostics, not process crashes or silent truncation.

## 5. Implementation exit criteria

The parser implementation is ready for renderer integration only when:

1. Every valid vector produces its expected AST.
2. Every invalid syntax vector returns a stable diagnostic code and source location.
3. Every semantic vector is covered by validator tests using typed host descriptors and a bundle fixture.
4. Fuzzing malformed input never returns a renderable partial AST.
5. Repeated parsing is deterministic and does not depend on Flutter or platform APIs.
6. The language package can run `dart test` without importing Flutter.
