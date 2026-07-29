import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'features/auth/presentation/login_screen.dart';
import 'features/leaves/presentation/role_selection_screen.dart';
import 'features/leaves/presentation/leave_request_screen.dart';
import 'features/leaves/presentation/manager_dashboard.dart';
import 'features/leaves/presentation/rh_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion des Congés',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3F51B5)),
        useMaterial3: true,
      ),
      // ➔ Démarre directement sur la sélection des 3 espaces
      initialRoute: '/role_selection',
      routes: {
        '/': (context) => const RoleSelectionScreen(),
        '/role_selection': (context) => const RoleSelectionScreen(),
        '/login': (context) => const LoginScreen(),
        '/employee': (context) => const LeaveRequestScreen(),
        '/manager': (context) => const ManagerDashboard(),
        '/rh': (context) => const RhDashboard(),
      },
    );
  }
}