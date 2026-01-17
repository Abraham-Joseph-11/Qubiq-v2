import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Dashboards
import 'package:little_emmi/Screens/Dashboard/dashboard_screen.dart';
import 'package:little_emmi/Screens/Auth/student_dashboard.dart';
import 'package:little_emmi/Screens/Auth/teacher_dashboard.dart';
import 'package:little_emmi/Screens/Dashboard/admin_dashboard.dart';
import 'package:little_emmi/Screens/Dashboard/super_admin_dashboard.dart';
import 'package:little_emmi/Screens/robot_launch_screen.dart'; // For Reset

import 'package:little_emmi/Utils/responsive_layout.dart';

class LittleEmmiLoginScreen extends StatefulWidget {
  const LittleEmmiLoginScreen({super.key});

  @override
  State<LittleEmmiLoginScreen> createState() => _LittleEmmiLoginScreenState();
}

class _LittleEmmiLoginScreenState extends State<LittleEmmiLoginScreen> {
  bool _isLogin = true;
  String _selectedRole = 'student';
  final _formKey = GlobalKey<FormState>();

  // Dropdown Values
  String _selectedClass = "1";
  String _selectedSection = "A";

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _schoolIdController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String? _generatedOtp;
  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  // 🔐 EmailJS Config
  final String serviceId = "service_bfu9is8";
  final String templateId = "template_hurkklz";
  final String publicKey = "25m02sQQ9YzU3GnLY";

