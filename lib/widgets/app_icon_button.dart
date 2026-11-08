import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Tombol ikon aksesibel dengan target sentuh minimum 48 px.
///
/// Memakai [IconButton] agar mendapatkan semantics, tooltip, fokus keyboard,
/// dan ripple bawaan Material. [selected] dipakai untuk tombol toggle seperti
/// favorit; label dan ikon otomatis berganti saat selected.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final String? selectedLabel;
  final VoidCallback? onPressed;
  final bool selected;
  final double size;
  final double? visualSize;
  final double iconSize;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? selectedBackgroundColor;
  final Color? selectedForegroundColor;
  final Color? borderColor;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.selectedLabel,
    this.onPressed,
    this.selected = false,
    this.size = 48,
    this.visualSize,
    this.iconSize = 20,
    this.backgroundColor,
    this.foregroundColor,
    this.selectedBackgroundColor,
    this.selectedForegroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = selected ? (selectedLabel ?? label) : label;
    final effectiveBackground = selected
        ? (selectedBackgroundColor ?? backgroundColor ?? Colors.white)
        : (backgroundColor ?? Colors.white);
    final effectiveForeground = selected
        ? (selectedForegroundColor ?? foregroundColor ?? AppTheme.coral)
        : (foregroundColor ?? AppTheme.ink);

    final effectiveIcon = selected ? (selectedIcon ?? icon) : icon;

    return Semantics(
      container: true,
      button: true,
      label: effectiveLabel,
      enabled: onPressed != null,
      selected: selected ? true : null,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: visualSize == null
            ? IconButton(
                onPressed: onPressed,
                tooltip: effectiveLabel,
                isSelected: selected,
                icon: Icon(effectiveIcon, size: iconSize),
                style: IconButton.styleFrom(
                  foregroundColor: effectiveForeground,
                  backgroundColor: effectiveBackground,
                  disabledForegroundColor: AppTheme.textFaint,
                  disabledBackgroundColor: backgroundColor ?? Colors.white,
                  fixedSize: Size(size, size),
                  minimumSize: Size(size, size),
                  maximumSize: Size(size, size),
                  padding: EdgeInsets.zero,
                  shape: CircleBorder(
                    side: BorderSide(
                      color: borderColor ?? Colors.transparent,
                    ),
                  ),
                ),
              )
            : SizedBox(
                width: size,
                height: size,
                child: Tooltip(
                  message: effectiveLabel,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onPressed,
                      customBorder: const CircleBorder(),
                      child: Center(
                        child: Container(
                          width: visualSize,
                          height: visualSize,
                          decoration: BoxDecoration(
                            color: effectiveBackground,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: borderColor ?? Colors.transparent,
                            ),
                          ),
                          child: Icon(
                            effectiveIcon,
                            size: iconSize,
                            color: effectiveForeground,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
