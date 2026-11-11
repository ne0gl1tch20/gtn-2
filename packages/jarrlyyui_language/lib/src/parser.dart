import 'ast.dart';
import 'diagnostic.dart';

class JuiParseResult {
  JuiParseResult({
    required this.document,
    required List<JuiDiagnostic> diagnostics,
  }) : diagnostics = List<JuiDiagnostic>.unmodifiable(diagnostics);

  final JuiDocument? document;
  final List<JuiDiagnostic> diagnostics;

  bool get isSuccess => document != null && diagnostics.isEmpty;
}

enum _TokenKind { identifier, string, number, leftBrace, rightBrace, eof }

class _Token {
  const _Token({
    required this.kind,
    required this.lexeme,
    required this.value,
    required this.span,
  });

  final _TokenKind kind;
  final String lexeme;
  final Object? value;
  final JuiSourceSpan span;
}

class _Lexer {
  _Lexer(this.source);

  final String source;
  final diagnostics = <JuiDiagnostic>[];
  final tokens = <_Token>[];
  int _offset = 0;
  int _line = 1;
  int _column = 1;

  List<_Token> scan() {
    while (!_atEnd) {
      final start = _offset;
      final line = _line;
      final column = _column;
      final char = _peek();

      if (_isWhitespace(char)) {
        _advance();
      } else if (char == '/' && _peekNext() == '/') {
        while (!_atEnd && _peek() != '\n') {
          _advance();
        }
      } else if (char == '{') {
        _advance();
        _add(_TokenKind.leftBrace, '{', null, start, line, column);
      } else if (char == '}') {
        _advance();
        _add(_TokenKind.rightBrace, '}', null, start, line, column);
      } else if (char == '"') {
        _scanString(start, line, column);
      } else if (_isDigit(char) || (char == '-' && _isDigit(_peekNext()))) {
        _scanNumber(start, line, column);
      } else if (_isIdentifierStart(char)) {
        _scanIdentifier(start, line, column);
      } else {
        _advance();
        diagnostics.add(
          JuiDiagnostic(
            code: 'JUI001_UNEXPECTED_TOKEN',
            message: 'Unexpected character "$char".',
            span: JuiSourceSpan(
              offset: start,
              length: 1,
              line: line,
              column: column,
            ),
          ),
        );
      }
    }

    tokens.add(
      _Token(
        kind: _TokenKind.eof,
        lexeme: '',
        value: null,
        span: JuiSourceSpan(
          offset: _offset,
          length: 0,
          line: _line,
          column: _column,
        ),
      ),
    );
    return tokens;
  }

