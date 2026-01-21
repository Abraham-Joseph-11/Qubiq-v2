import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:little_emmi/Providers/block_provider.dart';
import 'Services/bluetooth_manager.dart';

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// --- SCREENS IMPORTS ---
import 'Screens/BodyLayout/body_layout.dart';
import 'Screens/TopBar/top_bar.dart';
import 'package:camera_windows/camera_windows.dart';

// Import your screens
import 'package:little_emmi/Screens/Auth/login_screen.dart';
import 'package:little_emmi/Screens/Auth/activation_screen.dart';
import 'package:little_emmi/Screens/Dashboard/dashboard_screen.dart';
import 'package:little_emmi/Screens/Auth/student_dashboard.dart';
import 'package:little_emmi/Screens/Auth/teacher_dashboard.dart';
import 'package:little_emmi/Screens/MIT/mit_dashboard_screen.dart';
import 'package:little_emmi/Screens/MIT/mit_login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 🚀 CRITICAL FIX: Start the App INSTANTLY.
  // We moved all 'await' calls to the Splash Screen to kill the black screen.
  runApp(const QubiQApp());
}

class QubiQApp extends StatelessWidget {
  const QubiQApp({super.key});

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
        color: Colors.white,
        theme: ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.indigo,
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          useMaterial3: true,
        ),
        // 🚀 Go straight to Splash Screen
        home: const RobotLaunchScreen(),

        routes: {
          '/activation': (context) => const ActivationScreen(),
          '/login': (context) => const LittleEmmiLoginScreen(),
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

// ------------------------------------------------------------------
// 🚀 SPLASH SCREEN
// ------------------------------------------------------------------
class RobotLaunchScreen extends StatefulWidget {
  const RobotLaunchScreen({super.key});

  @override
  State<RobotLaunchScreen> createState() => _RobotLaunchScreenState();
}

class _RobotLaunchScreenState extends State<RobotLaunchScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Setup Animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)),
    );

    _controller.forward();

    // 2. 🚀 CRITICAL FIX: Use addPostFrameCallback
    // This ensures the logo is drawn to the screen BEFORE we start loading Firebase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      // A. Initialize Firebase (Background)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // B. DESKTOP FORCE LOGOUT (Windows & MacOS)
      // This ensures a clean login state every time the app opens on desktop.
      if (Platform.isWindows || Platform.isMacOS) {
        await FirebaseAuth.instance.signOut();
      }

      // C. Initialize Camera (Windows Check)
      if (Platform.isWindows) {
        try {
          // No 'await' here to prevent blocking if camera is slow
          CameraWindows.registerWith();
        } catch (e) {
          debugPrint("Camera init skipped: $e");
        }
      }

      // D. Load Preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isActivated = prefs.getBool('is_activated') ?? false;

      // E. Wait for Animation (Ensure at least 3 seconds passed)
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      // F. Navigate
      if (isActivated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      } else {
        Navigator.of(context).pushReplacementNamed('/activation');
      }

    } catch (e) {
      debugPrint("Critical Init Error: $e");
      // Safety Net: Go to login if initialization fails
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LittleEmmiLoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF1F5F9)],
          ),
        ),
        child: Center(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Image.asset(
                  'assets/images/qubiq_logo.png',
                  width: 700,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) {
                    return const Icon(Icons.smart_toy_rounded, size: 100, color: Colors.indigo);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// 🚀 AUTH WRAPPER (Handles Auto-Login)
// ------------------------------------------------------------------
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // This StreamBuilder checks the device cache immediately.
    // If a user is found, it loads the dashboard instantly.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const StudentDashboardScreen();
        }
        return const LittleEmmiLoginScreen();
      },
    );
  }
}