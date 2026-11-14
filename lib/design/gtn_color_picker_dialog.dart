import 'package:flutter/material.dart';

class GtnColorPickerResult {
  const GtnColorPickerResult({this.hex, this.reset = false});

  final String? hex;
  final bool reset;
}

Future<GtnColorPickerResult?> showGtnColorPickerDialog(
  BuildContext context, {
  required String initialHex,
  String title = 'Pick a color',
  bool allowReset = false,
}) {
  return showDialog<GtnColorPickerResult>(
    context: context,
    builder: (_) => _GtnColorPickerDialog(
      initialHex: initialHex,
      title: title,
      allowReset: allowReset,
    ),
  );
}

class _GtnColorPickerDialog extends StatefulWidget {
  const _GtnColorPickerDialog({
    required this.initialHex,
    required this.title,
    required this.allowReset,
  });

  final String initialHex;
  final String title;
  final bool allowReset;

  @override
  State<_GtnColorPickerDialog> createState() => _GtnColorPickerDialogState();
}

class _GtnColorPickerDialogState extends State<_GtnColorPickerDialog> {
  late HSVColor _hsv;
  late final TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    final color = _parseColor(widget.initialHex) ?? Colors.purple;
    _hsv = HSVColor.fromColor(color);
    _hexController = TextEditingController(text: _formatHex(color));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  static Color? _parseColor(String value) {
    final hex = value.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
    return Color(int.parse('FF$hex', radix: 16));
  }

  static String _formatHex(Color color) {
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  void _updateFromPosition(Offset position, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    setState(() {
      _hsv = _hsv
          .withSaturation((position.dx / size.width).clamp(0.0, 1.0).toDouble())
          .withValue((1 - position.dy / size.height).clamp(0.0, 1.0).toDouble());
      _hexController.text = _formatHex(_hsv.toColor());
    });
  }

  void _updateFromHex(String value) {
    final color = _parseColor(value);
    if (color == null) return;
    setState(() => _hsv = HSVColor.fromColor(color));
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsv.toColor();
    final hueColor = HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor();
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Color', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, 190);
                  return GestureDetector(
                    onPanDown: (details) =>
                        _updateFromPosition(details.localPosition, size),
                    onPanUpdate: (details) =>
                        _updateFromPosition(details.localPosition, size),
                    child: CustomPaint(
                      size: size,
                      painter: _SaturationValuePainter(
                        hueColor: hueColor,
                        saturation: _hsv.saturation,
                        value: _hsv.value,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Text('Hue: ${_hsv.hue.round()}°'),
              Slider(
                value: _hsv.hue.clamp(0, 360).toDouble(),
                min: 0,
                max: 360,
                onChanged: (value) {
                  setState(() {
                    _hsv = _hsv.withHue(value);
                    _hexController.text = _formatHex(_hsv.toColor());
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.28),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Live preview', style: theme.textTheme.labelLarge),
                        Text(
                          _formatHex(color),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _hexController,
                onChanged: _updateFromHex,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Hex',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.allowReset)
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              const GtnColorPickerResult(reset: true),
            ),
            child: const Text('Use theme'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            GtnColorPickerResult(hex: _formatHex(color)),
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _SaturationValuePainter extends CustomPainter {
  const _SaturationValuePainter({
    required this.hueColor,
    required this.saturation,
    required this.value,
  });

  final Color hueColor;
  final double saturation;
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, hueColor],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );

    final center = Offset(saturation * size.width, (1 - value) * size.height);
    canvas.drawCircle(
      center,
      10,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      center,
      7,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePainter oldDelegate) {
    return hueColor != oldDelegate.hueColor ||
        saturation != oldDelegate.saturation ||
        value != oldDelegate.value;
  }
}