  // Education Purple Theme
  final Color _accentColor = const Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _otpController.addListener(() {
      if (_isOtpSent) setState(() {});
    });
  }

  Future<void> _deactivateLicense() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if(!mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const RobotLaunchScreen()),
            (route) => false
    );
  }

  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty || _nameController.text.isEmpty) {
      setState(() => _errorMessage = "Please enter Name and Email first.");
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    String code = (Random().nextInt(900000) + 100000).toString();
    _generatedOtp = code;

    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'to_email': _emailController.text,
            'otp': code,
            'user_name': _nameController.text,
            'user_login_email': _emailController.text
          }
        }),
      );

      if (response.statusCode == 200) {
        setState(() { _isOtpSent = true; _isLoading = false; });
      } else {
        setState(() { _isLoading = false; _errorMessage = "Failed to send OTP."; });
      }
    } catch (e) {
      setState(() { _errorMessage = "Connection failed: $e"; _isLoading = false; });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    // Strict Education Checks
    if (!_isLogin) {
      if (!_isOtpSent) { setState(() => _errorMessage = "Verify OTP first."); return; }
      if (_otpController.text.trim() != _generatedOtp) { setState(() => _errorMessage = "Invalid OTP."); return; }

      DocumentSnapshot sCheck = await firestore.collection('schools').doc(_schoolIdController.text.trim()).get();
      if (!sCheck.exists) { setState(() => _errorMessage = "School ID not found."); return; }
    }

    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      if (_isLogin) {
        UserCredential cred = await auth.signInWithEmailAndPassword(
            email: _emailController.text.trim(), password: _passController.text.trim());
        DocumentSnapshot userDoc = await firestore.collection('users').doc(cred.user!.uid).get();

        if (userDoc.exists) {
          String role = userDoc.get('role');
          if (_emailController.text.trim() == "superadmin@qubiq.ai" || role == "super_admin") {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SuperAdminDashboard()));
            return;
          }
          if (userDoc.data().toString().contains('schoolId')) {
            DocumentSnapshot sDoc = await firestore.collection('schools').doc(userDoc.get('schoolId')).get();
            if (sDoc.exists && sDoc.get('status') == 'blocked') {
              await auth.signOut();
              setState(() { _isLoading = false; _errorMessage = "Access Blocked by School Admin."; });
              return;
            }
          }
          _navigateByRole(role);
        }
      } else {
        // REGISTER
        UserCredential userCredential = await auth.createUserWithEmailAndPassword(
            email: _emailController.text.trim(), password: _passController.text.trim());

        String role = _selectedRole;

        await firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': role,
          'phone': _phoneController.text.trim(),
          'schoolId': _schoolIdController.text.trim(),
          'class': role == 'student' ? "$_selectedClass-$_selectedSection" : null,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _navigateByRole(role);
      }
    } catch (e) { setState(() { _errorMessage = e.toString(); _isLoading = false; }); }
  }

  void _navigateByRole(String role) {
    if (!mounted) return;
    Widget next = (role == 'admin') ? const AdminDashboardScreen() : (role == 'teacher' ? const TeacherDashboardScreen() : (role == 'student' ? const StudentDashboardScreen() : const DashboardScreen()));
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => next));
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    bool requiresOtp = !_isLogin;

    // ✅ RESTORED SPLIT LAYOUT
    return Scaffold(
      body: ResponsiveLayout(
        desktopBody: Row(
          children: [
            Expanded(flex: 2, child: _buildEducationBranding(isMobile)),
            Expanded(flex: 3, child: Container(color: Colors.white, child: Center(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40), child: _buildForm(requiresOtp))))),
          ],
        ),
        mobileBody: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 250, width: double.infinity, child: _buildEducationBranding(true)),
              Container(color: Colors.white, padding: const EdgeInsets.all(24), child: _buildForm(requiresOtp)),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ RESTORED BRANDING PANEL
  Widget _buildEducationBranding(bool isMobile) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[50], border: Border(right: BorderSide(color: Colors.grey.shade300))),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: GridPainter(color: _accentColor.withOpacity(0.05)))),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/qubiq_logo.png', width: isMobile ? 300 : 250),
                  const SizedBox(height: 30),
                  Text("EDUCATION\nPORTAL", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4.0, color: Colors.blueGrey[900])),
                  const SizedBox(height: 20),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: _accentColor, borderRadius: BorderRadius.circular(2))),
                ],
              ),
            ),
          ),
          Positioned(
              bottom: 20,
              left: 20,
              child: TextButton.icon(
                  onPressed: _deactivateLicense,
                  icon: Icon(Icons.logout, size: 14, color: Colors.grey[400]),
                  label: Text("Deactivate License", style: TextStyle(color: Colors.grey[400], fontSize: 10))
              )
          )
        ],
      ),
    );
  }

  Widget _buildForm(bool requiresOtp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_isLogin ? "Welcome back" : "Create account", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isLogin) ...[
                Row(children: [
                  Expanded(child: _buildTextField(_nameController, "Full Name", Icons.person_outline)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildTextField(_phoneController, "Phone Number", Icons.phone_outlined, isNum: true)),
                ]),
                const SizedBox(height: 20),
                _buildRoleSelector(),
                const SizedBox(height: 20),
                _buildTextField(_schoolIdController, "School ID", Icons.badge_outlined, isNum: true),
                const SizedBox(height: 20),
                if (_selectedRole == 'student') _buildClassDropdowns(),
              ],
              _buildTextField(_emailController, "Email Address", Icons.email_outlined),
              const SizedBox(height: 20),
              _buildTextField(_passController, "Password", Icons.lock_outline, isPass: true),

              if (requiresOtp && _isOtpSent) ...[
                const SizedBox(height: 30),
                _buildCoolOtpInput(),
              ],

              if (_errorMessage != null) Padding(padding: const EdgeInsets.only(top: 15), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold))),

              const SizedBox(height: 30),
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _accentColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 5),
                  onPressed: _isLoading ? null : (requiresOtp && !_isOtpSent ? _sendOtp : _submitForm),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(requiresOtp && !_isOtpSent ? "Verify Identity" : (_isLogin ? "Sign In" : "Register"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
              Center(child: GestureDetector(onTap: () => setState(() { _isLogin = !_isLogin; _isOtpSent = false; _errorMessage = null; }), child: RichText(text: TextSpan(style: TextStyle(color: Colors.grey[600]), children: [TextSpan(text: _isLogin ? "New to Qubiq AI? " : "Already have an account? "), TextSpan(text: _isLogin ? "Create account" : "Log in", style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold))])))),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ RESTORED COOL OTP INPUT
  Widget _buildCoolOtpInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("ENTER 6-DIGIT CODE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.grey[600])),
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.center,
          children: [
            Opacity(opacity: 0.0, child: TextFormField(controller: _otpController, autofocus: true, keyboardType: TextInputType.number, maxLength: 6, style: const TextStyle(color: Colors.transparent), decoration: const InputDecoration(counterText: "", border: OutlineInputBorder(), fillColor: Colors.transparent, filled: true), enableInteractiveSelection: false)),
            IgnorePointer(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(6, (index) { String char = ""; if (_otpController.text.length > index) { char = _otpController.text[index]; } bool isFocused = _otpController.text.length == index; bool isFilled = _otpController.text.length > index; return AnimatedContainer(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut, width: 45, height: 55, decoration: BoxDecoration(color: isFilled ? _accentColor.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isFocused ? _accentColor : (isFilled ? _accentColor.withOpacity(0.5) : Colors.grey.shade300), width: isFocused ? 2 : 1.5), boxShadow: isFocused ? [BoxShadow(color: _accentColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))] : []), child: Center(child: Text(char, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _accentColor)))); }))),
          ],
        ),
      ],
    );
  }

  Widget _buildClassDropdowns() {
    return Padding(padding: const EdgeInsets.only(bottom: 25), child: Row(children: [Expanded(child: _customDropdown("Class", _selectedClass, ["1","2","3","4","5","6","7","8","9","10","11","12"], Icons.school_outlined, (v) => setState(() => _selectedClass = v!))), const SizedBox(width: 15), Expanded(child: _customDropdown("Section", _selectedSection, ["A","B","C","D","E"], Icons.groups_3_outlined, (v) => setState(() => _selectedSection = v!)))]));
  }

  Widget _customDropdown(String label, String value, List<String> items, IconData icon, ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.only(left: 8, bottom: 8), child: Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey[600]))), Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: _accentColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, isExpanded: true, icon: Icon(Icons.keyboard_arrow_down_rounded, color: _accentColor), borderRadius: BorderRadius.circular(15), items: items.map((e) => DropdownMenuItem(value: e, child: Row(children: [Icon(icon, size: 18, color: Colors.grey[400]), const SizedBox(width: 10), Text(e)]))).toList(), onChanged: onChanged)))] );
  }

  Widget _buildRoleSelector() {
    return Row(children: ['student', 'teacher', 'admin'].map((r) => Expanded(child: GestureDetector(onTap: () => setState(() => _selectedRole = r), child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: _selectedRole == r ? _accentColor.withOpacity(0.1) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _selectedRole == r ? _accentColor : Colors.grey.shade300, width: 2)), child: Center(child: Text(r.toUpperCase(), style: TextStyle(color: _selectedRole == r ? _accentColor : Colors.grey, fontWeight: FontWeight.bold, fontSize: 10))))))).toList());
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {bool isPass = false, bool isNum = false}) {
    return TextFormField(controller: ctrl, obscureText: isPass, keyboardType: isNum ? TextInputType.number : TextInputType.text, decoration: InputDecoration(labelText: hint, prefixIcon: Icon(icon, size: 20, color: Colors.grey[400]), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accentColor, width: 1.5))), validator: (v) => v!.isEmpty ? "Required" : null);
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 40) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += 40) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}