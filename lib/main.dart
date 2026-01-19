import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:little_emmi/Providers/block_provider.dart';
import 'Services/bluetooth_manager.dart';

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// --- SCREENS IMPORTS ---
import 'Screens/BodyLayout/body_layout.dart';
import 'Screens/TopBar/top_bar.dart';
import 'package:camera_windows/camera_windows.dart';

// Auth & Launch & Activation
import 'package:little_emmi/Screens/robot_launch_screen.dart';
import 'package:little_emmi/Screens/Auth/login_screen.dart';
import 'package:little_emmi/Screens/Auth/activation_screen.dart';

// Dashboards
import 'package:little_emmi/Screens/Dashboard/dashboard_screen.dart';
import 'package:little_emmi/Screens/Auth/student_dashboard.dart';
import 'package:little_emmi/Screens/Auth/teacher_dashboard.dart';

// MIT
import 'package:little_emmi/Screens/MIT/mit_dashboard_screen.dart';
import 'package:little_emmi/Screens/MIT/mit_login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SharedPreferences prefs = await SharedPreferences.getInstance();
  // If key doesn't exist, default to false (require activation)
  bool isActivated = prefs.getBool('is_activated') ?? false;
  CameraWindows.registerWith();

  runApp(QubiQApp(isActivated: isActivated));
}

class QubiQApp extends StatefulWidget {
  final bool isActivated;

  // ✅ FIX: Default to false if something goes wrong during reload
  const QubiQApp({super.key, this.isActivated = false});

  @override
  State<QubiQApp> createState() => _QubiQAppState();
}

class _QubiQAppState extends State<QubiQApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BlockProvider()),
        ChangeNotifierProvider(create: (_) => BluetoothManager()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'QubiQAI',
        theme: ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.indigo,
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          useMaterial3: true,
        ),

        // Logic: Check widget.isActivated safely
        initialRoute: widget.isActivated ? '/' : '/activation',

        routes: {
          '/activation': (context) => const ActivationScreen(),
          '/': (context) => const RobotLaunchScreen(),
          '/login': (context) => const LittleEmmiLoginScreen(),
          '/auth/login': (context) => const LittleEmmiLoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/auth/student': (context) => const StudentDashboardScreen(),
          '/auth/teacher': (context) => const TeacherDashboardScreen(),
          '/mit/login': (context) => const MitLoginScreen(),
          '/mit/dashboard': (context) => const MitDashboardScreen(),
          '/app/robot_workspace': (context) => const Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  TopBar(),
                  Expanded(child: BodyLayout()),
                ],
              ),
            ),
          ),
        },
      ),
    );
  }
}