  void _scanString(int start, int line, int column) {
    _advance();
    final buffer = StringBuffer();
    var closed = false;
    while (!_atEnd) {
      final char = _peek();
      if (char == '"') {
        _advance();
        closed = true;
        break;
      }
      if (char == '\n') {
        diagnostics.add(
          JuiDiagnostic(
            code: 'JUI003_UNTERMINATED_STRING',
            message: 'Strings cannot contain an unescaped newline.',
            span: JuiSourceSpan(
              offset: start,
              length: _offset - start,
              line: line,
              column: column,
            ),
          ),
        );
        break;
      }
      if (char == r'\') {
        final escapeOffset = _offset;
        final escapeLine = _line;
        final escapeColumn = _column;
        _advance();
        if (_atEnd) break;
        final escaped = _peek();
        _advance();
        if (escaped == '"') {
          buffer.write('"');
        } else if (escaped == r'\') {
          buffer.write(r'\');
        } else if (escaped == 'n') {
          buffer.write('\n');
        } else if (escaped == 't') {
          buffer.write('\t');
        } else {
          diagnostics.add(
            JuiDiagnostic(
              code: 'JUI008_INVALID_ESCAPE',
              message: 'Unsupported string escape "$escaped".',
              span: JuiSourceSpan(
                offset: escapeOffset,
                length: 2,
                line: escapeLine,
                column: escapeColumn,
              ),
            ),
          );
        }
        continue;
      }
      buffer.write(char);
      _advance();
    }
    if (!closed) {
      diagnostics.add(
        JuiDiagnostic(
          code: 'JUI003_UNTERMINATED_STRING',
          message: 'String literal was not closed.',
          span: JuiSourceSpan(
            offset: start,
            length: _offset - start,
            line: line,
            column: column,
          ),
        ),
      );
    }
    _add(
      _TokenKind.string,
      source.substring(start, _offset),
      buffer.toString(),
      start,
      line,
      column,
    );
  }

  void _scanNumber(int start, int line, int column) {
    if (_peek() == '-') _advance();
    while (_isDigit(_peek())) {
      _advance();
    }
    if (_peek() == '.' && _isDigit(_peekNext())) {
      _advance();
      while (_isDigit(_peek())) {
        _advance();
      }
    }
    final lexeme = source.substring(start, _offset);
    final value = num.tryParse(lexeme);
    if (value == null || !value.isFinite) {
      diagnostics.add(
        JuiDiagnostic(
          code: 'JUI001_UNEXPECTED_TOKEN',
          message: 'Expected a finite numeric literal.',
          span: JuiSourceSpan(
            offset: start,
            length: _offset - start,
            line: line,
            column: column,
          ),
        ),
      );
      return;
    }
    _add(_TokenKind.number, lexeme, value, start, line, column);
  }

  void _scanIdentifier(int start, int line, int column) {
    _advance();
    while (_isIdentifierPart(_peek())) {
      _advance();
    }
    final lexeme = source.substring(start, _offset);
    _add(_TokenKind.identifier, lexeme, lexeme, start, line, column);
  }

  void _add(
    _TokenKind kind,
    String lexeme,
    Object? value,
    int start,
    int line,
    int column,
  ) {
    tokens.add(
      _Token(
        kind: kind,
        lexeme: lexeme,
        value: value,
        span: JuiSourceSpan(
          offset: start,
          length: _offset - start,
          line: line,
          column: column,
        ),
      ),
    );
  }

  bool get _atEnd => _offset >= source.length;
  String _peek() => _atEnd ? '\u0000' : source[_offset];
  String _peekNext() =>
      _offset + 1 >= source.length ? '\u0000' : source[_offset + 1];

  String _advance() {
    final char = source[_offset++];
    if (char == '\n') {
      _line++;
      _column = 1;
    } else {
      _column++;
    }
    return char;
  }

  bool _isWhitespace(String char) =>
      char == ' ' || char == '\r' || char == '\t' || char == '\n';

  bool _isDigit(String char) =>
      char.isNotEmpty && char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;

  bool _isIdentifierStart(String char) =>
      char == '_' ||
      (char.isNotEmpty &&
          ((char.codeUnitAt(0) >= 65 && char.codeUnitAt(0) <= 90) ||
              (char.codeUnitAt(0) >= 97 && char.codeUnitAt(0) <= 122)));

  bool _isIdentifierPart(String char) =>
      _isIdentifierStart(char) || _isDigit(char) || char == '-';
}

class JuiParser {
  JuiParser({
    this.maxDocumentCharacters = 262144,
    this.maxDepth = 32,
    this.maxNodes = 2048,
  });

  final int maxDocumentCharacters;
  final int maxDepth;
  final int maxNodes;

  static const _containers = <String>{
    'column',
    'row',
    'stack',
    'scroll',
    'panel',
    'list',
    'dialog',
  };
  static const _leaves = <String>{
    'text',
    'icon',
    'image',
    'spacer',
    'divider',
    'input',
    'button',
    'toggle',
  };
  static const _attributeNames = <String>{
    'id',
    'key',
    'bind',
    'action',
    'style',
    'gap',
    'type',
    'enabled',
    'label',
    'asset',
    'semantic',
  };

  late List<_Token> _tokens;
  final _diagnostics = <JuiDiagnostic>[];
  int _current = 0;
  int _nodeCount = 0;

