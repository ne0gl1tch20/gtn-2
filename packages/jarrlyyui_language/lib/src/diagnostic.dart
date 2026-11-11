class JuiSourceSpan {
  const JuiSourceSpan({
    required this.offset,
    required this.length,
    required this.line,
    required this.column,
  });

  final int offset;
  final int length;
  final int line;
  final int column;
}

class JuiDiagnostic {
  const JuiDiagnostic({
    required this.code,
    required this.message,
    required this.span,
  });

  final String code;
  final String message;
  final JuiSourceSpan span;

  int get line => span.line;
  int get column => span.column;

  @override
  String toString() => '$code at $line:$column: $message';
}
