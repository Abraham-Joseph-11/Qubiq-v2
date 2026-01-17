import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import 'package:little_emmi/Screens/Auth/login_screen.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final TextEditingController _licenseController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<String> _getDeviceId() async {
    var deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isWindows) {
        var windowsInfo = await deviceInfo.windowsInfo;
        return windowsInfo.deviceId;
      } else if (Platform.isMacOS) {
        var macInfo = await deviceInfo.macOsInfo;
        return macInfo.systemGUID ?? 'unknown-mac-id';
      } else if (Platform.isAndroid) {
        var androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        var iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown-ios-id';
      }
    } catch (e) {
      return 'unknown-device';
    }
    return 'generic-id';
  }

  Future<void> _verifyLicense() async {
    setState(() { _isLoading = true; _error = null; });

    String inputKey = _licenseController.text.trim();
    if (inputKey.isEmpty) {
      setState(() { _isLoading = false; _error = "Please enter a valid key."; });
      return;
    }

    // 🛑 HARDCODED BYPASS
    if (inputKey == "QBIQ-TEST-KEY") {
      await _finalizeActivation();
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Search for the key
      QuerySnapshot query = await firestore
          .collection('licenses')
          .where('key', isEqualTo: inputKey)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() { _isLoading = false; _error = "Invalid License Key."; });
        return;
      }

      DocumentSnapshot licenseDoc = query.docs.first;
      Map<String, dynamic> data = licenseDoc.data() as Map<String, dynamic>;
      String status = data['status'] ?? 'unused';

      // 🔒 STRICT CHECK: ONE-TIME USE ONLY
      // If status is ANYTHING other than 'unused', we block it.
      // It does not matter if it's the same device or a new one.
      if (status != 'unused') {
        setState(() {
          _isLoading = false;
          _error = "This key has already been used.";
        });
        return;
      }

      // 2. If unused, Activate it (Burn the key)
      String deviceId = await _getDeviceId();

      await licenseDoc.reference.update({
        'status': 'active',
        'linkedDeviceId': deviceId, // We still record WHO used it
        'activatedAt': FieldValue.serverTimestamp(),
      });

      await _finalizeActivation();

    } catch (e) {
      setState(() { _isLoading = false; _error = "Connection failed. Check internet."; });
    }
  }

  Future<void> _finalizeActivation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_activated', true);

    if (!mounted) return;
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LittleEmmiLoginScreen())
    );
  }

  Future<void> _resetApp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _licenseController.clear();
      _error = "Memory Wiped! Restart app to re-test.";
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("App Reset. Please restart."))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(40),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔴 RESET BUTTON
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _resetApp,
                    icon: const Icon(Icons.refresh, color: Colors.red, size: 16),
                    label: const Text("RESET APP", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.05),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.verified_user_outlined, size: 40, color: Colors.blue),
                ),
                const SizedBox(height: 24),
                const Text("Software Activation", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                const Text("Enter your license key to activate this terminal.",
                    textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 30),

                // ✅ INPUT FIELD
                TextField(
                  controller: _licenseController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(letterSpacing: 3, fontWeight: FontWeight.bold, fontSize: 18),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
                    UpperCaseTextFormatter(),
                    _LicenseKeyFormatter(),
                  ],
                  decoration: InputDecoration(
                    hintText: "XXXX-XXXX-XXXX",
                    hintStyle: const TextStyle(letterSpacing: 1, fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),

                if (_error != null) Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isLoading ? null : _verifyLicense,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Activate License"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- HELPERS ---

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class _LicenseKeyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }
    String text = newValue.text.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      int index = i + 1;
      if (index % 4 == 0 && index != text.length) {
        buffer.write('-');
      }
    }
    String formatted = buffer.toString();
    if (formatted.length > 14) {
      formatted = formatted.substring(0, 14);
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}