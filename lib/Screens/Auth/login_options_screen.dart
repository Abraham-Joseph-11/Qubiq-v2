import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:uuid/uuid.dart';

// VVV --- FIX: ADD ALL NECESSARY IMPORTS --- VVV
import '../../Models/AdminModels.dart';
import '../../Screens/Admin/super_admin_screen.dart';
import '../../Screens/Admin/institution_admin_screen.dart';
import '../../Screens/Teacher/teacher_dashboard_screen.dart';
import '../../Screens/Student/student_dashboard_screen.dart';
// ^^^ ---------------------------------------- ^^^

// Defines the four user roles
enum UserRole { superAdmin, institution, teacher, student }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _shakeController;

  final MockTeacher _mockTeacher = MockTeacher(
    id: const Uuid().v4(),
    name: 'Mrs. Evans',
    email: 'teacher@school.com',
    gradeLevel: 8,
  );

  final MockTeacher _mockStudent = MockTeacher(
    id: const Uuid().v4(),
    name: 'Student X',
    email: 'student@school.com',
    gradeLevel: 8, // Student is assigned to Grade 8
  );

  // --- MOCK AUTHENTICATION DATA ---
  final Map<String, String> _mockCredentials = {
    'admin@emmi.com': 'admin123', // SuperAdmin
    'institution@school.com': 'inst123', // Institution
    'teacher@school.com': 'teacher123', // Teacher
    'student@school.com': 'student123', // Student
  };

  UserRole _getRoleFromUsername(String username) {
    if (username.contains('admin')) return UserRole.superAdmin;
    if (username.contains('institution')) return UserRole.institution;
    if (username.contains('teacher')) return UserRole.teacher;
    if (username.contains('student')) return UserRole.student;
    return UserRole.student;
  }

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      _shakeController.forward(from: 0);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    await Future.delayed(const Duration(milliseconds: 500));

    if (_mockCredentials.containsKey(username) &&
        _mockCredentials[username] == password) {

      final role = _getRoleFromUsername(username);

      if (mounted) {
        Widget destination;

        if (role == UserRole.superAdmin) {
          destination = const SuperAdminScreen();
        } else if (role == UserRole.institution) {
          destination = const InstitutionAdminScreen();
        } else if (role == UserRole.teacher) {
          destination = TeacherDashboardScreen(teacher: _mockTeacher);
        } else {
          destination = StudentDashboardScreen(teacher: _mockStudent);
        }

        // Navigate and clear the history
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => destination),
              (Route<dynamic> route) => false,
        );
      }
    } else {
      _shakeController.forward(from: 0);
      setState(() {
        _errorMessage = 'Invalid username or password. Try a mock credential.';
      });
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // --- BUILDER WIDGETS ---

  InputDecoration _buildInputDecoration({required String label, required IconData icon}) {
    // Styling taken from login_screen.dart
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400, width: 2)),
    );
  }

  Widget _buildLoginButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _handleLogin,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.teal.withOpacity(0.5),
        highlightColor: Colors.teal.withOpacity(0.3),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(colors: [Color(0xFF00897B), Color(0xFF00695C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('LOGIN', style: GoogleFonts.poppins(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginSection() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: Colors.white54)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text("Or continue with", style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8))),
            ),
            const Expanded(child: Divider(color: Colors.white54)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // VVV --- NEW APPS BUTTON (Dashboard Shortcut) --- VVV
            _SocialButton(
              icon: Icons.apps_outlined,
              tooltip: "App Dashboard",
              // Navigate directly to the dashboard, removing the login page
              onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
            ),
            // ^^^ ------------------------------------------- ^^^
            const SizedBox(width: 20),
            _SocialButton(icon: FontAwesomeIcons.google, onTap: () {}, tooltip: "Sign in with Google"),
            const SizedBox(width: 20),
            _SocialButton(icon: FontAwesomeIcons.apple, onTap: () {}, tooltip: "Sign in with Apple"),
            const SizedBox(width: 20),
            _SocialButton(icon: FontAwesomeIcons.facebookF, onTap: () {}, tooltip: "Sign in with Facebook"),
          ],
        ),
      ],
    );
  }

  // --- MAIN BUILD METHOD (Unchanged) ---
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Scaffold(
      body: Stack(
        children: [
          const ParallaxBubbleBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Animate(
                controller: _shakeController,
                effects: const [ShakeEffect(hz: 4, duration: Duration(milliseconds: 300), rotation: 0.02)],
                child: GlassmorphismContainer(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.child_care, size: 50, color: Color(0xFF00796B)),
                        ).animate().scale(delay: 200.ms, duration: 700.ms, curve: Curves.elasticOut),
                        const SizedBox(height: 20),
                        Text('Welcome Back to Little Emmi', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text('Please sign in to continue', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70)),
                        const SizedBox(height: 32),

                        // --- Username Field ---
                        TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration(label: 'Email / Username', icon: Icons.person_outline),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => (value == null || value.isEmpty) ? 'Please enter a username' : null,
                        ),
                        const SizedBox(height: 16),

                        // --- Password Field ---
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration(label: 'Password', icon: Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                          validator: (value) => (value == null || value.isEmpty) ? 'Please enter your password' : null,
                          onFieldSubmitted: (_) => _handleLogin(),
                        ),

                        const SizedBox(height: 20),

                        // --- Error Message ---
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 15.0),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w600),
                            ),
                          ),

                        _buildLoginButton(),
                        const SizedBox(height: 24),
                        _buildSocialLoginSection(),
                      ].animate(interval: 80.ms).fadeIn(duration: 400.ms).slideY(begin: 0.5, curve: Curves.easeOutCubic),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- SUPPORTING WIDGETS (Updated to accept tooltip) ---

class ParallaxBubbleBackground extends StatefulWidget {
  const ParallaxBubbleBackground({super.key});

  @override
  State<ParallaxBubbleBackground> createState() => _ParallaxBubbleBackgroundState();
}

class _ParallaxBubbleBackgroundState extends State<ParallaxBubbleBackground> {
  double x = 0;
  double y = 0;

  @override
  void initState() {
    super.initState();
    accelerometerEvents.listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          x = (event.x * 0.1).clamp(-0.4, 0.4);
          y = (event.y * 0.1).clamp(-0.4, 0.4);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF003932), Color(0xFF00695C), Color(0xFF00796B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          _Bubble(x: x, y: y, size: 250, color: Colors.tealAccent, speed: 1.5, alignment: const Alignment(-0.8, -0.8)),
          _Bubble(x: x, y: y, size: 150, color: Colors.cyanAccent, speed: 0.8, alignment: const Alignment(0.7, -0.6)),
          _Bubble(x: x, y: y, size: 350, color: Colors.lightGreenAccent, speed: 2.2, alignment: const Alignment(0.6, 0.9)),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
    required this.alignment,
  });

  final double x;
  final double y;
  final double size;
  final Color color;
  final double speed;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedAlign(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: alignment - Alignment(x * speed, y * speed),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.05),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 80, spreadRadius: 20)],
        ),
      ),
    );
  }
}

class GlassmorphismContainer extends StatelessWidget {
  final Widget child;
  const GlassmorphismContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _SocialButton({required this.icon, required this.onTap, this.tooltip = ''});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white.withOpacity(0.15),
          child: FaIcon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}