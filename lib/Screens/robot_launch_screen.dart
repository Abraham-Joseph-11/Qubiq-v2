import 'dart:io'; // For Platform check
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart'; // ✅ NEW PACKAGE

// IMPORT YOUR LOGIN SCREEN
import 'package:little_emmi/Screens/Auth/login_screen.dart';

// ------------------------------------------------------------------
// 1. LAUNCH SCREEN (Levitating Logo Animation)
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
    _checkLicenseAndNavigate();

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
  }

  Future<void> _checkLicenseAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isActivated = prefs.getBool('is_activated') ?? false;

    if (!mounted) return;

    if (isActivated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LittleEmmiLoginScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LicenseActivationScreen()),
      );
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
// 2. LICENSE ACTIVATION SCREEN (Hardware ID Logic)
// ------------------------------------------------------------------

class LicenseActivationScreen extends StatefulWidget {
  const LicenseActivationScreen({super.key});

  @override
  State<LicenseActivationScreen> createState() => _LicenseActivationScreenState();
}

class _LicenseActivationScreenState extends State<LicenseActivationScreen> {
  final TextEditingController _licenseController = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;

  // 🆔 HARDWARE ID EXTRACTION
  Future<String> _getHardwareDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceId = '';

    try {
      if (Platform.isWindows) {
        // Reads from Windows Registry (MachineGuid) - Very stable for labs
        WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
        deviceId = windowsInfo.deviceId;
      }
      else if (Platform.isMacOS) {
        // Hardware UUID - Tied to the motherboard
        MacOsDeviceInfo macInfo = await deviceInfo.macOsInfo;
        deviceId = macInfo.systemGUID ?? 'mac_unknown';
      }
      else if (Platform.isAndroid) {
        // Android ID - Persists until Factory Reset
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      }
      else if (Platform.isIOS) {
        // Vendor ID - Good for App Store apps
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'ios_unknown';
      }
      else {
        // Fallback for Linux/Web
        deviceId = 'generic_device_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      // Fallback if permission/driver fails
      debugPrint("Error getting Hardware ID: $e");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      deviceId = prefs.getString('fallback_id') ?? DateTime.now().millisecondsSinceEpoch.toString();
      if (!prefs.containsKey('fallback_id')) {
        await prefs.setString('fallback_id', deviceId);
      }
    }
    return deviceId;
  }

  Future<void> _activateLicense() async {
    String key = _licenseController.text.trim();

    if (key.length != 14) {
      setState(() => _errorMsg = "Invalid format. Use XXXX-XXXX-XXXX");
      return;
    }

    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Get Real Hardware ID
      String deviceId = await _getHardwareDeviceId();
      print("🔍 Checking License for Device ID: $deviceId");

      // 2. CHECK FIRESTORE
      QuerySnapshot snapshot = await firestore
          .collection('licenses')
          .where('key', isEqualTo: key)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() { _isLoading = false; _errorMsg = "License key not found."; });
        return;
      }

      var doc = snapshot.docs.first;
      var data = doc.data() as Map<String, dynamic>;

      // 3. VALIDATE STATUS & OWNERSHIP
      if (data['status'] == 'active') {
        if (data['linkedDeviceId'] == deviceId) {
          // ✅ License belongs to this PC -> Allow Re-login
          await _saveLocalActivation(key);
          return;
        } else {
          // ❌ License stolen/used by another PC
          setState(() { _isLoading = false; _errorMsg = "Key already in use on another machine."; });
          return;
        }
      }

      // 4. ACTIVATE NEW LICENSE (Lock to this Hardware ID)
      await doc.reference.update({
        'status': 'active',
        'linkedDeviceId': deviceId, // Lock happens here
        'activatedAt': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem, // Useful for your admin panel
      });

      // 5. SUCCESS
      await _saveLocalActivation(key);

    } catch (e) {
      setState(() { _isLoading = false; _errorMsg = "Connection Error: $e"; });
    }
  }

  Future<void> _saveLocalActivation(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_activated', true);
    await prefs.setString('license_key', key);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LittleEmmiLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/qubiq_logo.png', height: 100),
              const SizedBox(height: 40),

              Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                    border: Border.all(color: Colors.grey.shade200)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Product Activation", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey[900])),
                    const SizedBox(height: 8),
                    Text("Enter your 12-character educational license key.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(height: 30),

                    // LICENSE INPUT
                    TextField(
                      controller: _licenseController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, letterSpacing: 3, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                        UpperCaseTextFormatter(),
                        LicenseKeyFormatter(),
                        LengthLimitingTextInputFormatter(14),
                      ],
                      decoration: InputDecoration(
                        hintText: "XXXX-XXXX-XXXX",
                        hintStyle: TextStyle(fontSize: 16, letterSpacing: 2, color: Colors.grey[300]),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),

                    if (_errorMsg != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(_errorMsg!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ),

                    const SizedBox(height: 30),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _activateLicense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("ACTIVATE PORTAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text("Need a license? Contact support@qubiq.ai", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- CUSTOM FORMATTERS ---
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection);
  }
}

class LicenseKeyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) buffer.write('-');
    }
    var string = buffer.toString();
    return newValue.copyWith(text: string, selection: TextSelection.collapsed(offset: string.length));
  }
}