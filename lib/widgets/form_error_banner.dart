import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Error form tingkat layar. Dibacakan pembaca layar lewat live region,
/// jadi pengguna tidak perlu mencari SnackBar yang cepat hilang.
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.redSoft,
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
          border: Border.all(color: AppTheme.red.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: AppTheme.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
