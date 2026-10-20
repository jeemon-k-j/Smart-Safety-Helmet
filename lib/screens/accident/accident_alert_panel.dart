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

        final isUrgent = controller.phase == AccidentAlertPhase.countdown ||
            controller.phase == AccidentAlertPhase.locating ||
            controller.phase == AccidentAlertPhase.notifying;
        final color = switch (controller.phase) {
          AccidentAlertPhase.cancelled => AppColors.safe,
          AccidentAlertPhase.sent => AppColors.accent,
          AccidentAlertPhase.failed => AppColors.warning,
          _ => AppColors.emergency,
        };

        return Card(
          color: color.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: color),
                    const SizedBox(width: 8),
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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(controller.statusMessage ?? ''),
                if (controller.lastMapsUrl != null) ...[
                  const SizedBox(height: 8),
                  SelectableText(
                    controller.lastMapsUrl!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (controller.canCancel) ...[
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: controller.cancel,
                    child: const Text('Cancel false alert'),
                  ),
                ],
                if (isUrgent && controller.phase == AccidentAlertPhase.countdown)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Emergency emails are sent when the countdown reaches zero.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
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