  JuiParseResult parse(String source) {
    _diagnostics.clear();
    _current = 0;
    _nodeCount = 0;
    if (source.length > maxDocumentCharacters) {
      return JuiParseResult(
        document: null,
        diagnostics: [
          JuiDiagnostic(
            code: 'JUI050_DOCUMENT_TOO_LARGE',
            message: 'Document exceeds the configured size limit.',
            span: const JuiSourceSpan(
              offset: 0,
              length: 0,
              line: 1,
              column: 1,
            ),
          ),
        ],
      );
    }

    final lexer = _Lexer(source);
    _tokens = lexer.scan();
    _diagnostics.addAll(lexer.diagnostics);
    if (_diagnostics.isNotEmpty) return _failure();

    final start = _currentToken.span;
    if (!_matchIdentifier('screen')) {
      _error(
        'JUI001_UNEXPECTED_TOKEN',
        'Document must start with "screen".',
        _currentToken.span,
      );
      return _failure();
    }
    final screenId = _consumeString('Expected a quoted screen ID.');
    _consumeIdentifier('version', 'Expected "version" after screen ID.');
    final versionToken = _consumeNumber('Expected an integer language version.');
    final versionValue = versionToken?.value;
    final version = versionValue is int ? versionValue : -1;
    if (version != 1) {
      _error(
        'JUI005_UNSUPPORTED_VERSION',
        'Only language version 1 is supported.',
        versionToken?.span ?? _currentToken.span,
      );
    }
    if (!_match(_TokenKind.leftBrace)) {
      _error(
        'JUI001_UNEXPECTED_TOKEN',
        'Expected "{" after screen header.',
        _currentToken.span,
      );
      return _failure();
    }

    final children = _parseChildren(depth: 0);
    final end = _currentToken.span;
    if (!_match(_TokenKind.rightBrace)) {
      _error(
        'JUI002_UNCLOSED_BLOCK',
        'Screen block was not closed.',
        start,
      );
    }
    if (!_match(_TokenKind.eof)) {
      _error(
        'JUI001_UNEXPECTED_TOKEN',
        'Unexpected content after the screen block.',
        _currentToken.span,
      );
    }

    if (_diagnostics.isNotEmpty || screenId == null) return _failure();
    final document = JuiDocument(
      id: screenId,
      version: version,
      children: children,
      span: JuiSourceSpan(
        offset: start.offset,
        length: end.offset - start.offset,
        line: start.line,
        column: start.column,
      ),
    );
    _validateDocument(document);
    return _diagnostics.isEmpty
        ? JuiParseResult(document: document, diagnostics: _diagnostics)
        : _failure();
  }

  List<JuiNode> _parseChildren({required int depth}) {
    final children = <JuiNode>[];
    while (!_check(_TokenKind.rightBrace) && !_check(_TokenKind.eof)) {
      final before = _current;
      final node = _parseNode(depth: depth + 1);
      if (node != null) children.add(node);
      if (_current == before) _advance();
    }
    return children;
  }

