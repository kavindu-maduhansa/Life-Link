import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/lifelink_design.dart';
import '../lifelink/ll_components.dart';

// -----------------------------------------------------------------------------
// NeumorphicSurface
// -----------------------------------------------------------------------------

/// A tactile soft-surface container supporting raised, flat, and pressed states.
///
/// Features:
/// - Light top-left directional highlight and dark bottom-right ambient shadow.
/// - Tactile subtle gradient surface.
/// - Crisp accessible border to ensure visibility on low-contrast screens.
class NeumorphicSurface extends StatelessWidget {
  const NeumorphicSurface({
    super.key,
    this.child,
    this.elevation = NeumorphicElevationLevel.card,
    this.borderRadius,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.isPressed = false,
    this.useGradient = true,
  });

  final Widget? child;
  final NeumorphicElevationLevel elevation;
  final BorderRadius? borderRadius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool isPressed;
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brightness = Theme.of(context).brightness;
    final radius = borderRadius ?? BorderRadius.circular(LLRadius.card);
    final surfaceColor = color ?? colors.surface;
    final borderCol = borderColor ?? colors.border;

    final decoration = isPressed
        ? BoxDecoration(
            color: colors.elevatedSurface,
            borderRadius: radius,
            border: Border.all(color: borderCol, width: borderWidth),
            gradient: useGradient
                ? LLNeumorphism.concaveGradient(
                    brightness: brightness,
                    baseColor: colors.elevatedSurface,
                  )
                : null,
          )
        : BoxDecoration(
            color: surfaceColor,
            borderRadius: radius,
            border: Border.all(color: borderCol, width: borderWidth),
            boxShadow: LLNeumorphism.shadows(
              brightness: brightness,
              elevation: elevation,
            ),
            gradient: useGradient
                ? LLNeumorphism.convexGradient(
                    brightness: brightness,
                    baseColor: surfaceColor,
                  )
                : null,
          );

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }
}

// -----------------------------------------------------------------------------
// NeumorphicCard
// -----------------------------------------------------------------------------

/// Tactile card with Neumorphic dual shadows, optional tap reaction,
/// and semantic border accents.
class NeumorphicCard extends StatefulWidget {
  const NeumorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(LLSpacing.lg),
    this.margin,
    this.borderRadius,
    this.tone,
    this.emphasised = false,
    this.elevation = NeumorphicElevationLevel.card,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final LLTone? tone;
  final bool emphasised;
  final NeumorphicElevationLevel elevation;
  final Color? color;
  final VoidCallback? onTap;

  @override
  State<NeumorphicCard> createState() => _NeumorphicCardState();
}

class _NeumorphicCardState extends State<NeumorphicCard> {
  bool _isDown = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = widget.borderRadius ?? BorderRadius.circular(LLRadius.card);

    final borderColor = widget.emphasised && widget.tone != null
        ? widget.tone!.resolve(context).$1.withValues(alpha: 0.55)
        : colors.border;

