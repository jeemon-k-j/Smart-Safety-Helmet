import 'package:flutter/material.dart';

import 'app_dependencies.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_shell.dart';
import 'theme/app_theme.dart';

class SmartSafetyHelmetApp extends StatefulWidget {
  const SmartSafetyHelmetApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<SmartSafetyHelmetApp> createState() => _SmartSafetyHelmetAppState();
}

class _SmartSafetyHelmetAppState extends State<SmartSafetyHelmetApp> {
  @override
  void dispose() {
    widget.dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deps = widget.dependencies;
    return MaterialApp(
      title: 'Smart Safety Helmet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: StreamBuilder(
        stream: deps.authService.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData &&
              deps.authService.currentUser == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final user = snapshot.data ?? deps.authService.currentUser;
          if (user == null) {
            return LoginScreen(
              authService: deps.authService,
              firebaseReady: deps.firebaseReady,
            );
          }
          return HomeShell(
            authService: deps.authService,
            deviceRepository: deps.deviceRepository,
            accidentRepository: deps.accidentRepository,
            contactRepository: deps.contactRepository,
            alertController: deps.alertController,
            firebaseReady: deps.firebaseReady,
          );
        },
      ),
    );
  }
}
