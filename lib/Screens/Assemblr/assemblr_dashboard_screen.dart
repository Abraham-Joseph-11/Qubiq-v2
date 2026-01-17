// lib/Screens/Assemblr/assemblr_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:little_emmi/Screens/inappwebview_screen.dart'; // Use your project name

class AssemblrDashboardScreen extends StatefulWidget {
  const AssemblrDashboardScreen({super.key});

  @override
  State<AssemblrDashboardScreen> createState() => _AssemblrDashboardScreenState();
}

class _AssemblrDashboardScreenState extends State<AssemblrDashboardScreen> {
  final _assemblrLinkController = TextEditingController();

  @override
  void dispose() {
    _assemblrLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Using same theme
      appBar: AppBar(
        title: const Text('Assemblr Edu AR'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            _buildAssemblrLaunchCard(context),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AR Project Launcher',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'View your Assemblr Edu projects in Augmented Reality.',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
        ),
      ],
    ).animate().slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOut);
  }

  Widget _buildAssemblrLaunchCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00BFA6), Colors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.view_in_ar_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'Launch Assemblr AR',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Paste your Assemblr project link below to view it in AR.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 20),
          // Link Input Field
          TextField(
            controller: _assemblrLinkController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'https://assemblr.world/p/...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.black.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          // Launch Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF00BFA6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                String url = _assemblrLinkController.text.trim(); // Added .trim()
                if (url.isNotEmpty && url.startsWith('https://assemblr.world/p/')) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InAppWebViewScreen(
                        title: 'Assemblr AR',
                        url: url, // Pass the dynamic URL
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid or empty Assemblr project link.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                'Launch AR',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().scaleXY(delay: 200.ms, duration: 500.ms, curve: Curves.elasticOut);
  }
}