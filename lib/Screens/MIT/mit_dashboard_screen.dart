// lib/Screens/MIT/mit_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:little_emmi/Screens/inappwebview_screen.dart';

class MitDashboardScreen extends StatelessWidget {
  const MitDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color(0xFF16213E);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('MIT App Inventor'),
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
            _buildLaunchCard(context, cardColor),
            const SizedBox(height: 30),
            _buildFeaturesSection(cardColor),
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
          'App Inventor Hub',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A platform for creating apps with visual block coding.',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
        ),
      ],
    ).animate().slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOut);
  }

  Widget _buildLaunchCard(BuildContext context, Color cardColor) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.5),
      child: InkWell(
        onTap: () {
          // Navigate to the InAppWebView
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InAppWebViewScreen(
                title: 'Mobile App Development Learning',
                // ✅ UPDATED: Changed URL to the 'code2' server
                url: 'https://code2.appinventor.mit.edu/',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF00BFA6), Colors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 40),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Launch Web Editor',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Opens code2.appinventor.mit.edu',
                      style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().scaleXY(delay: 200.ms, duration: 500.ms, curve: Curves.elasticOut);
  }

  Widget _buildFeaturesSection(Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Features',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureTile(
          icon: Icons.extension_outlined,
          title: 'Visual Block Coding',
          subtitle: 'No complex code needed to build apps.',
          cardColor: cardColor,
        ),
        _buildFeatureTile(
          icon: Icons.phone_android_rounded,
          title: 'Real-time Testing',
          subtitle: 'See your changes live on your device.',
          cardColor: cardColor,
        ),
        _buildFeatureTile(
          icon: Icons.widgets_outlined,
          title: 'Rich Component Library',
          subtitle: 'Use buttons, sensors, and more.',
          cardColor: cardColor,
        ),
      ],
    );
  }

  Widget _buildFeatureTile({required IconData icon, required String title, required String subtitle, required Color cardColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}