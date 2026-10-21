import 'package:flutter/material.dart';

import '../../services/accident/accident_alert_controller.dart';
import '../../theme/app_theme.dart';
import '../accident/accident_alert_panel.dart';

/// Accident alert workflow and notification status.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({
    super.key,
    required this.alertController,
  });

  final AccidentAlertController alertController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppMetrics.page,
        AppMetrics.page,
        AppMetrics.page,
        AppMetrics.page + 24,
      ),
      children: [
        Text(
          'Alerts',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.brand,
                letterSpacing: -0.3,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Cancel false accident alerts during the countdown. Emergency email '
          'is sent only for accidents after the countdown ends without cancel.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.unknown,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 18),
        ListenableBuilder(
          listenable: alertController,
          builder: (context, _) {
            if (alertController.phase == AccidentAlertPhase.idle) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.safeSoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.safe,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'No active accident alert. When the helmet reports an '
                          'accident, the countdown and cancel action appear here.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.4,
                                    color: AppColors.brand,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return AccidentAlertPanel(controller: alertController);
          },
        ),
        const SizedBox(height: 28),
        Text(
          'Notification status',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.brand,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Accident emergency email uses a fixed recipient configured on the '
          'email bridge. Helmet clip, alcohol, drowsiness, and ignition updates '
          'never send email.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.unknown,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 14),
        ListenableBuilder(
          listenable: alertController,
          builder: (context, _) {
            final phase = alertController.phase;
            final message = switch (phase) {
              AccidentAlertPhase.idle =>
                'Waiting for an accident alert from the helmet.',
              AccidentAlertPhase.countdown =>
                alertController.statusMessage ?? 'Accident countdown in progress.',
              AccidentAlertPhase.locating =>
                alertController.statusMessage ?? 'Obtaining phone location…',
              AccidentAlertPhase.notifying =>
                alertController.statusMessage ?? 'Sending emergency email…',
              AccidentAlertPhase.sent =>
                alertController.statusMessage ?? 'Emergency email sent.',
              AccidentAlertPhase.cancelled =>
                alertController.statusMessage ??
                    'Alert cancelled. Emergency email was not sent.',
              AccidentAlertPhase.failed =>
                alertController.statusMessage ??
                    'Emergency email could not be sent.',
            };
            final tone = switch (phase) {
              AccidentAlertPhase.sent ||
              AccidentAlertPhase.cancelled ||
              AccidentAlertPhase.idle =>
                AppColors.safe,
              AccidentAlertPhase.failed => AppColors.warning,
              _ => AppColors.danger,
            };
            final soft = switch (phase) {
              AccidentAlertPhase.sent ||
              AccidentAlertPhase.cancelled ||
              AccidentAlertPhase.idle =>
                AppColors.safeSoft,
              AccidentAlertPhase.failed => AppColors.warningSoft,
              _ => AppColors.dangerSoft,
            };
            return Container(
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(AppMetrics.radius),
                border: Border.all(color: tone.withValues(alpha: 0.28)),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    phase == AccidentAlertPhase.sent
                        ? Icons.mark_email_read_outlined
                        : phase == AccidentAlertPhase.failed
                            ? Icons.error_outline
                            : Icons.info_outline,
                    color: tone,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                            color: AppColors.brand,
                          ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
