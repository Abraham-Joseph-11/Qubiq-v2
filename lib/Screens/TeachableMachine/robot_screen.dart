import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_animate/flutter_animate.dart';
import 'robot_brain.dart';

class RobotScreen extends StatefulWidget {
  const RobotScreen({super.key});

  @override
  State<RobotScreen> createState() => _RobotScreenState();
}

class _RobotScreenState extends State<RobotScreen> {
  CameraController? _controller;
  final RobotBrain _brain = RobotBrain();
  bool _isTraining = false;
  String _currentPrediction = "Teach me something! 🤖";
  double _confidence = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _brain.loadModel();
  }

  Future<void> _initializeCamera() async {
    print("DEBUG: Starting Camera Init..."); // DEBUG LOG

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print("DEBUG: No cameras found!");
        return;
      }

      print("DEBUG: Found ${cameras.length} cameras. Opening first one...");
      _controller = CameraController(cameras.first, ResolutionPreset.medium, enableAudio: false);

      await _controller!.initialize();
      print("DEBUG: Camera Initialized!");

      if (mounted) {
        setState(() {});
        _startGuessingLoop();
      }
    } catch (e) {
      print("DEBUG: CRITICAL ERROR IN CAMERA INIT: $e"); // THIS WILL SHOW YOU THE REAL ERROR
    }
  }

  void _startGuessingLoop() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (_controller == null || !_controller!.value.isInitialized || _controller!.value.isTakingPicture || _isTraining) return;

      try {
        XFile photo = await _controller!.takePicture();
        final bytes = await photo.readAsBytes();
        final image = img.decodeImage(bytes);

        if (image != null) {
          var result = _brain.guess(image);
          if (mounted) {
            setState(() {
              if (result.isEmpty) {
                _currentPrediction = "I need examples! 📸";
                _confidence = 0.0;
              } else {
                _currentPrediction = "I see: ${result['label']}";
                _confidence = result['confidence'];
              }
            });
          }
        }
      } catch (e) {
        print("Camera busy: $e");
      }
    });
  }

  Future<void> _teachRobot(String label) async {
    setState(() => _isTraining = true);
    try {
      XFile photo = await _controller!.takePicture();
      final bytes = await photo.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image != null) await _brain.teach(image, label);
    } catch (e) {
      print("Error training: $e");
    }
    setState(() => _isTraining = false);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Teach the Robot", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Column(
        children: [
          // Camera Zone
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(_controller!),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.black54,
                        child: Column(
                          children: [
                            Text(_currentPrediction, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _confidence,
                              backgroundColor: Colors.white24,
                              color: _confidence > 0.8 ? Colors.greenAccent : Colors.orangeAccent,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          // Controls Zone
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: -10, offset: const Offset(0, -5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Train your Buckets:", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTrainButton("Red Object", Colors.redAccent),
                      _buildTrainButton("Blue Object", Colors.blueAccent),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainButton(String label, Color color) {
    int count = _brain.getCount(label);
    return GestureDetector(
      onTap: () => _teachRobot(label),
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
            Text("$count examples", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ).animate(target: _isTraining ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(0.95, 0.95)),
    );
  }
}