import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StatusTile extends StatelessWidget {
  const StatusTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.tone,
    this.subtitle,
    this.badgeLabel,
  });

  final String title;
  final String value;
  final IconData icon;
  final SafetyTone tone;
  final String? subtitle;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.toneColor(tone);
    final soft = AppTheme.toneSoft(tone);
    final label = badgeLabel ?? switch (tone) {
          SafetyTone.safe => 'Safe',
          SafetyTone.warning => 'Warning',
          SafetyTone.danger => 'Danger',
          SafetyTone.unknown => 'Unknown',
        };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppColors.unknown,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: soft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: color,
                          height: 1.2,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.unknown,
                            height: 1.35,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
