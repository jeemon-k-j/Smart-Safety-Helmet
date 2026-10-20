import 'package:flutter/material.dart';

import '../../services/accident/accident_alert_controller.dart';
import '../../theme/app_theme.dart';

/// Countdown / cancel UI for false-alert cancellation.
class AccidentAlertPanel extends StatelessWidget {
  const AccidentAlertPanel({super.key, required this.controller});

  final AccidentAlertController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.phase == AccidentAlertPhase.idle) {
          return const SizedBox.shrink();
        }

        final tone = switch (controller.phase) {
          AccidentAlertPhase.cancelled => SafetyTone.safe,
          AccidentAlertPhase.sent => SafetyTone.warning,
          AccidentAlertPhase.failed => SafetyTone.warning,
          _ => SafetyTone.danger,
        };
        final color = AppTheme.toneColor(tone);
        final soft = AppTheme.toneSoft(tone);

        return Container(
          decoration: BoxDecoration(
            color: soft,
            borderRadius: BorderRadius.circular(AppMetrics.radius),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.warning_amber_rounded, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Accident alert',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                    ),
                  ),
                  if (controller.phase == AccidentAlertPhase.countdown)
                    Text(
                      _formatRemaining(controller.remaining),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: color,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                controller.statusMessage ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      color: AppColors.brand,
                    ),
              ),
              if (controller.lastMapsUrl != null) ...[
                const SizedBox(height: 10),
                SelectableText(
                  controller.lastMapsUrl!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                ),
              ],
              if (controller.canCancel) ...[
                const SizedBox(height: 14),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: color,
                  ),
                  onPressed: controller.cancel,
                  child: const Text('Cancel false alert'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Emergency emails are sent when the countdown reaches zero.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.unknown,
                      ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatRemaining(Duration value) {
    final total = value.inSeconds.clamp(0, 999);
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
