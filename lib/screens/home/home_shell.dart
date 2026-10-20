import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/accident_event.dart';
import '../../repositories/accident_repository.dart';
import '../../repositories/device_repository.dart';
import '../../repositories/emergency_contact_repository.dart';
import '../../services/accident/accident_alert_controller.dart';
import '../../services/auth/auth_service.dart';
import '../alerts/alerts_screen.dart';
import '../dashboard/dashboard_screen.dart';

/// Authenticated shell with Safety and Alerts destinations only.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.authService,
    required this.deviceRepository,
    required this.accidentRepository,
    required this.contactRepository,
    required this.alertController,
    required this.firebaseReady,
  });

  final AuthService authService;
  final DeviceRepository deviceRepository;
  final AccidentRepository accidentRepository;
  final EmergencyContactRepository contactRepository;
  final AccidentAlertController alertController;
  final bool firebaseReady;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
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
    final titles = <String>['Safety', 'Alerts'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: widget.authService.signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(
            deviceRepository: widget.deviceRepository,
            accidentRepository: widget.accidentRepository,
            alertController: widget.alertController,
            firebaseReady: widget.firebaseReady,
          ),
          AlertsScreen(
            alertController: widget.alertController,
            contactRepository: widget.contactRepository,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: 'Safety',
          ),
          NavigationDestination(
            icon: Icon(Icons.notification_important_outlined),
            selectedIcon: Icon(Icons.notification_important),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}
