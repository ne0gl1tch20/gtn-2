import 'package:flutter/material.dart';
import 'package:jarrlyyui_language/jarrlyyui_language.dart';

typedef JuiTextResolver = String Function(String key);
typedef JuiAssetBuilder = Widget Function(
  BuildContext context,
  String path,
  String? semanticLabel,
);

class JuiInputChange {
  const JuiInputChange({required this.binding, required this.value});

  final String binding;
  final Object? value;
}

/// Renders a validated jarrlyyui v1 document using native Flutter widgets.
///
/// The host supplies read-only values, writable input callbacks and an
/// allowlisted action dispatcher. This renderer never mutates application or
/// gameplay state directly.
class JuiRenderer extends StatelessWidget {
  const JuiRenderer({
    super.key,
    required this.document,
    this.values = const {},
    this.onInputChanged,
    this.onAction,
    this.resolveText,
    this.buildAsset,
    this.padding = const EdgeInsets.all(16),
  });

  final JuiDocument document;
  final Map<String, Object?> values;
  final ValueChanged<JuiInputChange>? onInputChanged;
  final ValueChanged<String>? onAction;
  final JuiTextResolver? resolveText;
  final JuiAssetBuilder? buildAsset;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: padding,
          child: _buildChildren(context, document.children, Axis.vertical),
        ),
      ),
    );
  }

  Widget _buildChildren(
    BuildContext context,
    List<JuiNode> nodes,
    Axis axis, {
    double gap = 0,
  }) {
    final children = <Widget>[];
    for (final node in nodes) {
      if (children.isNotEmpty && gap > 0) {
        children.add(
          axis == Axis.horizontal
              ? SizedBox(width: gap)
              : SizedBox(height: gap),
        );
      }
      children.add(_buildNode(context, node));
    }
    return axis == Axis.horizontal
        ? Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
  }

  Widget _buildNode(BuildContext context, JuiNode node) {
    final gap = _number(node, 'gap')?.clamp(0, 128).toDouble() ?? 0;
    final children = node.children;
    switch (node.kind) {
      case 'column':
        return _buildChildren(context, children, Axis.vertical, gap: gap);
      case 'row':
        return _buildChildren(context, children, Axis.horizontal, gap: gap);
      case 'stack':
        return Stack(
          children: children.map((child) => _buildNode(context, child)).toList(),
        );
      case 'scroll':
        return SingleChildScrollView(
          child: _buildChildren(context, children, Axis.vertical, gap: gap),
        );
      case 'panel':
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildChildren(
              context,
              children,
              Axis.vertical,
              gap: gap,
            ),
          ),
        );
      case 'list':
        return _buildChildren(context, children, Axis.vertical, gap: gap);
      case 'dialog':
        return AlertDialog(
          content: _buildChildren(
            context,
            children,
            Axis.vertical,
            gap: gap,
          ),
        );
      case 'text':
        return Text(
          _textFor(node),
          semanticsLabel: node.attributes['semantic'] as String?,
          style: _textStyle(context, node.style),
        );
      case 'icon':
        return _buildIcon(context, node);
      case 'image':
        return _buildImage(context, node);
      case 'spacer':
        final extent = _number(node, 'extent')?.clamp(0, 4096).toDouble() ?? 8;
        return SizedBox(width: extent, height: extent);
      case 'divider':
        return Divider(
          height: _number(node, 'extent')?.clamp(0, 128).toDouble() ?? 1,
        );
      case 'input':
        return _buildInput(node);
      case 'toggle':
        return _buildToggle(node);
      case 'button':
        return _buildButton(context, node);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInput(JuiNode node) {
    final binding = node.binding;
    if (binding == null) return const SizedBox.shrink();
    final isInteger = node.type == 'integer';
    final current = values[binding]?.toString() ?? '';
    return _JuiBoundInput(
      key: ValueKey(node.id ?? binding),
      initialValue: current,
      label: _labelFor(node),
      semanticLabel: node.attributes['semantic'] as String?,
      keyboardType: isInteger ? TextInputType.number : TextInputType.text,
      onChanged: (text) {
        final value = isInteger ? int.tryParse(text) : text;
        if (value != null) {
          onInputChanged?.call(JuiInputChange(binding: binding, value: value));
        }
      },
    );
  }

  Widget _buildToggle(JuiNode node) {
    final binding = node.binding;
    if (binding == null) return const SizedBox.shrink();
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(_labelFor(node)),
      value: values[binding] == true,
      onChanged: (value) => onInputChanged?.call(
        JuiInputChange(binding: binding, value: value),
      ),
    );
  }

  Widget _buildButton(BuildContext context, JuiNode node) {
    final action = node.action;
    if (action == null) return const SizedBox.shrink();
    final enabledBinding = node.attributes['enabled'] as String?;
    final enabled = enabledBinding == null || values[enabledBinding] == true;
    final child = node.children.isEmpty
        ? Text(_labelFor(node))
        : _buildChildren(context, node.children, Axis.vertical);
    return FilledButton(
      onPressed: enabled ? () => onAction?.call(action) : null,
      child: child,
    );
  }

  Widget _buildIcon(BuildContext context, JuiNode node) {
    final asset = node.asset;
    if (asset != null) return _asset(context, asset, node);
    final token = node.attributes['key'] as String? ?? '';
    final icon = _iconFor(token);
    return Semantics(
      label: node.attributes['semantic'] as String?,
      image: true,
      child: Icon(icon),
    );
  }

  Widget _buildImage(BuildContext context, JuiNode node) {
    final asset = node.asset;
    if (asset == null) return const SizedBox.shrink();
    return _asset(context, asset, node);
  }

  Widget _asset(BuildContext context, String path, JuiNode node) {
    final semantic = node.attributes['semantic'] as String?;
    if (buildAsset != null) return buildAsset!(context, path, semantic);
    return Image.asset(
      path,
      semanticLabel: semantic,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
    );
  }

  String _textFor(JuiNode node) {
    final binding = node.binding;
    if (binding != null) return values[binding]?.toString() ?? '';
    final key = node.key;
    if (key != null) return resolveText?.call(key) ?? key;
    return '';
  }

  String _labelFor(JuiNode node) {
    final label = node.attributes['label'] as String?;
    if (label != null) return label;
    final key = node.key;
    if (key != null) return resolveText?.call(key) ?? key;
    return node.id ?? '';
  }

  TextStyle? _textStyle(BuildContext context, String? token) {
    final styles = Theme.of(context).textTheme;
    return switch (token) {
      'headline' => styles.headlineSmall,
      'title' => styles.titleLarge,
      'value' => styles.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      'caption' => styles.bodySmall,
      'body' => styles.bodyMedium,
      _ => styles.bodyMedium,
    };
  }

  IconData _iconFor(String token) => switch (token) {
    'home' => Icons.home_outlined,
    'settings' => Icons.settings_outlined,
    'star' => Icons.star_outline,
    'info' => Icons.info_outline,
    'check' => Icons.check_circle_outline,
    'close' => Icons.close,
    'menu' => Icons.menu,
    'arrow' => Icons.arrow_forward,
    'play' => Icons.play_arrow,
    'bolt' => Icons.bolt,
    _ => Icons.circle_outlined,
  };

  double? _number(JuiNode node, String key) {
    final value = node.attributes[key];
    return value is num && value.isFinite ? value.toDouble() : null;
  }
}

class _JuiBoundInput extends StatefulWidget {
  const _JuiBoundInput({
    super.key,
    required this.initialValue,
    required this.label,
    required this.semanticLabel,
    required this.keyboardType,
    required this.onChanged,
  });

  final String initialValue;
  final String label;
  final String? semanticLabel;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;

  @override
  State<_JuiBoundInput> createState() => _JuiBoundInputState();
}

class _JuiBoundInputState extends State<_JuiBoundInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _JuiBoundInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(
          offset: widget.initialValue.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    keyboardType: widget.keyboardType,
    onChanged: widget.onChanged,
    decoration: InputDecoration(labelText: widget.label),
    semanticsLabel: widget.semanticLabel,
  );
}
