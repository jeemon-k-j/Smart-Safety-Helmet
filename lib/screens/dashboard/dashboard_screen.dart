import 'package:flutter/material.dart';

import '../../models/accident_event.dart';
import '../../models/device_status.dart';
import '../../repositories/accident_repository.dart';
import '../../repositories/device_repository.dart';
import '../../services/accident/accident_alert_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/config_status_banner.dart';
import '../../widgets/status_tile.dart';
import '../accident/accident_alert_panel.dart';

/// Presentation model for the Home Accident [StatusTile].
class HomeAccidentStatusPresentation {
  const HomeAccidentStatusPresentation({
    required this.tone,
    required this.value,
    required this.subtitle,
  });

  final SafetyTone tone;
  final String value;
  final String subtitle;
}

/// Maps RTDB accident state to Home tile copy.
///
/// Live warnings only for [AccidentEvent.isActionable]. Cancelled / resolved /
/// inactive events are Clear (safe), never technical event IDs.
HomeAccidentStatusPresentation describeHomeAccidentStatus(
  AccidentEvent? accident,
) {
  if (accident == null || accident.eventId.trim().isEmpty) {
    return const HomeAccidentStatusPresentation(
      tone: SafetyTone.unknown,
      value: 'Unknown',
      subtitle: 'No accident updates received yet',
    );
  }

  if (accident.isActionable) {
    final detected = accident.detectedAt;
    return HomeAccidentStatusPresentation(
      tone: SafetyTone.danger,
      value: 'Active (${accident.severity.name})',
      subtitle: detected == null
          ? 'Accident in progress. Use Alerts to cancel if needed.'
          : 'Detected ${formatDateTimeIst(detected)}. '
              'Use Alerts to cancel if needed.',
    );
  }

  final detected = accident.detectedAt;
  final when = detected == null ? null : formatDateTimeIst(detected);
  if (accident.cancelled) {
    return HomeAccidentStatusPresentation(
      tone: SafetyTone.safe,
      value: 'Clear',
      subtitle: when == null
          ? 'Last alert was cancelled. Details are on Alerts.'
          : 'Last alert cancelled · $when',
    );
  }
  if (accident.notificationSent) {
    return HomeAccidentStatusPresentation(
      tone: SafetyTone.safe,
      value: 'Clear',
      subtitle: when == null
          ? 'Last alert was resolved. Details are on Alerts.'
          : 'Last alert resolved · $when',
    );
  }
  return HomeAccidentStatusPresentation(
    tone: SafetyTone.safe,
    value: 'Clear',
    subtitle: when == null
        ? 'No active accident'
        : 'No active accident · last update $when',
  );
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.deviceRepository,
    required this.accidentRepository,
    required this.alertController,
    required this.firebaseReady,
  });

  final DeviceRepository deviceRepository;
  final AccidentRepository accidentRepository;
  final AccidentAlertController alertController;
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DeviceStatus>(
      stream: deviceRepository.watchStatus(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.all(AppMetrics.page),
            children: [
              ConfigStatusBanner(firebaseReady: firebaseReady),
              const SizedBox(height: 14),
              _DataMessageCard(
                tone: SafetyTone.warning,
                title: 'Status unavailable',
                message:
                    'Could not load helmet status. Safety detection continues '
                    'on the helmet; values will appear when the connection '
                    'is restored.',
              ),
            ],
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final status = snapshot.data ?? DeviceStatus.unavailable;
        final overall = _overallTone(status);

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppMetrics.page,
            AppMetrics.page,
            AppMetrics.page,
            AppMetrics.page + 24,
          ),
          children: [
            _HeroHeader(
              deviceId: deviceRepository.deviceId,
              tone: overall,
              summary: _overallSummary(status),
            ),
            const SizedBox(height: 14),
            ConfigStatusBanner(firebaseReady: firebaseReady),
            const SizedBox(height: 14),
            AccidentAlertPanel(controller: alertController),
            const SizedBox(height: 18),
            Text(
              'Safety status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.brand,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sensor values are reported by the helmet hardware. This app '
              'displays them only.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.unknown,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 12),
            if (!status.isAvailable) ...[
              _DataMessageCard(
                tone: SafetyTone.unknown,
                title: 'No helmet reading yet',
                message:
                    'No status has been received from the helmet. '
                    'Ignition and local warnings remain under hardware control.',
              ),
              const SizedBox(height: AppMetrics.gap),
            ],
            StatusTile(
              title: 'Helmet',
              value: !status.isAvailable
                  ? 'Unknown'
                  : (status.helmetClipped ? 'Clipped / worn' : 'Not clipped'),
              icon: Icons.sports_motorsports,
              tone: !status.isAvailable
                  ? SafetyTone.unknown
                  : (status.helmetClipped ? SafetyTone.safe : SafetyTone.danger),
              subtitle: !status.isAvailable
                  ? 'Helmet clip status is unavailable'
                  : (status.helmetClipped
                      ? 'Ignition may proceed if alcohol is clear'
                      : 'Ignition blocked until helmet is clipped'),
            ),
            const SizedBox(height: AppMetrics.gap),
            StatusTile(
              title: 'Alcohol',
              value: !status.isAvailable
                  ? 'Unknown'
                  : (status.alcoholDetected ? 'Detected' : 'Clear'),
              icon: Icons.local_bar_outlined,
              tone: !status.isAvailable
                  ? SafetyTone.unknown
                  : (status.alcoholDetected
                      ? SafetyTone.danger
                      : SafetyTone.safe),
              subtitle: !status.isAvailable
                  ? 'Alcohol sensor status is unavailable'
                  : (status.alcoholDetected
                      ? 'Ignition blocked by alcohol sensor'
                      : 'No alcohol detected'),
            ),
            const SizedBox(height: AppMetrics.gap),
            StatusTile(
              title: 'Ignition',
              value: !status.isAvailable
                  ? 'Unknown'
                  : (status.ignitionActive
                      ? 'Active'
                      : (status.ignitionAllowed
                          ? 'Allowed (idle)'
                          : 'Blocked')),
              icon: Icons.key_rounded,
              tone: !status.isAvailable
                  ? SafetyTone.unknown
                  : (status.ignitionAllowed
                      ? SafetyTone.safe
                      : SafetyTone.danger),
              subtitle: !status.isAvailable
                  ? 'Ignition status is unavailable'
                  : 'Controlled by helmet and alcohol sensors on the device',
            ),
            const SizedBox(height: AppMetrics.gap),
            StatusTile(
              title: 'Drowsiness',
              value: !status.isAvailable
                  ? 'Unknown'
                  : (status.drowsy ? 'Drowsy — warning active' : 'Alert'),
              icon: Icons.bedtime_outlined,
              tone: !status.isAvailable
                  ? SafetyTone.unknown
                  : (status.drowsy ? SafetyTone.warning : SafetyTone.safe),
              subtitle: !status.isAvailable
                  ? 'Drowsiness status is unavailable'
                  : (status.warningActive
                      ? 'Warning indicators active on the helmet'
                      : 'No local warning'),
            ),
            const SizedBox(height: AppMetrics.gap),
            StreamBuilder<AccidentEvent>(
              stream: accidentRepository.watchAccident(),
              builder: (context, accidentSnap) {
                if (accidentSnap.hasError) {
                  return const StatusTile(
                    title: 'Accident',
                    value: 'Unavailable',
                    icon: Icons.car_crash_outlined,
                    tone: SafetyTone.unknown,
                    subtitle: 'Could not load accident updates',
                  );
                }
                final presentation =
                    describeHomeAccidentStatus(accidentSnap.data);
                return StatusTile(
                  title: 'Accident',
                  value: presentation.value,
                  icon: Icons.car_crash_outlined,
                  tone: presentation.tone,
                  subtitle: presentation.subtitle,
                );
              },
            ),
          ],
        );
      },
    );
  }

  SafetyTone _overallTone(DeviceStatus status) {
    if (!status.isAvailable) {
      return SafetyTone.unknown;
    }
    if (!status.helmetClipped || status.alcoholDetected) {
      return SafetyTone.danger;
    }
    if (status.drowsy || status.warningActive) {
      return SafetyTone.warning;
    }
    if (status.ignitionAllowed) {
      return SafetyTone.safe;
    }
    return SafetyTone.unknown;
  }

  String _overallSummary(DeviceStatus status) {
    if (!status.isAvailable) {
      return 'Helmet status is unavailable';
    }
    if (!status.helmetClipped) {
      return 'Helmet not clipped — ignition held off by hardware';
    }
    if (status.alcoholDetected) {
      return 'Alcohol detected — ignition held off by hardware';
    }
    if (status.drowsy) {
      return 'Drowsiness warning active on the helmet';
    }
    if (status.ignitionAllowed) {
      return 'Safety checks clear for this device';
    }
    return 'Awaiting current helmet sensor readings';
  }
}

class _DataMessageCard extends StatelessWidget {
  const _DataMessageCard({
    required this.tone,
    required this.title,
    required this.message,
  });

  final SafetyTone tone;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.toneColor(tone);
    final soft = AppTheme.toneSoft(tone);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(AppMetrics.radius),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.sensors_off_outlined, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        color: AppColors.brand,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.deviceId,
    required this.tone,
    required this.summary,
  });

  final String deviceId;
  final SafetyTone tone;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.toneColor(tone);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, Color(0xFF124A6B)],
        ),
        borderRadius: BorderRadius.circular(AppMetrics.radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  deviceId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  switch (tone) {
                    SafetyTone.safe => 'Safe',
                    SafetyTone.warning => 'Warning',
                    SafetyTone.danger => 'Danger',
                    SafetyTone.unknown => 'Unknown',
                  },
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Safety overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}
