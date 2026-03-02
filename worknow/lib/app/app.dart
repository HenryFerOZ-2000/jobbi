import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/fcm_service.dart';
import 'router.dart';
import 'auth_gate.dart';

class WorkNowApp extends StatefulWidget {
  const WorkNowApp({super.key});

  @override
  State<WorkNowApp> createState() => _WorkNowAppState();
}

class _WorkNowAppState extends State<WorkNowApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Assign navigator key to FCM Service for background navigation
    FCMService.navigatorKey = _navigatorKey;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'WorkNow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}

