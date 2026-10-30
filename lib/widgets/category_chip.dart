import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Chip filter kategori — dipakai di Jelajahi.
/// Sudut kecil (bukan pill), dan state aktif memakai tinta pekat.
class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 38),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.ink : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          border: Border.all(
            color: selected ? AppTheme.ink : AppTheme.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : AppTheme.muted,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  color: selected ? Colors.white : AppTheme.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab kategori di Beranda: label teks dengan garis bawah saat aktif.
///
/// Dulu tiap kategori berupa kotak ikon berwarna + label — pola kartu ikon
/// yang membuat baris ini terlihat seperti template.
class CategoryIconItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryIconItem({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.headingFont,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: -0.1,
              color: selected ? AppTheme.ink : AppTheme.muted,
            ),
          ),
          const SizedBox(height: 7),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 2,
            width: selected ? 22 : 0,
            decoration: BoxDecoration(
              color: selected ? AppTheme.violet : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}
