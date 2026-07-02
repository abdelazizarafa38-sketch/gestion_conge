import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:leave_app/features/auth/presentation/login_screen.dart';
import 'package:leave_app/features/leaves/presentation/leave_request_screen.dart';
import 'package:leave_app/features/leaves/presentation/manager_dashboard.dart';
import 'package:leave_app/features/leaves/presentation/rh_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseApp.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GLSI Leave Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Écran initial au démarrage de l'application
      initialRoute: '/login',
      // Déclaration de toutes les routes de l'application
      routes: {
        '/login': (context) => const LoginScreen(),
        '/leave_request': (context) => const LeaveRequestScreen(),
        '/manager_dashboard': (context) => const ManagerDashboard(),
        '/rh_dashboard': (context) => const RhDashboard(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}