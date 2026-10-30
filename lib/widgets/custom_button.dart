import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Tombol utama EventKuy — blok tinta datar, sudut kecil, tanpa shadow.
/// [outline] = true untuk varian sekunder (putih ber-border).
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outline;
  final bool loading;
  final IconData? icon;
  final double? height;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.outline = false,
    this.loading = false,
    this.icon,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = loading || onPressed == null;

    if (outline) {
      return OutlinedButton(
        onPressed: disabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, height ?? 48),
          side: const BorderSide(color: AppTheme.border, width: 1),
        ),
        child: _content(
          color: AppTheme.ink,
          progressColor: AppTheme.ink,
        ),
      );
    }

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Container(
        height: height ?? 48,
        decoration: BoxDecoration(
          color: AppTheme.ink,
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : onPressed,
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            child: Center(
              child: _content(
                color: Colors.white,
                progressColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content({required Color color, required Color progressColor}) {
    if (loading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: progressColor,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }
}
