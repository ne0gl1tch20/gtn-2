# jarrlyyui_engine Language v1 Draft

**Status:** Parser design draft. This document does not add a runtime dependency to GTN2.
**Companion:** [JARRLYYUI_ENGINE_ARCHITECTURE.md](JARRLYYUI_ENGINE_ARCHITECTURE.md)

## Design decision

Version 1 uses a small block-based declarative language. It is HTML-like in readability and hierarchy, but it is not HTML/XML, does not embed JavaScript, and does not evaluate expressions. The parser produces a typed immutable syntax tree; Flutter rendering is a separate package.

The language intentionally describes presentation and user intent only. It cannot implement gameplay rules, modify save data, or execute arbitrary code.

## 1. Example

~~~jui
screen "game.home" version 1 {
  column id "root" gap 16 {
    text key "home.title" style "headline"

    panel id "wallet" style "surface" {
      row gap 8 {
        text key "currency.money"
        text bind "wallet.moneyLabel" style "value"
      }
    }

    input id "guess.input" bind "guess.text" type "integer"
    button id "guess.submit" key "guess.submit"
      action "game.submitGuess"
      enabled bind "guess.canSubmit"
  }
}
~~~

All identifiers in `key`, `bind` and `action` are symbolic names registered by the Dart host. A script cannot create new host actions.

## 2. Lexical rules

- UTF-8 input; newline is significant only for diagnostics, not statement termination.
- Whitespace separates tokens. `//` starts a line comment.
- Strings use double quotes. Version 1 supports only escaped quote, backslash, newline and tab.
- Numbers are finite decimal literals. No NaN, infinity, arithmetic or interpolation.
- Identifiers begin with an ASCII letter or underscore and continue with letters, digits, underscore or hyphen.
- Braces define child scopes. A node ends at its closing brace, or at the end of its header for leaf nodes.
- No semicolon is required.
- Duplicate attributes on one node are invalid.

## 3. Grammar (EBNF)

~~~ebnf
document       = screen ;
screen         = "screen", string, "version", integer, block ;
block          = "{", { node }, "}" ;
node           = container | actionNode | leaf ;
container      = containerName, { attribute }, block ;
actionNode     = "button", { attribute }, [ block ] ;
leaf           = leafName, { attribute } ;
containerName  = "column" | "row" | "stack" | "scroll" | "panel"
               | "list" | "dialog" ;
leafName       = "text" | "icon" | "image" | "spacer" | "divider"
               | "input" | "toggle" ;
attribute      = idAttr | keyAttr | bindAttr | actionAttr
               | styleAttr | gapAttr | typeAttr | enabledAttr
               | labelAttr | assetAttr | semanticAttr ;
idAttr         = "id", string ;
keyAttr        = "key", string ;
bindAttr       = "bind", string ;
actionAttr     = "action", string ;
styleAttr      = "style", string ;
gapAttr        = "gap", number ;
typeAttr       = "type", identifier ;
enabledAttr    = "enabled", "bind", string ;
labelAttr      = "label", string ;
assetAttr      = "asset", string ;
semanticAttr   = "semantic", string ;
string         = quotedString ;
integer        = digit, { digit } ;
number         = [ "-" ], integer, [ ".", digit, { digit } ] ;
identifier     = identifierStart, { identifierPart } ;
quotedString   = '"', { stringCharacter | escape }, '"' ;
escape         = "\\\\", ( '"' | "\\\\" | "n" | "t" ) ;
digit          = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" ;
identifierStart = "A"…"Z" | "a"…"z" | "_" ;
identifierPart  = identifierStart | digit | "-" ;
~~~

`stringCharacter` excludes an unescaped quote, backslash and control characters. Escape sequences are decoded before semantic validation.

The grammar is followed by a semantic validation pass. Node-specific attributes are not interchangeable: for example, `asset` is valid for image/icon, `action` is valid for button, and `bind` on input must resolve to a writable input binding.

## 4. Version 1 node contract

| Node | Children | Required properties | Meaning |
|---|---|---|---|
| screen | nodes | stable screen ID in host route table | Root document |
| column / row | nodes | none | Native flex layout |
| stack | nodes | none | Layered layout |
| scroll | nodes | none | Bounded scroll container |
| panel | nodes | none | Theme-backed surface |
| list | nodes | typed item binding in host | Repeated native list |
| dialog | nodes | host-declared dialog ID | Native dialog surface |
| text | none | key or bind | Localized or bound text |
| icon | none | asset or registered icon token | Theme-aware icon |
| image | none | asset | Sandboxed bundle asset |
| spacer / divider | none | none | Layout primitives |
| input | none | id, writable bind, type | Typed user input |
| button | nodes optional | id, action | Allowlisted intent |
| toggle | none | id, writable bind | Boolean input |

