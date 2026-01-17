import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ImageGenScreen extends StatefulWidget {
  const ImageGenScreen({super.key});

  @override
  State<ImageGenScreen> createState() => _ImageGenScreenState();
}

class _ImageGenScreenState extends State<ImageGenScreen> {
  final TextEditingController _controller = TextEditingController();

  // We store the URL string, not the bytes.
  // This allows Flutter to handle the slow connection gracefully.
  String? _imageUrl;
  int _refreshKey = 0;
  bool _isLoading = false;

  void _generateImage() {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    // 1. Dismiss keyboard
    FocusScope.of(context).unfocus();

    // 2. Set Loading State
    setState(() {
      _isLoading = true;
      _refreshKey++; // Forces Flutter to treat this as a NEW image
    });

    // 3. Build Optimized URL
    final int seed = Random().nextInt(1000000);
    final encodedPrompt = Uri.encodeComponent(prompt);

    // ✅ FIX: Standard Model + 768px (Best balance of speed/quality)
    // We do NOT use 'http.get' here. We just set the URL.
    final url = 'https://image.pollinations.ai/prompt/$encodedPrompt?width=768&height=768&seed=$seed&nologo=true&model=flux';

    print("🚀 Loading Image from: $url");

    // 4. Update UI to trigger Image.network
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _imageUrl = url;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: Text("Vision Forge", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Placeholder (Start State)
                    if (_imageUrl == null)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.palette_outlined, size: 60, color: Colors.white24),
                          const SizedBox(height: 10),
                          Text("Enter a prompt to start", style: GoogleFonts.poppins(color: Colors.white54)),
                        ],
                      ),

                    // 2. The Image Widget (Handles its own loading)
                    if (_imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          _imageUrl!,
                          key: ValueKey(_refreshKey), // Critical for reloading
                          fit: BoxFit.contain,

                          // ✅ ADDED HEADERS: Helps bypass "Bot" blockers
                          headers: const {
                            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                          },

                          // Loading Builder: Shows while bytes are downloading
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              // Download Complete!
                              // We use a post-frame callback to safely update our local state variable
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && _isLoading) setState(() => _isLoading = false);
                              });
                              return child.animate().fadeIn();
                            }

                            // While Downloading...
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(color: Colors.pinkAccent),
                                  const SizedBox(height: 20),
                                  Text("Forging Vision...", style: GoogleFonts.poppins(color: Colors.white70)),
                                ],
                              ),
                            );
                          },

                          // Error Builder: Handles Timeouts/429s visually
                          errorBuilder: (context, error, stackTrace) {
                            // Stop the loading spinner on error
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && _isLoading) setState(() => _isLoading = false);
                            });

                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.cloud_off, color: Colors.redAccent, size: 40),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Server Busy.\nTry a simpler prompt or wait 10s.",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: _generateImage,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text("Retry"),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Input Area
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "e.g., Cyberpunk city...",
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      onSubmitted: (_) => _generateImage(),
                    ),
                  ),
                  IconButton(
                    icon: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pinkAccent))
                        : const Icon(Icons.auto_awesome, color: Colors.pinkAccent),
                    onPressed: _isLoading ? null : _generateImage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}