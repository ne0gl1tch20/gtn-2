import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// Preferred-size wrapper that routes application app bars through M3 Expressive.
class GtnExpressiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GtnExpressiveAppBar({
    super.key,
    this.title,
    this.titleText,
    this.leading,
    this.actions,
    this.centerTitle = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.toolbarHeight,
    this.automaticallyImplyLeading = true,
  });

  final Widget? title;
  final String? titleText;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final double? toolbarHeight;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight ?? 64);

  @override
  Widget build(BuildContext context) => M3EAppBar.top(
        title: title,
        titleText: titleText,
        leading: leading,
        actions: actions,
        centerTitle: centerTitle,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: elevation,
        toolbarHeight: toolbarHeight,
        automaticallyImplyLeading: automaticallyImplyLeading,
      );
}

/// Card compatibility wrapper backed by the native M3 Expressive card surface.
class GtnExpressiveCard extends StatelessWidget {
  const GtnExpressiveCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.all(4),
    this.color,
    this.elevation,
    this.shape,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final double? elevation;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final roundedShape = shape is RoundedRectangleBorder
        ? shape! as RoundedRectangleBorder
        : null;
    return Padding(
      padding: margin,
      child: M3ECard(
        padding: padding,
        color: color,
        elevation: elevation,
        borderRadius: roundedShape?.borderRadius.resolve(TextDirection.ltr),
        border: roundedShape?.side,
        child: child,
      ),
    );
  }
}

/// Text-field adapter that preserves the existing TextField call sites while
/// rendering the native M3 Expressive floating-label input.
class GtnExpressiveTextField extends StatelessWidget {
  const GtnExpressiveTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.obscureText = false,
    this.onEditingComplete,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int? maxLines;
  final int? minLines;
  final bool readOnly;
  final bool autofocus;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final bool obscureText;
  final VoidCallback? onEditingComplete;

  @override
  Widget build(BuildContext context) => M3ETextField(
        controller: controller,
        focusNode: focusNode,
        label: decoration?.labelText,
        supportingText: decoration?.helperText,
        errorText: decoration?.errorText,
        prefixText: decoration?.prefixText,
        suffixText: decoration?.suffixText,
        placeholder: decoration?.hintText,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        maxLines: maxLines,
        minLines: minLines,
        readOnly: readOnly,
        autofocus: autofocus,
        maxLength: maxLength,
        textCapitalization: textCapitalization,
        textAlign: textAlign,
        obscureText: obscureText,
        onEditingComplete: onEditingComplete,
      );
}