Version 1 deliberately omits loops, conditionals, expressions, custom functions, arbitrary colors, arbitrary font loading, raw platform calls and network access.

## 5. Typed AST

The parser emits immutable nodes with source spans:

- `ScreenNode(id, languageVersion, children, span)`
- `ContainerNode(kind, id?, styleToken?, gap?, children, span)`
- `TextNode(id?, localizationKey?, valueBinding?, styleToken?, span)`
- `AssetNode(kind, id?, assetPath, semanticLabel?, span)`
- `InputNode(id, binding, inputType, labelKey?, span)`
- `ActionNode(kind, id, actionId, enabledBinding?, children, span)`
- `SpacerNode(id?, extent?, span)`

All nodes retain the source start/end offsets and line/column mapping. Rendering must not consume raw source strings or reinterpret syntax.

## 6. Semantic validation

Validation occurs after parsing and before rendering:

1. Exactly one root screen; supported language version.
2. Unique non-empty node IDs within a screen.
3. Node nesting and child types match the node contract.
4. Only known attributes are present and each has the expected value type.
5. Every localization key and asset reference exists in the declared bundle.
6. Every read binding exists in the host's read-only view model.
7. Every writable binding is explicitly registered as writable and has a compatible type.
8. Every action is allowlisted by the host and has the declared argument contract.
9. Layout values are finite and inside documented bounds.
10. Node count, nesting depth, string length and asset size stay within bundle limits.

Unknown required syntax fails closed with a source diagnostic. Optional extensions require an explicit schema capability; they are never silently ignored when doing so could change behavior.

## 7. Binding and action model

A host view model exposes typed descriptors, not arbitrary object reflection:

- `ReadBinding<T>`: stream of read-only values.
- `InputBinding<T>`: validated UI input update callback.
- `ActionDescriptor<A>`: named intent with typed argument schema.

The renderer may display a read binding, update an input binding, or dispatch an action descriptor. Dart revalidates all values and performs all game transactions. A script cannot write directly to a save or mutate a progression object.

## 8. Parser pipeline and errors

1. Enforce byte-size limit before decoding.
2. Tokenize while recording offsets and line/column.
3. Parse exactly one screen into a temporary AST.
4. Validate grammar and node structure.
5. Resolve host binding/action descriptors.
6. Validate assets and localization references against the bundle manifest.
7. Publish the validated AST to the renderer.

Diagnostics use stable codes such as `JUI001_UNEXPECTED_TOKEN`, `JUI002_UNCLOSED_BLOCK`, `JUI010_UNKNOWN_NODE`, `JUI020_DUPLICATE_ID`, `JUI030_UNKNOWN_BINDING`, `JUI031_UNKNOWN_ACTION` and `JUI040_INVALID_ASSET`. Each diagnostic includes file, line, column and a concise explanation.

No partially parsed AST is renderable.

## 9. Package boundaries

Recommended initial workspace:

- `jarrlyyui_language`: tokenizer, parser, AST, validator, formatter and diagnostics. Pure Dart; no Flutter dependency.
- `jarrlyyui_flutter`: AST-to-Flutter renderer, theme token adapters and typed binding bridge.
- `jarrlyyui_bundle`: manifest validation, asset lookup, hashes, staging and atomic activation.

The language package can be tested with Dart alone. Flutter widgets and platform APIs stay outside the parser.

## 10. Parser acceptance tests

- Golden source-to-AST tests for every node and attribute.
- Exact source spans for multiline and malformed documents.
- Unknown node/attribute, duplicate ID, duplicate attribute and invalid nesting rejection.
- Escaped strings, Unicode text and malformed UTF-8 handling.
- Binding/action type mismatch and unregistered identifier rejection.
- Limits for bytes, depth, node count, string size and numeric bounds.
- Deterministic parse output across Android and Windows runtimes.
- Fuzz tests proving malformed input never crashes the host or yields a renderable partial tree.

## 11. Decisions intentionally deferred

Do not add conditional syntax, iteration, animation DSL, theme authoring, script imports or remote custom components in v1. First prove parsing, validation and rendering of a small static screen and a small interactive settings screen. Complex and animated UI can remain registered Dart widgets.
