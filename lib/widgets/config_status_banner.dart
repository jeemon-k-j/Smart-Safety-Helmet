import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Compact notice when cloud services are unavailable.
class ConfigStatusBanner extends StatelessWidget {
  const ConfigStatusBanner({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    if (firebaseReady) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppMetrics.radiusSm),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cloud services are unavailable. Account and alert settings are '
              'stored on this device until a cloud connection is established.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.35,
                    color: AppColors.brand,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
