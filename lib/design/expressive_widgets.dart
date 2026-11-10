import 'package:flutter/services.dart';
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

/// GTN1 visual tokens. These intentionally preserve the Web Play identity while
/// M3 Expressive supplies selected interactive controls, not the whole visual system.
class GtnUiTokens {
  GtnUiTokens._();

  static const background = Color(0xFF080B16);
  static const panel = Color(0xFF11172A);
  static const raisedPanel = Color(0xFF171F36);
  static const line = Color(0x20FFFFFF);
  static const foreground = Color(0xFFF7F8FF);
  static const muted = Color(0xFF9BA5C4);
  static const purple = Color(0xFF9B7CFF);
  static const cyan = Color(0xFF62E8FF);
  static const gold = Color(0xFFFFD66B);
  static const green = Color(0xFF63F5A4);
  static const danger = Color(0xFFFF7195);
  static const radius = 26.0;
  static const contentMaxWidth = 720.0;
}

/// GTN1-style surface with custom gradients, borders and glow; M3E is reserved
/// for the interactive controls where its expressive motion is useful.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = roundedShape?.borderRadius.resolve(TextDirection.ltr).topLeft.x ??
        GtnUiTokens.radius;
    final side = roundedShape?.side ??
        BorderSide(color: isDark ? GtnUiTokens.line : const Color(0x180D1530));
    return Padding(
      padding: margin,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? (isDark ? GtnUiTokens.panel : Colors.white),
          borderRadius: BorderRadius.circular(radius),
          border: Border.fromBorderSide(side),
          boxShadow: (elevation ?? 0) > 0
              ? [BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? .22 : .08),
                  blurRadius: (elevation ?? 0) * 5,
                  offset: Offset(0, (elevation ?? 0) * 1.5),
                )]
              : const [],
        ),
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
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = dark
        ? Colors.white.withValues(alpha: .10)
        : const Color(0x220D1530);
    final hintColor = dark ? GtnUiTokens.muted : const Color(0xFF65708C);
    final radius = BorderRadius.circular(18);
    return TextField(
      controller: controller,
      focusNode: focusNode,
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
      style: TextStyle(
        color: dark ? GtnUiTokens.foreground : const Color(0xFF172039),
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: decoration?.labelText,
        hintText: decoration?.hintText,
        helperText: decoration?.helperText,
        errorText: decoration?.errorText,
        prefixText: decoration?.prefixText,
        suffixText: decoration?.suffixText,
        filled: true,
        fillColor: dark ? const Color(0xFF080D1B) : const Color(0xFFF0F1FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(
            color: GtnUiTokens.purple,
            width: 1.4,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: borderColor.withValues(alpha: .5)),
        ),
        hintStyle: TextStyle(color: hintColor.withValues(alpha: .8)),
      ),
    );
  }
}

/// Switch row backed by the spring-driven M3 Expressive switch.
class GtnExpressiveSwitchTile extends StatelessWidget {
  const GtnExpressiveSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    this.secondary,
    required this.value,
    required this.onChanged,
    this.contentPadding,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? secondary;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: contentPadding,
        leading: secondary,
        title: title,
        subtitle: subtitle,
        trailing: M3ESwitch(value: value, onChanged: onChanged),
      );
}

/// Choice chip adapter backed by the M3 Expressive filter-chip interaction.
class GtnExpressiveChoiceChip extends StatelessWidget {
  const GtnExpressiveChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) => M3EChip(
        label: label,
        type: M3EChipType.filter,
        selected: selected,
        onPressed: onSelected == null ? null : () => onSelected!(!selected),
      );
}

/// Single-select dropdown adapter backed by M3EDropdownMenu.
class GtnExpressiveDropdown<T> extends StatelessWidget {
  const GtnExpressiveDropdown({
    super.key,
    this.value,
    this.initialValue,
    required this.items,
    this.onChanged,
    this.decoration,
  });

  final T? value;
  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final selectedValue = value ?? initialValue;
    final expressiveItems = items
        .where((item) => item.value != null)
        .map(
          (item) => M3EDropdownItem<T>(
            label: item.child is Text
                ? (item.child as Text).data ?? item.value.toString()
                : item.value.toString(),
            value: item.value as T,
            selected: item.value == selectedValue,
            disabled: !item.enabled,
          ),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (decoration?.labelText case final label?)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
        M3EDropdownMenu<T>(
          items: expressiveItems,
          singleSelect: true,
          enabled: onChanged != null,
          fieldStyle: M3EDropdownFieldStyle(
            hintText: decoration?.hintText ??
                decoration?.labelText ??
                'Select an option',
          ),
          onSelectionChanged: (selected) {
            if (selected.isNotEmpty) onChanged?.call(selected.first.value);
          },
        ),
        if (decoration?.helperText case final helper?)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(helper, style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }
}

/// Dialog surface and presentation adapter backed by M3 Expressive dialogs.
class GtnExpressiveDialog extends StatelessWidget {
  const GtnExpressiveDialog({
    super.key,
    required this.title,
    this.content,
    this.actions = const [],
    this.icon,
    this.subhead,
    this.contentPadding,
  });

  final Widget title;
  final Widget? content;
  final List<Widget> actions;
  final Widget? icon;
  final String? subhead;
  final EdgeInsets? contentPadding;

  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    bool? resizeToAvoidBottomInset,
  }) {
    return M3EDialog.show<T>(
      context,
      dialog: Builder(builder: builder),
      barrierDismissible: barrierDismissible,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }

  @override
  Widget build(BuildContext context) {
    final headline = title is Text ? (title as Text).data ?? '' : title.toString();
    return M3EDialog(
      title: headline,
      content: content,
      actions: actions,
      icon: icon,
      subhead: subhead,
      contentPadding: contentPadding,
    );
  }
}

/// Message presenter backed by the M3 Expressive snackbar overlay.
class GtnExpressiveSnackbar {
  static void show(
    BuildContext context, {
    required Widget content,
    Duration? duration,
  }) {
    final message = content is Text ? content.data ?? '' : content.toString();
    M3ESnackbar.show(context, message: message, duration: duration);
  }
}