    final card = NeumorphicSurface(
      elevation: _isDown ? NeumorphicElevationLevel.low : widget.elevation,
      borderRadius: radius,
      color: widget.color ?? colors.surface,
      borderColor: borderColor,
      padding: widget.padding,
      margin: widget.margin,
      isPressed: _isDown,
      child: widget.child,
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isDown = true),
      onTapUp: (_) => setState(() => _isDown = false),
      onTapCancel: () => setState(() => _isDown = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isDown ? 0.985 : 1.0,
        duration: LLMotion.fast,
        curve: Curves.easeOutCubic,
        child: card,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// NeumorphicButton
// -----------------------------------------------------------------------------

/// Tactile raised button with accessible tap target, loading state,
/// and smooth pressed-depth animation.
class NeumorphicButton extends StatefulWidget {
  const NeumorphicButton({
    super.key,
    this.onPressed,
    this.label,
    this.icon,
    this.child,
    this.isPrimary = true,
    this.isOutlined = false,
    this.isCritical = false,
    this.tone,
    this.isLoading = false,
    this.height = 48,
    this.width,
    this.borderRadius,
    this.padding,
  });

  final VoidCallback? onPressed;
  final String? label;
  final IconData? icon;
  final Widget? child;
  final bool isPrimary;
  final bool isOutlined;
  final bool isCritical;
  final LLTone? tone;
  final bool isLoading;
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isDown = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = widget.onPressed != null && !widget.isLoading;
    final radius =
        widget.borderRadius ?? BorderRadius.circular(LLRadius.control);

    Color fg;
    Color bg;
    Color borderCol;

    if (!enabled) {
      fg = colors.disabled;
      bg = colors.elevatedSurface;
      borderCol = colors.border;
    } else if (widget.isCritical) {
      fg = Colors.white;
      bg = colors.critical;
      borderCol = colors.critical;
    } else if (widget.tone != null) {
      final (tFg, tBg) = widget.tone!.resolve(context);
      fg = widget.isPrimary ? Colors.white : tFg;
      bg = widget.isPrimary ? tFg : tBg;
      borderCol = tFg;
    } else if (widget.isOutlined) {
      fg = colors.accent;
      bg = _isDown ? colors.accentContainer : colors.surface;
      borderCol = colors.accent;
    } else if (widget.isPrimary) {
      fg = Colors.white;
      bg = colors.primary;
      borderCol = colors.primary;
    } else {
      fg = colors.textPrimary;
      bg = colors.surface;
      borderCol = colors.border;
    }

    final decoration = !enabled
        ? BoxDecoration(
            color: bg,
            borderRadius: radius,
            border: Border.all(color: borderCol),
          )
        : LLNeumorphism.buttonDecoration(
            context,
            borderRadius: radius,
            color: bg,
            borderColor: borderCol,
            isPressed: _isDown,
            isOutlined: widget.isOutlined,
            isPrimary: widget.isPrimary || widget.isCritical,
          );

    Widget content;
    if (widget.isLoading) {
      content = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    } else if (widget.child != null) {
      content = widget.child!;
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: LLIconSize.action, color: fg),
            const SizedBox(width: LLSpacing.sm),
          ],
          if (widget.label != null)
            Text(
              widget.label!,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: fg,
                letterSpacing: 0.2,
              ),
            ),
        ],
      );
    }

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isDown = true) : null,
        onTapUp: enabled ? (_) => setState(() => _isDown = false) : null,
        onTapCancel: enabled ? () => setState(() => _isDown = false) : null,
        onTap: enabled ? widget.onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isDown && enabled ? 0.98 : 1.0,
          duration: LLMotion.fast,
          curve: Curves.easeOutCubic,
          child: Container(
            width: widget.width,
            height: widget.height,
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            padding:
                widget.padding ??
                const EdgeInsets.symmetric(horizontal: LLSpacing.lg),
            alignment: Alignment.center,
            decoration: decoration,
            child: content,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// NeumorphicIconButton
// -----------------------------------------------------------------------------

/// Tactile icon button with soft dual shadows and minimum 44x44 tap target.
class NeumorphicIconButton extends StatefulWidget {
  const NeumorphicIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.iconColor,
    this.backgroundColor,
    this.size = 44,
    this.iconSize = 20,
    this.isCircle = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;
  final double iconSize;
  final bool isCircle;

  @override
  State<NeumorphicIconButton> createState() => _NeumorphicIconButtonState();
}

class _NeumorphicIconButtonState extends State<NeumorphicIconButton> {
  bool _isDown = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brightness = Theme.of(context).brightness;
    final enabled = widget.onPressed != null;
    final radius = widget.isCircle
        ? BorderRadius.circular(widget.size / 2)
        : BorderRadius.circular(LLRadius.control);

    final bg = widget.backgroundColor ?? colors.surface;
    final fg =
        widget.iconColor ?? (enabled ? colors.textPrimary : colors.disabled);

    final decoration = !enabled
        ? BoxDecoration(
            color: colors.elevatedSurface,
            borderRadius: radius,
            border: Border.all(color: colors.border),
          )
        : BoxDecoration(
            color: _isDown ? colors.elevatedSurface : bg,
            borderRadius: radius,
            border: Border.all(
              color: _isDown
                  ? colors.accent.withValues(alpha: 0.6)
                  : colors.border,
            ),
            boxShadow: _isDown
                ? const []
                : LLNeumorphism.shadows(
                    brightness: brightness,
                    elevation: NeumorphicElevationLevel.low,
                  ),
            gradient: _isDown
                ? LLNeumorphism.concaveGradient(
                    brightness: brightness,
                    baseColor: bg,
                  )
                : LLNeumorphism.convexGradient(
                    brightness: brightness,
                    baseColor: bg,
                  ),
          );

    final button = GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _isDown = true) : null,
      onTapUp: enabled ? (_) => setState(() => _isDown = false) : null,
      onTapCancel: enabled ? () => setState(() => _isDown = false) : null,
      onTap: enabled ? widget.onPressed : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isDown && enabled ? 0.94 : 1.0,
        duration: LLMotion.fast,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: decoration,
          alignment: Alignment.center,
          child: Icon(widget.icon, size: widget.iconSize, color: fg),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

// -----------------------------------------------------------------------------
// NeumorphicInput
// -----------------------------------------------------------------------------

/// Recessed soft form input with smooth focus ring, validation errors,
/// and clear input boundaries.
class NeumorphicInput extends StatefulWidget {
  const NeumorphicInput({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  State<NeumorphicInput> createState() => _NeumorphicInputState();
}

class _NeumorphicInputState extends State<NeumorphicInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final hasError = _errorText != null && _errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              widget.labelText!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hasError
                    ? colors.critical
                    : _isFocused
                    ? colors.accent
                    : colors.textSecondary,
              ),
            ),
          ),
        ],
        Container(
          decoration: LLNeumorphism.inputDecoration(
            context,
            isFocused: _isFocused,
            hasError: hasError,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            autofocus: widget.autofocus,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            onChanged: (val) {
              if (hasError) setState(() => _errorText = null);
              widget.onChanged?.call(val);
            },
            onFieldSubmitted: widget.onFieldSubmitted,
            validator: (val) {
              final err = widget.validator?.call(val);
              setState(() => _errorText = err);
              return err;
            },
            style: TextStyle(
              fontSize: 14.5,
              color: widget.enabled ? colors.textPrimary : colors.disabled,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                fontSize: 14,
                color: colors.textSecondary.withValues(alpha: 0.7),
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              errorStyle: const TextStyle(height: 0, fontSize: 0),
            ),
          ),
        ),
        if (hasError) ...[
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 5),
            child: Text(
              _errorText!,
              style: TextStyle(
                fontSize: 12,
                color: colors.critical,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// NeumorphicDropdown
// -----------------------------------------------------------------------------

/// Recessed soft dropdown selector with crisp accessible borders.
class NeumorphicDropdown<T> extends StatelessWidget {
  const NeumorphicDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.labelText,
    this.prefixIcon,
    this.validator,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final Widget? hint;
  final String? labelText;
  final Widget? prefixIcon;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              labelText!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
        Container(
          decoration: LLNeumorphism.inputDecoration(context),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonFormField<T>(
            initialValue: value,
            items: items,
            onChanged: onChanged,
            hint: hint,
            validator: validator,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colors.textSecondary,
            ),
            dropdownColor: colors.surface,
            style: TextStyle(fontSize: 14.5, color: colors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: prefixIcon,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// NeumorphicStatusBadge
// -----------------------------------------------------------------------------

/// Tactile status pill badge with icon, label, and high-contrast semantics.
class NeumorphicStatusBadge extends StatelessWidget {
  const NeumorphicStatusBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.tone,
    this.dense = false,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final LLTone tone;
  final bool dense;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = tone.resolve(context);
    final brightness = Theme.of(context).brightness;

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? LLSpacing.sm : 10,
        vertical: dense ? 3 : 5.5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(LLRadius.pill),
        border: Border.all(color: fg.withValues(alpha: 0.45)),
        boxShadow: LLNeumorphism.shadows(
          brightness: brightness,
          elevation: NeumorphicElevationLevel.low,
          darkShadowColor: fg.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 11 : LLIconSize.badge, color: fg),
          const SizedBox(width: LLSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: dense ? 10 : 11,
                fontWeight: FontWeight.bold,
                color: fg,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: badge);
    }
    return badge;
  }
}

// -----------------------------------------------------------------------------
// NeumorphicNavigationItem
// -----------------------------------------------------------------------------

/// Tactile navigation item supporting selected / pressed states.
class NeumorphicNavigationItem extends StatelessWidget {
  const NeumorphicNavigationItem({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brightness = Theme.of(context).brightness;

    final activeColor = colors.primary;

    return Semantics(
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LLRadius.control),
        child: AnimatedContainer(
          duration: LLMotion.fast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: isSelected
              ? BoxDecoration(
                  color: colors.elevatedSurface,
                  borderRadius: BorderRadius.circular(LLRadius.control),
                  border: Border.all(color: activeColor.withValues(alpha: 0.3)),
                  gradient: LLNeumorphism.concaveGradient(
                    brightness: brightness,
                    baseColor: colors.elevatedSurface,
                  ),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? (selectedIcon ?? icon) : icon,
                    size: 22,
                    color: isSelected ? activeColor : colors.textSecondary,
                  ),
                  if (badgeCount != null && badgeCount! > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: colors.critical,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          badgeCount! > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? activeColor : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// NeumorphicDialog
// -----------------------------------------------------------------------------

/// Tactile modal dialog with high Neumorphic elevation, rounded sheet radius,
/// and accessible title/actions layout.
class NeumorphicDialog extends StatelessWidget {
  const NeumorphicDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.icon,
    this.tone,
    this.maxWidth = 460,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final IconData? icon;
  final LLTone? tone;
  final double maxWidth;

  static Future<T?> show<T>({
    required BuildContext context,
    Widget? title,
    Widget? content,
    List<Widget>? actions,
    IconData? icon,
    LLTone? tone,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => NeumorphicDialog(
        title: title,
        content: content,
        actions: actions,
        icon: icon,
        tone: tone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brightness = Theme.of(context).brightness;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(LLRadius.sheet),
            border: Border.all(color: colors.border),
            boxShadow: LLNeumorphism.shadows(
              brightness: brightness,
              elevation: NeumorphicElevationLevel.high,
            ),
            gradient: LLNeumorphism.convexGradient(
              brightness: brightness,
              baseColor: colors.surface,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (icon != null) ...[
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: tone != null
                            ? tone!.resolve(context).$2
                            : colors.primaryContainer,
                        shape: BoxShape.circle,
                        boxShadow: LLNeumorphism.shadows(
                          brightness: brightness,
                          elevation: NeumorphicElevationLevel.low,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 26,
                        color: tone != null
                            ? tone!.resolve(context).$1
                            : colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (title != null) ...[
                  DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    child: title!,
                  ),
                  const SizedBox(height: 12),
                ],
                if (content != null) ...[
                  DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                      height: 1.45,
                    ),
                    child: content!,
                  ),
                  const SizedBox(height: 20),
                ],
                if (actions != null && actions!.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (var i = 0; i < actions!.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        actions![i],
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