  JuiNode? _parseNode({required int depth}) {
    final token = _currentToken;
    if (token.kind != _TokenKind.identifier) {
      _error(
        'JUI001_UNEXPECTED_TOKEN',
        'Expected a UI node name.',
        token.span,
      );
      _advance();
      return null;
    }
    final kind = token.lexeme;
    if (!_containers.contains(kind) && !_leaves.contains(kind)) {
      _error('JUI010_UNKNOWN_NODE', 'Unknown node "$kind".', token.span);
      _advance();
      return null;
    }
    if (depth > maxDepth) {
      _error(
        'JUI051_MAX_DEPTH',
        'Document exceeds the maximum nesting depth.',
        token.span,
      );
      _advance();
      return null;
    }
    _advance();
    _nodeCount++;
    if (_nodeCount > maxNodes) {
      _error(
        'JUI052_MAX_NODES',
        'Document exceeds the maximum node count.',
        token.span,
      );
      return null;
    }

    final attributes = <String, Object>{};
    while (_currentToken.kind == _TokenKind.identifier &&
        _attributeNames.contains(_currentToken.lexeme)) {
      final attributeToken = _advance();
      final attribute = attributeToken.lexeme;
      if (attributes.containsKey(attribute)) {
        _error(
          'JUI011_DUPLICATE_ATTRIBUTE',
          'Attribute "$attribute" is declared more than once.',
          attributeToken.span,
        );
      }
      final value = _parseAttributeValue(attribute);
      if (value != null) attributes[attribute] = value;
    }

    final children = <JuiNode>[];
    if (_containers.contains(kind)) {
      if (!_match(_TokenKind.leftBrace)) {
        _error(
          'JUI001_UNEXPECTED_TOKEN',
          'Container "$kind" must open a child block.',
          _currentToken.span,
        );
      } else {
        children.addAll(_parseChildren(depth: depth));
        if (!_match(_TokenKind.rightBrace)) {
          _error(
            'JUI002_UNCLOSED_BLOCK',
            'Container "$kind" block was not closed.',
            token.span,
          );
        }
      }
    } else if (_check(_TokenKind.leftBrace)) {
      _error(
        'JUI001_UNEXPECTED_TOKEN',
        'Leaf node "$kind" cannot contain a block.',
        _currentToken.span,
      );
      _advance();
    }

    if (_currentToken.kind == _TokenKind.identifier &&
        !_containers.contains(_currentToken.lexeme) &&
        !_leaves.contains(_currentToken.lexeme) &&
        !_attributeNames.contains(_currentToken.lexeme)) {
      _error(
        'JUI012_UNKNOWN_ATTRIBUTE',
        'Unknown attribute or node token "' + _currentToken.lexeme + '".',
        _currentToken.span,
      );
      _advance();
    }

    return JuiNode(
      kind: kind,
      attributes: attributes,
      children: children,
      span: JuiSourceSpan(
        offset: token.span.offset,
        length: _previousToken.span.offset +
            _previousToken.span.length -
            token.span.offset,
        line: token.span.line,
        column: token.span.column,
      ),
    );
  }

  Object? _parseAttributeValue(String attribute) {
    if (attribute == 'enabled') {
      _consumeIdentifier('bind', 'Expected "bind" after "enabled".');
      return _consumeString('Expected a binding ID after "enabled bind".');
    }
    if (attribute == 'gap') {
      final token = _consumeNumber('Expected a number after "gap".');
      final value = token?.value;
      if (value is num && value.isFinite && value >= 0 && value <= 4096) {
        return value;
      }
      _error(
        'JUI013_INVALID_NUMBER',
        'Layout values must be between 0 and 4096.',
        token?.span ?? _currentToken.span,
      );
      return null;
    }
    if (attribute == 'type') {
      if (_currentToken.kind != _TokenKind.identifier) {
        _error(
          'JUI001_UNEXPECTED_TOKEN',
          'Expected an input type identifier.',
          _currentToken.span,
        );
        return null;
      }
      return _advance().lexeme;
    }
    return _consumeString('Expected a quoted string after "$attribute".');
  }

  void _validateDocument(JuiDocument document) {
    final ids = <String>{};
    for (final node in document.children) {
      _validateNode(node, ids);
    }
  }

