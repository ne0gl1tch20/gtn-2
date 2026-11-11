import 'diagnostic.dart';

class JuiDocument {
  JuiDocument({
    required this.id,
    required this.version,
    required List<JuiNode> children,
    required this.span,
  }) : children = List<JuiNode>.unmodifiable(children);

  final String id;
  final int version;
  final List<JuiNode> children;
  final JuiSourceSpan span;
}

class JuiNode {
  JuiNode({
    required this.kind,
    required Map<String, Object> attributes,
    required List<JuiNode> children,
    required this.span,
  }) : attributes = Map<String, Object>.unmodifiable(attributes),
       children = List<JuiNode>.unmodifiable(children);

  final String kind;
  final Map<String, Object> attributes;
  final List<JuiNode> children;
  final JuiSourceSpan span;

  String? get id => attributes['id'] as String?;
  String? get key => attributes['key'] as String?;
  String? get binding => attributes['bind'] as String?;
  String? get action => attributes['action'] as String?;
  String? get asset => attributes['asset'] as String?;
  String? get style => attributes['style'] as String?;
  String? get type => attributes['type'] as String?;
}
