import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/accident_event.dart';
import '../../models/device_status.dart';
import '../../repositories/accident_repository.dart';
import '../../repositories/device_repository.dart';
import '../../repositories/emergency_contact_repository.dart';
import '../../services/accident/accident_alert_controller.dart';
import '../../services/auth/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_tile.dart';
import '../accident/accident_alert_panel.dart';
import '../contacts/emergency_contacts_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.authService,
    required this.deviceRepository,
    required this.accidentRepository,
    required this.contactRepository,
    required this.alertController,
  });

  final AuthService authService;
  final DeviceRepository deviceRepository;
  final AccidentRepository accidentRepository;
  final EmergencyContactRepository contactRepository;
  final AccidentAlertController alertController;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  StreamSubscription<AccidentEvent>? _accidentSub;

  @override
  void initState() {
    super.initState();
    _accidentSub = widget.accidentRepository.watchAccident().listen((event) {
      unawaited(widget.alertController.onAccidentUpdate(event));
    });
  }

  @override
  void dispose() {
    unawaited(_accidentSub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Safety Helmet'),
        actions: [
          IconButton(
            tooltip: 'Emergency contacts',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => EmergencyContactsScreen(
                    repository: widget.contactRepository,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.contacts_outlined),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: widget.authService.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<DeviceStatus>(
        stream: widget.deviceRepository.watchStatus(),
        builder: (context, snapshot) {
          final status = snapshot.data ?? DeviceStatus.empty;
          return ListView(
            padding: const EdgeInsets.all(AppMetrics.page),
            children: [
              Text(
                'Live device status',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.brand,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Device: ${widget.deviceRepository.deviceId}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              AccidentAlertPanel(controller: widget.alertController),
              const SizedBox(height: 12),
              StatusTile(
                title: 'Helmet',
                value: status.helmetClipped ? 'Clipped / worn' : 'Not clipped',
                icon: Icons.sports_motorsports,
                ok: status.helmetClipped,
                subtitle: status.helmetClipped
                    ? 'Ignition may proceed if alcohol is clear'
                    : 'Ignition blocked until helmet is clipped',
              ),
              const SizedBox(height: AppMetrics.gap),
              StatusTile(
                title: 'Alcohol',
                value: status.alcoholDetected ? 'Detected' : 'Clear',
                icon: Icons.local_bar_outlined,
                ok: !status.alcoholDetected,
                subtitle: status.alcoholDetected
                    ? 'Ignition blocked by alcohol sensor'
                    : 'No alcohol detected',
              ),
              const SizedBox(height: AppMetrics.gap),
              StatusTile(
                title: 'Ignition',
                value: status.ignitionActive
                    ? 'Active'
                    : (status.ignitionAllowed ? 'Allowed (idle)' : 'Blocked'),
                icon: Icons.key,
                ok: status.ignitionAllowed,
                subtitle:
                    'Controlled on ESP32 from helmet + alcohol (offline-safe)',
              ),
              const SizedBox(height: AppMetrics.gap),
              StatusTile(
                title: 'Drowsiness',
                value: status.drowsy ? 'Drowsy — warning active' : 'Alert',
                icon: Icons.bedtime_outlined,
                ok: !status.drowsy,
                subtitle: status.warningActive
                    ? 'LED / buzzer warning active on helmet'
                    : 'No local warning',
              ),
              const SizedBox(height: AppMetrics.gap),
              StreamBuilder<AccidentEvent>(
                stream: widget.accidentRepository.watchAccident(),
                builder: (context, accidentSnap) {
                  final accident = accidentSnap.data;
                  final active = accident?.active == true;
                  return StatusTile(
                    title: 'Accident',
                    value: active
                        ? 'Active (${accident!.severity.name})'
                        : (accident?.cancelled == true
                            ? 'Cancelled'
                            : 'None'),
                    icon: Icons.car_crash_outlined,
                    ok: !active,
                    subtitle: accident?.eventId.isNotEmpty == true
                        ? 'Event: ${accident!.eventId}'
                        : 'Waiting for ESP32 accident updates',
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
