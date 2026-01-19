// lib/Screens/GenAI/gen_ai_hub_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Import your screens
import 'package:little_emmi/Screens/ai_chat_screen.dart';
import 'package:little_emmi/Screens/GenAI/image_gen_screen.dart';
import 'package:little_emmi/Screens/GenAI/music_gen_screen.dart';

class GenAIHubScreen extends StatelessWidget {
  const GenAIHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "QubiQAI Suite",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 1. Dark AI Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F0C29), // Deep Cyber Dark
                  Color(0xFF302B63), // Purple Haze
                  Color(0xFF24243E), // Midnight
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 2. Animated Background Particles (FIXED)
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purpleAccent.withOpacity(0.2),
                // ✅ FIXED: Replaced invalid 'blurRadius' with 'boxShadow'
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withOpacity(0.4),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(duration: 3.seconds, begin: const Offset(1, 1), end: const Offset(1.5, 1.5)),
          ),

          // 3. Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "Select a Module",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(),

                  const SizedBox(height: 20),

                  // --- THE CARDS ---
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildAICard(
                          context,
                          title: "Neural Chat",
                          subtitle: "Advanced LLM Tutor (Gemini)",
                          icon: Icons.psychology_outlined,
                          color1: const Color(0xFF8E2DE2),
                          color2: const Color(0xFF4A00E0),
                          delay: 300,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AiChatScreen()),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildAICard(
                          context,
                          title: "Vision Forge",
                          subtitle: "Text-to-Image Diffusion",
                          icon: Icons.palette_outlined,
                          color1: const Color(0xFFFF416C),
                          color2: const Color(0xFFFF4B2B),
                          delay: 400,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ImageGenScreen()),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildAICard(
                          context,
                          title: "Sonic Lab",
                          subtitle: "AI Music Composition",
                          icon: Icons.graphic_eq,
                          color1: const Color(0xFF00B4DB),
                          color2: const Color(0xFF0083B0),
                          delay: 500,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MusicGenScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAICard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color1,
        required Color color2,
        required VoidCallback onTap,
        required int delay,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [color1.withOpacity(0.9), color2.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color1.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Stack(
          children: [
            // Decorative background icon (Large & faded)
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                icon,
                size: 150,
                color: Colors.white.withOpacity(0.1),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.2, curve: Curves.easeOut);
  }
}