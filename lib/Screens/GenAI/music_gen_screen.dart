import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class MusicGenScreen extends StatefulWidget {
  const MusicGenScreen({super.key});

  @override
  State<MusicGenScreen> createState() => _MusicGenScreenState();
}

class _MusicGenScreenState extends State<MusicGenScreen> {
  final TextEditingController _controller = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isLoading = false;
  String? _status;
  String? _filePath;

  // 🔴 PASTE YOUR ELEVENLABS KEY HERE
  final String _apiKey = 'sk_dfc11444457c79cef52e64def09bd1858a885e4a492d5a0f';

  Future<void> _generateSoundEffect() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _status = "Generating Sound FX...";
      _filePath = null;
    });

    try {
      // ✅ ElevenLabs Text-to-Sound-Effects API
      final url = Uri.parse('https://api.elevenlabs.io/v1/sound-generation');

      final response = await http.post(
        url,
        headers: {
          'xi-api-key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "text": prompt, // e.g. "A majestic lion roaring"
          "duration_seconds": 6, // Max length (keep short for speed)
          "prompt_influence": 0.3, // 0.3 is usually best for FX
        }),
      );

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/sound_effect.mp3');
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          _filePath = file.path;
          _status = "Sound Ready! 🔊";
        });
      } else {
        // Handle common errors
        String errorMsg = "Error: ${response.statusCode}";
        if (response.statusCode == 401) errorMsg = "Invalid API Key";
        if (response.statusCode == 429) errorMsg = "Quota Exceeded (Free Tier Limit)";

        setState(() => _status = errorMsg);
      }
    } catch (e) {
      setState(() => _status = "Connection Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _playAudio() async {
    if (_filePath != null) {
      await _audioPlayer.play(DeviceFileSource(_filePath!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("Sound FX Lab", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.graphic_eq,
              size: 100,
              color: _isLoading ? Colors.orangeAccent : Colors.lightBlueAccent,
            ),
            const SizedBox(height: 30),
            Text(
              _status ?? "Describe a sound (e.g., 'Laser blast', 'Cat meow')",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 30),
            if (_filePath != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text("Play FX"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _playAudio,
              ),
            const Spacer(),
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white10,
                hintText: "Enter sound description...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                suffixIcon: IconButton(
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_fix_high, color: Colors.lightBlueAccent),
                  onPressed: _isLoading ? null : _generateSoundEffect,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}