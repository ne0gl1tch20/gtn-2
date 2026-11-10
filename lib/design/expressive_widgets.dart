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
