import 'package:flutter/material.dart';

import '../../repositories/emergency_contact_repository.dart';
import '../../services/accident/accident_alert_controller.dart';
import '../../theme/app_theme.dart';
import '../accident/accident_alert_panel.dart';
import 'emergency_recipients_section.dart';

/// Accident alert workflow and emergency email recipients.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({
    super.key,
    required this.alertController,
    required this.contactRepository,
  });

  final AccidentAlertController alertController;
  final EmergencyContactRepository contactRepository;

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
          'Cancel false accident alerts during the countdown, and manage who '
          'receives emergency emails.',
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
                          'No active accident alert. When ESP32 reports an '
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
        EmergencyRecipientsSection(repository: contactRepository),
      ],
    );
  }
}