  void _validateNode(JuiNode node, Set<String> ids) {
    final id = node.id;
    if (id != null && !ids.add(id)) {
      _error(
        'JUI020_DUPLICATE_ID',
        'Node ID "$id" is used more than once in this screen.',
        node.span,
      );
    }

    final allowed = _allowedAttributes(node.kind);
    for (final attribute in node.attributes.keys) {
      if (!allowed.contains(attribute)) {
        _error(
          'JUI012_UNKNOWN_ATTRIBUTE',
          'Attribute "$attribute" is not valid on "' + node.kind + '".',
          node.span,
        );
      }
    }

    if (node.kind == 'text') {
      final hasKey = node.key != null;
      final hasBinding = node.binding != null;
      if (hasKey == hasBinding) {
        _error(
          'JUI021_TEXT_SOURCE_REQUIRED',
          'Text requires exactly one of "key" or "bind".',
          node.span,
        );
      }
    } else if (node.kind == 'input') {
      if (node.id == null || node.binding == null || node.type == null) {
        _error(
          'JUI022_INPUT_CONTRACT',
          'Input requires id, bind and type.',
          node.span,
        );
      }
      if (node.type != null &&
          !const {'integer', 'number', 'text', 'boolean'}.contains(node.type)) {
        _error(
          'JUI023_INVALID_INPUT_TYPE',
          'Unsupported input type "' + node.type! + '".',
          node.span,
        );
      }
    } else if (node.kind == 'button') {
      if (node.id == null || node.action == null) {
        _error(
          'JUI024_BUTTON_CONTRACT',
          'Button requires id and action.',
          node.span,
        );
      }
    } else if (node.kind == 'toggle') {
      if (node.id == null || node.binding == null) {
        _error(
          'JUI025_TOGGLE_CONTRACT',
          'Toggle requires id and bind.',
          node.span,
        );
      }
    } else if (node.kind == 'image') {
      if (node.asset == null) {
        _error(
          'JUI026_IMAGE_CONTRACT',
          'Image requires an asset path.',
          node.span,
        );
      }
    } else if (node.kind == 'icon') {
      if (node.asset == null && node.style == null) {
        _error(
          'JUI027_ICON_CONTRACT',
          'Icon requires an asset or registered style token.',
          node.span,
        );
      }
    } else if (node.kind == 'list') {
      if (node.binding == null) {
        _error(
          'JUI028_LIST_CONTRACT',
          'List requires a typed item binding.',
          node.span,
        );
      }
    } else if (node.kind == 'dialog' && node.id == null) {
      _error(
        'JUI029_DIALOG_CONTRACT',
        'Dialog requires a stable ID.',
        node.span,
      );
    }

    for (final child in node.children) {
      _validateNode(child, ids);
    }
  }

  Set<String> _allowedAttributes(String kind) {
    if (kind == 'column' ||
        kind == 'row' ||
        kind == 'stack' ||
        kind == 'scroll' ||
        kind == 'panel') {
      return {'id', 'style', 'gap'};
    }
    if (kind == 'list') return {'id', 'style', 'gap', 'bind'};
    if (kind == 'dialog') return {'id', 'style'};
    if (kind == 'text') {
      return {'id', 'key', 'bind', 'style', 'label', 'semantic'};
    }
    if (kind == 'icon') return {'id', 'asset', 'style', 'semantic'};
    if (kind == 'image') return {'id', 'asset', 'semantic'};
    if (kind == 'spacer') return {'id', 'gap'};
    if (kind == 'divider') return {'id', 'style'};
    if (kind == 'input') return {'id', 'bind', 'type', 'label', 'semantic'};
    if (kind == 'button') {
      return {'id', 'key', 'action', 'enabled', 'style', 'semantic'};
    }
    if (kind == 'toggle') return {'id', 'bind', 'label', 'semantic'};
    return const {};
  }

  String? _consumeString(String message) {
    if (_currentToken.kind != _TokenKind.string) {
      _error('JUI001_UNEXPECTED_TOKEN', message, _currentToken.span);
      return null;
    }
    return _advance().value as String;
  }

  _Token? _consumeNumber(String message) {
    if (_currentToken.kind != _TokenKind.number) {
      _error('JUI001_UNEXPECTED_TOKEN', message, _currentToken.span);
      return null;
    }
    return _advance();
  }

  void _consumeIdentifier(String value, String message) {
    if (!_matchIdentifier(value)) {
      _error('JUI001_UNEXPECTED_TOKEN', message, _currentToken.span);
    }
  }

  bool _matchIdentifier(String value) {
    if (_currentToken.kind != _TokenKind.identifier ||
        _currentToken.lexeme != value) {
      return false;
    }
    _advance();
    return true;
  }

  bool _match(_TokenKind kind) {
    if (!_check(kind)) return false;
    _advance();
    return true;
  }

  bool _check(_TokenKind kind) => _currentToken.kind == kind;
  _Token get _currentToken => _tokens[_current];
  _Token get _previousToken => _tokens[_current - 1];

  _Token _advance() {
    if (!_check(_TokenKind.eof)) _current++;
    return _previousToken;
  }

  void _error(String code, String message, JuiSourceSpan span) {
    _diagnostics.add(
      JuiDiagnostic(code: code, message: message, span: span),
    );
  }

  JuiParseResult _failure() =>
      JuiParseResult(document: null, diagnostics: _diagnostics);
}
