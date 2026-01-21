// lib/Screens/Auth/student_dashboard.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' as p;
import 'dart:io' show Platform;
import 'package:process_run/shell.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import 'package:little_emmi/Screens/flowchart_ide_screen.dart';
import 'package:little_emmi/Screens/python_ide_screen.dart';
import 'package:little_emmi/Screens/inappwebview_screen.dart';
import 'package:little_emmi/Screens/MIT/mit_dashboard_screen.dart';
import 'package:little_emmi/Screens/ai_chat_screen.dart';
import 'package:little_emmi/Screens/ar_dashboard.dart';
import 'package:little_emmi/Screens/Auth/login_screen.dart';
import 'package:little_emmi/Screens/GenAI/image_gen_screen.dart';
import 'package:little_emmi/Screens/GenAI/music_gen_screen.dart';
import 'package:little_emmi/Screens/Help/help_chat_screen.dart';
import 'package:little_emmi/Screens/adaptive_quiz_demo.dart';
import 'package:permission_handler/permission_handler.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> with WidgetsBindingObserver {
  String _userName = "Student";
  final String _studentClass = "Class 5-A";
  Timer? _internetCheckTimer;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 🚀 CACHE START: Load data immediately
    _fetchUserName();
    _requestCameraPermission();
    _internetCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _verifyRealInternet();
    });
  }

  // 🚀 CACHE: Pre-load images for smoother UI
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheAssets();
  }

  // 🚀 LOGOUT: Handle Desktop Close
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((Platform.isWindows || Platform.isMacOS) && state == AppLifecycleState.detached) {
      FirebaseAuth.instance.signOut();
    }
  }

  void _precacheAssets() {
    final List<String> assets = [
      'assets/images/quiz.png',
      'assets/images/suno.png',
      'assets/images/chatai.png',
      'assets/images/imagegen.png',
      'assets/images/soundgen.png',
      'assets/images/word.png',
      'assets/images/powerpoint.png',
      'assets/images/excel.png',
    ];
    for (String path in assets) {
      precacheImage(AssetImage(path), context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _internetCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _verifyRealInternet() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com')).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        if (_isOffline && mounted) setState(() => _isOffline = false);
      }
    } catch (e) {
      if (!_isOffline && mounted) setState(() => _isOffline = true);
    }
  }

  Future<void> _requestCameraPermission() async {
    if (Platform.isWindows) {
      try {
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          debugPrint("No cameras found. Permission might be denied in Windows Settings.");
        }
      } catch (e) {
        debugPrint("Camera access denied on Windows: $e");
      }
      return;
    }
    var status = await Permission.camera.status;
    if (status.isDenied) await Permission.camera.request();
    if (await Permission.camera.isPermanentlyDenied) openAppSettings();
  }

  Future<void> _launchEmmiV2App() async {
    try {
      String appDirectory = p.dirname(Platform.resolvedExecutable);
      var shell = Shell(workingDirectory: appDirectory);
      await shell.run('EmmiV2.exe');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Launch Error: EmmiV2.exe not found"), backgroundColor: Colors.red),
      );
    }
  }

  // 🚀 CACHE LOGIC: Fetch User Name
  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // 1. Check Local Cache FIRST (Fastest)
        final docCache = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.cache)); //

        if (docCache.exists && mounted) {
          setState(() => _userName = docCache.get('name'));
          return; // If found in cache, we are done!
        }

        // 2. Fallback to Server if cache is empty
        final docServer = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.server));

        if (docServer.exists && mounted) {
          setState(() => _userName = docServer.get('name'));
        }
      } catch (e) { debugPrint("Error: $e"); }
    }
  }

  void _showComingSoon(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.construction_rounded, size: 50, color: Colors.orangeAccent),
                const SizedBox(height: 20),
                Text("Coming Soon!", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("$featureName is under development.", textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Got it"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Student Portal", style: GoogleFonts.poppins(fontSize: 14, color: Colors.blueGrey[500], fontWeight: FontWeight.w600)),
          Text("Welcome, $_userName", style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blueGrey[900])),
        ]),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          onPressed: () async {
            // 🛑 FORCE LOGOUT
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LittleEmmiLoginScreen()),
                    (route) => false,
              );
            }
          },
        ),
      ],
    ).animate().fadeIn();
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    final List<DashboardItem> quizApps = [
      DashboardItem(title: 'Smart Quiz', subtitle: 'Adaptive Levels', imagePath: 'assets/images/quiz.png', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdaptiveLearningMenu()))),
    ];

    final List<DashboardItem> aiLearningApps = [
      DashboardItem(title: 'Suno AI', subtitle: 'Music Creation', imagePath: 'assets/images/suno.png', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InAppWebViewScreen(url: 'https://suno.com', title: 'Suno AI')))),
      DashboardItem(title: 'Neural Chat', subtitle: 'QubiQAI Assistant', imagePath: 'assets/images/chatai.png', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AiChatScreen()))),
      DashboardItem(title: 'Vision Forge', subtitle: 'AI Image Gen', imagePath: 'assets/images/imagegen.png', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ImageGenScreen()))),
      DashboardItem(title: 'Sonic Lab', subtitle: 'AI Sound FX', imagePath: 'assets/images/soundgen.png', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MusicGenScreen()))),
    ];

    final List<DashboardItem> teachableApps = [
      DashboardItem(title: 'Image Model', subtitle: 'Vision Training', imagePath: 'assets/images/imgnobgnew.png', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InAppWebViewScreen(url: 'https://teachablemachine.withgoogle.com/train/image', title: 'Train Image Model')))),
      DashboardItem(title: 'Audio Model', subtitle: 'Sound Training', imagePath: 'assets/images/soundmachinenobg.png', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InAppWebViewScreen(url: 'https://teachablemachine.withgoogle.com/train/audio', title: 'Train Audio Model')))),
      DashboardItem(title: 'Pose Model', subtitle: 'Body Tracking', imagePath: 'assets/images/posemodelnobg.png', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InAppWebViewScreen(url: 'https://teachablemachine.withgoogle.com/train/pose', title: 'Train Pose Model')))),
    ];

    final List<DashboardItem> roboticsApps = [
      if (Platform.isWindows) DashboardItem(title: 'Emmi Core', subtitle: 'Robot Manager', imagePath: 'assets/images/emmi.png', onTap: _launchEmmiV2App),
      DashboardItem(title: 'Little Emmi', subtitle: 'Robot Learning', imagePath: 'assets/images/littleemmi.png', onTap: () => Navigator.pushNamed(context, '/app/robot_workspace')),
    ];

    final List<DashboardItem> mobileApps = [
      DashboardItem(title: 'App Development', subtitle: 'MIT Blocks', imagePath: 'assets/images/mitnobg.png', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MitDashboardScreen()))),
    ];

    final List<DashboardItem> codingApps = [
      DashboardItem(title: 'Flowchart Py', subtitle: 'Visual Python', imagePath: 'assets/images/pyflownobg.png', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FlowchartIdeScreen()))),
      DashboardItem(title: 'Flowchart Java', subtitle: 'Visual Java', imagePath: 'assets/images/javaflownobg.png', onTap: () => _showComingSoon(context, "Flowchart Java")),
      DashboardItem(title: 'Python IDE', subtitle: 'Code Editor', imagePath: 'assets/images/python.jpg', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PythonIdeScreen()))),
      DashboardItem(title: 'Java IDE', subtitle: 'Professional', imagePath: 'assets/images/java.jpg', onTap: () => _showComingSoon(context, "Professional Java IDE")),
    ];

    final List<DashboardItem> arApps = [
      DashboardItem(title: 'AR Learning', subtitle: '3D Exploration', imagePath: 'assets/images/ar.png', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ARDashboard()))),
      DashboardItem(title: 'Assemblr EDU', subtitle: 'AR Studio', imagePath: 'assets/images/edu.jpg', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InAppWebViewScreen(url: 'https://edu.assemblrworld.com/en/edukits', title: 'Assemblr EDU')))),
    ];

    final List<DashboardItem> productivityApps = [
      DashboardItem(title: 'Word', subtitle: 'Documents', imagePath: 'assets/images/word.png', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InAppWebViewScreen(url: 'https://www.office.com/launch/word', title: 'Microsoft Word')))),
      DashboardItem(title: 'PowerPoint', subtitle: 'Slides', imagePath: 'assets/images/powerpoint.png', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InAppWebViewScreen(url: 'https://www.office.com/launch/powerpoint', title: 'Microsoft PowerPoint')))),
      DashboardItem(title: 'Excel', subtitle: 'Spreadsheets', imagePath: 'assets/images/excel.png', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InAppWebViewScreen(url: 'https://www.office.com/launch/excel', title: 'Microsoft Excel')))),
    ];

    final List<_CategoryTile> categories = [
      _CategoryTile(name: "Adaptive Learning", color: Colors.deepPurpleAccent, items: quizApps),
      _CategoryTile(name: "AI Learning", color: Colors.blue, items: aiLearningApps),
      _CategoryTile(name: "Teachable Machine", color: Colors.orange, items: teachableApps),
      _CategoryTile(name: "Robotics", color: Colors.teal, items: roboticsApps),
      _CategoryTile(name: "Mobile App", color: Colors.green, items: mobileApps),
      _CategoryTile(name: "Coding", color: Colors.amber, items: codingApps),
      _CategoryTile(name: "Augmented Reality", color: Colors.pinkAccent, items: arApps),
      _CategoryTile(name: "Productivity Studio", color: Colors.indigo, items: productivityApps),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpChatScreen())),
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.support_agent_rounded, color: Colors.white),
        label: const Text("Help AI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: PastelAnimatedBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 30),
                  if (isMobile) Column(children: [_buildGlassProgressCard(), const SizedBox(height: 16), _buildStatsGrid(isMobile)]) else Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: _buildGlassProgressCard()), const SizedBox(width: 20), Expanded(flex: 5, child: _buildStatsGrid(isMobile))]),
                  const SizedBox(height: 30),
                  Text("Experiments", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('assignments').where('className', isEqualTo: _studentClass).orderBy('dueDate', descending: false).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return Center(child: Text("Error loading tasks", style: GoogleFonts.poppins(color: Colors.redAccent)));
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text("No assignments due! 🎉", style: GoogleFonts.poppins(color: Colors.grey)));
                      return ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: snapshot.data!.docs.length, itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        return _buildRealProjectTile(context, doc.data() as Map<String, dynamic>, doc.id);
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  ...categories.map((category) => _buildCategorySection(category, isMobile)),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
          _buildOfflineBanner(),
        ],
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildRealProjectTile(BuildContext context, Map<String, dynamic> data, String docId) {
    String tool = data['tool'] ?? 'General';
    DateTime? dueDate = data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null;
    Color accentColor = tool.contains('Python') ? Colors.amber.shade700 : tool.contains('Flowchart') ? Colors.orange : tool.contains('Emmi') ? Colors.teal : (tool.contains('AR') || tool.contains('3D')) ? Colors.pinkAccent : Colors.blue;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AssignmentDetailScreen(assignmentData: data, docId: docId))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white)),
        child: Row(children: [Container(height: 40, width: 4, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['title'] ?? 'Untitled', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.blueGrey[800], fontSize: 15)), Text(dueDate != null ? "Due: ${DateFormat('MMM dd').format(dueDate)}" : "No Due Date", style: GoogleFonts.poppins(color: Colors.blueGrey[400], fontSize: 12))])), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text("Start >", style: GoogleFonts.poppins(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)))]),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildCategorySection(_CategoryTile category, bool isMobile) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.only(left: 4.0, bottom: 16.0), child: Row(children: [Container(width: 4, height: 24, decoration: BoxDecoration(color: category.color, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 10), Text(category.name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]))])), GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: isMobile ? 4 : 7, crossAxisSpacing: 10, mainAxisSpacing: 16, childAspectRatio: 0.75), itemCount: category.items.length, itemBuilder: (context, index) => _ImageAppCard(item: category.items[index])), const SizedBox(height: 24)]);
  }

  Widget _buildOfflineBanner() {
    return Positioned(bottom: 24, right: 24, child: AnimatedSwitcher(duration: const Duration(milliseconds: 500), child: _isOffline ? Container(width: 300, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.95), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 20)]), child: Row(children: [const Icon(Icons.wifi_off_rounded, color: Colors.white), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text("Offline Mode", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), Text("Using local cached data.", style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 11))]))])) : const SizedBox.shrink()));
  }

  Widget _buildGlassProgressCard() {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white, width: 2)), child: Column(children: [CircularPercentIndicator(radius: 45.0, lineWidth: 8.0, percent: 0.75, center: const Text("75%"), progressColor: Colors.indigoAccent), const SizedBox(height: 12), Text("Weekly Progress", style: GoogleFonts.poppins(fontWeight: FontWeight.bold))]));
  }

  Widget _buildStatsGrid(bool isMobile) {
    return GridView.count(crossAxisCount: isMobile ? 2 : 4, crossAxisSpacing: 12, mainAxisSpacing: 12, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: [_buildStatTile("Projects", "12", Icons.folder_outlined, Colors.blue), _buildStatTile("Tests", "5/6", Icons.assignment_outlined, Colors.green), _buildStatTile("Pending", "2", Icons.hourglass_empty, Colors.orange), _buildStatTile("Rank", "#4", Icons.emoji_events_outlined, Colors.purple)]);
  }

  Widget _buildStatTile(String title, String value, IconData icon, Color color) {
    return Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(16)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 20), Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)), Text(title, style: GoogleFonts.poppins(fontSize: 11, color: Colors.blueGrey[500]))]));
  }
}

class AssignmentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> assignmentData;
  final String docId;
  const AssignmentDetailScreen({super.key, required this.assignmentData, required this.docId});
  void _showInfoPopup(BuildContext context, String title, String message) { showDialog(context: context, builder: (context) => Center(child: Container(width: MediaQuery.of(context).size.width * 0.8, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)]), child: Material(color: Colors.transparent, child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.info_outline_rounded, color: Colors.indigo, size: 48), const SizedBox(height: 16), Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14)), const SizedBox(height: 24), ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("OK", style: TextStyle(color: Colors.white)))])))).animate().scale().fadeIn()); }
  void _launchAssignedTool(BuildContext context, String toolName) { if (toolName.contains("Python")) { Navigator.push(context, MaterialPageRoute(builder: (context) => const PythonIdeScreen())); } else if (toolName.contains("Flowchart")) Navigator.push(context, MaterialPageRoute(builder: (context) => const FlowchartIdeScreen())); else if (toolName.contains("App Inventor") || toolName.contains("Mobile")) Navigator.push(context, MaterialPageRoute(builder: (context) => const MitDashboardScreen())); else if (toolName.contains("Little Emmi")) Navigator.pushNamed(context, '/app/robot_workspace'); else if (toolName.contains("AR") || toolName.contains("3D")) Navigator.push(context, MaterialPageRoute(builder: (context) => ARDashboard())); else if (toolName.contains("Vision") || toolName.contains("Image")) Navigator.push(context, MaterialPageRoute(builder: (context) => const ImageGenScreen())); else if (toolName.contains("Sonic") || toolName.contains("Sound")) Navigator.push(context, MaterialPageRoute(builder: (context) => const MusicGenScreen())); else _showInfoPopup(context, "Manual Start Required", "The tool '$toolName' is not integrated for auto-launch."); }
  @override Widget build(BuildContext context) { String tool = assignmentData['tool'] ?? 'None'; DateTime? dueDate = assignmentData['dueDate'] != null ? (assignmentData['dueDate'] as Timestamp).toDate() : null; return Scaffold(backgroundColor: const Color(0xFFF8FAFC), appBar: AppBar(title: Text("Assignment Details", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: Colors.black)), body: Padding(padding: const EdgeInsets.all(24.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(24), width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(tool, style: GoogleFonts.poppins(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 12))), const Spacer(), Icon(Icons.access_time, size: 16, color: Colors.grey[600]), const SizedBox(width: 4), Text(dueDate != null ? DateFormat('MMM dd, hh:mm a').format(dueDate) : "No Due Date", style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12))]), const SizedBox(height: 16), Text(assignmentData['title'] ?? 'Assignment', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey[900])), const SizedBox(height: 8), Text("Assigned by ${assignmentData['teacherName'] ?? 'Teacher'}", style: GoogleFonts.poppins(fontSize: 14, color: Colors.blueGrey[500]))])), const SizedBox(height: 24), Text("Instructions", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])), const SizedBox(height: 12), Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Text(assignmentData['description'] ?? 'No instructions.', style: GoogleFonts.poppins(fontSize: 15, color: Colors.blueGrey[700], height: 1.6))), const Spacer(), SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(onPressed: () => _launchAssignedTool(context, tool), icon: const Icon(Icons.rocket_launch, color: Colors.white), label: Text("Launch $tool", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4)))]))); }
}

class _CategoryTile { final String name; final Color color; final List<DashboardItem> items; _CategoryTile({required this.name, required this.color, required this.items}); }
class _ImageAppCard extends StatelessWidget { final DashboardItem item; const _ImageAppCard({required this.item}); @override Widget build(BuildContext context) { return GestureDetector(onTap: item.onTap, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))]), child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [Expanded(child: Container(padding: const EdgeInsets.all(34), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white), child: Image.asset(item.imagePath, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_rounded, size: 30, color: Colors.grey)))), const SizedBox(height: 8), Text(item.title, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 2), Text(item.subtitle, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 9, color: Colors.blueGrey[400]), maxLines: 1, overflow: TextOverflow.ellipsis)]))); } }
class DashboardItem { final String title; final String subtitle; final String imagePath; final VoidCallback onTap; DashboardItem({required this.title, required this.subtitle, required this.imagePath, required this.onTap}); }
class PastelAnimatedBackground extends StatelessWidget { const PastelAnimatedBackground({super.key}); @override Widget build(BuildContext context) { return Container(color: Colors.white); } }