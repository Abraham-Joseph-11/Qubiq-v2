// lib/Screens/Auth/student_dashboard.dart

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:little_emmi/Screens/TeachableMachine/robot_screen.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:process_run/shell.dart';

// ✅ Firebase & Connectivity Imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

// ✅ Import Responsive Helper
import 'package:little_emmi/Utils/responsive_layout.dart';

// Import screens
import 'package:little_emmi/Screens/Dashboard/dashboard_screen.dart';
import 'package:little_emmi/Screens/flowchart_ide_screen.dart';
import 'package:little_emmi/Screens/python_ide_screen.dart';
import 'package:little_emmi/Screens/inappwebview_screen.dart';
import 'package:little_emmi/Screens/adaptive_quiz_demo.dart';
import 'package:little_emmi/Screens/MIT/mit_dashboard_screen.dart';
import 'package:little_emmi/Screens/GenAI/gen_ai_hub_screen.dart';
import 'package:little_emmi/Screens/ar_dashboard.dart';
import 'package:little_emmi/Screens/Auth/login_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  String _userName = "Student";
  final String _studentClass = "Class 5-A";

  // ✅ Connectivity State
  Timer? _internetCheckTimer;
  bool _isOffline = false; // CHANGED: Simple boolean instead of dialog state

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _internetCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _verifyRealInternet();
    });
  }

  @override
  void dispose() {
    _internetCheckTimer?.cancel();
    super.dispose();
  }

  // ✅ CHANGED: Logic now updates a boolean variable instead of showing/popping dialogs
  Future<void> _verifyRealInternet() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com')).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        if (_isOffline) {
          if (mounted) setState(() => _isOffline = false); // Auto-hide when back online
        }
      }
    } catch (e) {
      if (!_isOffline) {
        if (mounted) setState(() => _isOffline = true); // Show corner popup
      }
    }
  }

  // ❌ REMOVED: _showOfflineModePopup and _showCustomPopup (No longer needed)

  Future<void> _launchEmmiV2App() async {
    try {
      String appDirectory = p.dirname(Platform.resolvedExecutable);
      var shell = Shell(workingDirectory: appDirectory);
      await shell.run('EmmiV2.exe');
    } catch (e) {
      // We can use a simple SnackBar for this error now, or a similar corner popup logic
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Launch Error: EmmiV2.exe not found"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null && doc.data()!.containsKey('name')) {
          if (mounted) setState(() => _userName = doc.get('name'));
        }
      } catch (e) { debugPrint("Error fetching name: $e"); }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    // 1. CODING LAB
    final List<DashboardItem> codingApps = [
      DashboardItem(title: 'Flowchart', subtitle: 'Visual Logic', icon: Icons.account_tree_outlined, accentColor: Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FlowchartIdeScreen()))),
      DashboardItem(title: 'Python IDE', subtitle: 'Code Editor', icon: Icons.code_outlined, accentColor: Colors.amber.shade700, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PythonIdeScreen()))),
      DashboardItem(title: 'Mobile Apps', subtitle: 'Block Coding', icon: Icons.extension_outlined, accentColor: Colors.green, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MitDashboardScreen()))),
    ];

    // 2. ROBOTICS & AI
    final List<DashboardItem> roboticsApps = [
      DashboardItem(title: 'Teach Robot', subtitle: 'Train AI', icon: Icons.model_training_rounded, accentColor: Colors.deepOrangeAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RobotScreen()))),
      DashboardItem(title: 'Generative AI', subtitle: 'QubiQAI Suite', icon: Icons.auto_awesome, accentColor: Colors.purple, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GenAIHubScreen()))),
      DashboardItem(title: 'Suno AI Music', subtitle: 'Create Songs', icon: Icons.music_note_rounded, accentColor: Colors.pink, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InAppWebViewScreen(url: 'https://suno.com', title: 'Suno AI Music')))),
      if (Platform.isWindows) DashboardItem(title: 'Emmi Core', subtitle: 'Robot Manager', icon: Icons.apps_outage_rounded, accentColor: Colors.blue, onTap: _launchEmmiV2App),
    ];

    // 3. IMMERSIVE LEARNING
    final List<DashboardItem> learningApps = [
      DashboardItem(title: 'Little Emmi', subtitle: 'Learning', icon: Icons.child_care_outlined, accentColor: Colors.teal, onTap: () => Navigator.pushNamed(context, '/app/robot_workspace')),
      DashboardItem(title: 'Adaptive Quiz', subtitle: 'Practice', icon: Icons.psychology_outlined, accentColor: Colors.deepPurple, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdaptiveLearningMenu()))),
      DashboardItem(title: 'AR Learning', subtitle: '3D Science', icon: Icons.view_in_ar, accentColor: Colors.pinkAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ARDashboard()))),
      DashboardItem(title: 'Assemblr Edu', subtitle: '3D EduKits', icon: Icons.layers_outlined, accentColor: Colors.cyan, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InAppWebViewScreen(url: 'https://edu.assemblrworld.com/edukits', title: 'Assemblr EduKits')))),
    ];

    // 4. PRODUCTIVITY (Separated Apps)
    final List<DashboardItem> productivityApps = [
      DashboardItem(
          title: 'Microsoft Word',
          subtitle: 'Documents',
          icon: Icons.description_outlined,
          accentColor: Colors.blue[700]!,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InAppWebViewScreen(url: 'https://www.microsoft365.com/launch/word', title: 'Microsoft Word')))
      ),
      DashboardItem(
          title: 'Microsoft Excel',
          subtitle: 'Spreadsheets',
          icon: Icons.table_chart_outlined,
          accentColor: Colors.green[700]!,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InAppWebViewScreen(url: 'https://www.microsoft365.com/launch/excel', title: 'Microsoft Excel')))
      ),
      DashboardItem(
          title: 'PowerPoint',
          subtitle: 'Presentations',
          icon: Icons.slideshow_outlined,
          accentColor: Colors.orange[800]!,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InAppWebViewScreen(url: 'https://www.microsoft365.com/launch/powerpoint', title: 'Microsoft PowerPoint')))
      ),
    ];

    // Define Categories for UI
    final List<_CategoryTile> categories = [
      _CategoryTile(name: "Coding Lab", icon: Icons.code_rounded, color: Colors.orange, items: codingApps),
      _CategoryTile(name: "Robotics & AI", icon: Icons.smart_toy_rounded, color: Colors.purple, items: roboticsApps),
      _CategoryTile(name: "Immersive Learning", icon: Icons.school_rounded, color: Colors.teal, items: learningApps),
      _CategoryTile(name: "Productivity", icon: Icons.work_rounded, color: Colors.indigo, items: productivityApps),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                  if (isMobile) Column(children: [_buildGlassProgressCard(), const SizedBox(height: 16), _buildStatsGrid(isMobile)])
                  else Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: _buildGlassProgressCard()), const SizedBox(width: 20), Expanded(flex: 5, child: _buildStatsGrid(isMobile))]),

                  const SizedBox(height: 30),
                  Text("Pending Assignments", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
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
                  // App Categories
                  ...categories.map((category) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: category.color.withOpacity(0.1),
                                    shape: BoxShape.circle
                                ),
                                child: Icon(category.icon, color: category.color, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                  category.name,
                                  style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey[800]
                                  )
                              ),
                            ],
                          ),
                        ),
                        // App Grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isMobile ? 3 : 5, // Responsive columns
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: category.items.length,
                          itemBuilder: (context, index) {
                            return _GlassAppCard(item: category.items[index], isPopup: false);
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  }),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // ✅ NEW: Non-intrusive Corner Notification
          Positioned(
            bottom: 24,
            right: 24,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(animation),
                child: child,
              ),
              child: _isOffline
                  ? Container(
                width: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 5))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Connection Lost",
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            "You can still use Flowchart and Python IDE.",
                            style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  : const SizedBox.shrink(), // Hides completely when online
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Student Portal", style: GoogleFonts.poppins(fontSize: 14, color: Colors.blueGrey[500], fontWeight: FontWeight.w600)), Text("Welcome, $_userName", style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]), softWrap: true, maxLines: 2)])),
        const SizedBox(width: 16),
        Container(
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
          child: IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LittleEmmiLoginScreen())),
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildRealProjectTile(BuildContext context, Map<String, dynamic> data, String docId) {
    String tool = data['tool'] ?? 'General';
    DateTime? dueDate = data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null;
    Color accentColor = tool.contains('Python') ? Colors.amber.shade700 : tool.contains('Flowchart') ? Colors.orange : tool.contains('Emmi') ? Colors.teal : (tool.contains('AR') || tool.contains('3D')) ? Colors.pinkAccent : Colors.blue;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AssignmentDetailScreen(assignmentData: data, docId: docId))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white)),
        child: Row(
          children: [
            Container(height: 40, width: 4, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['title'] ?? 'Untitled', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.blueGrey[800], fontSize: 15)), Text(dueDate != null ? "Due: ${DateFormat('MMM dd').format(dueDate)}" : "No Due Date", style: GoogleFonts.poppins(color: Colors.blueGrey[400], fontSize: 12))])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text("Start >", style: GoogleFonts.poppins(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)))
          ],
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildGlassProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(children: [CircularPercentIndicator(radius: 45.0, lineWidth: 8.0, animation: true, percent: 0.75, center: Text("75%", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18.0, color: Colors.indigo)), circularStrokeCap: CircularStrokeCap.round, progressColor: Colors.indigoAccent, backgroundColor: Colors.indigo.withOpacity(0.1)), const SizedBox(height: 16), Text("Overall Progress", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey[900])), Text("Keep it up!", style: GoogleFonts.poppins(fontSize: 12, color: Colors.blueGrey[500]))]),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }

  Widget _buildStatsGrid(bool isMobile) {
    return GridView.count(crossAxisCount: isMobile ? 2 : 4, crossAxisSpacing: 12, mainAxisSpacing: 12, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.0, children: [_buildStatTile("Projects", "12", Icons.folder_copy_outlined, Colors.blue), _buildStatTile("Tests", "5/6", Icons.assignment_turned_in_outlined, Colors.green), _buildStatTile("Pending", "2", Icons.hourglass_top_outlined, Colors.orange), _buildStatTile("Rank", "#4", Icons.emoji_events_outlined, Colors.purple)]).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildStatTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 20), const SizedBox(height: 8), Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[900])), Text(title, style: GoogleFonts.poppins(fontSize: 11, color: Colors.blueGrey[500]))]),
    );
  }
}

// ✅ HELPER CLASS FOR CATEGORIES
class _CategoryTile {
  final String name;
  final IconData icon;
  final Color color;
  final List<DashboardItem> items;
  _CategoryTile({required this.name, required this.icon, required this.color, required this.items});
}

class AssignmentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> assignmentData;
  final String docId;
  const AssignmentDetailScreen({super.key, required this.assignmentData, required this.docId});

  void _showInfoPopup(BuildContext context, String title, String message) {
    showDialog(context: context, builder: (context) => Center(child: Container(width: MediaQuery.of(context).size.width * 0.8, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)]), child: Material(color: Colors.transparent, child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.info_outline_rounded, color: Colors.indigo, size: 48), const SizedBox(height: 16), Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14)), const SizedBox(height: 24), ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("OK", style: TextStyle(color: Colors.white)))])))).animate().scale().fadeIn());
  }
  void _launchAssignedTool(BuildContext context, String toolName) {
    if (toolName.contains("Python")) Navigator.push(context, MaterialPageRoute(builder: (context) => const PythonIdeScreen()));
    else if (toolName.contains("Flowchart")) Navigator.push(context, MaterialPageRoute(builder: (context) => const FlowchartIdeScreen()));
    else if (toolName.contains("App Inventor") || toolName.contains("Mobile")) Navigator.push(context, MaterialPageRoute(builder: (context) => const MitDashboardScreen()));
    else if (toolName.contains("Little Emmi")) Navigator.pushNamed(context, '/app/robot_workspace');
    else if (toolName.contains("AR") || toolName.contains("3D")) Navigator.push(context, MaterialPageRoute(builder: (context) => ARDashboard()));
    else _showInfoPopup(context, "Manual Start Required", "The tool '$toolName' is not integrated for auto-launch. Please open it from the dashboard.");
  }
  @override
  Widget build(BuildContext context) {
    String tool = assignmentData['tool'] ?? 'None';
    DateTime? dueDate = assignmentData['dueDate'] != null ? (assignmentData['dueDate'] as Timestamp).toDate() : null;
    return Scaffold(backgroundColor: const Color(0xFFF8FAFC), appBar: AppBar(title: Text("Assignment Details", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: Colors.black)), body: Padding(padding: const EdgeInsets.all(24.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(24), width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(tool, style: GoogleFonts.poppins(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 12))), const Spacer(), Icon(Icons.access_time, size: 16, color: Colors.grey[600]), const SizedBox(width: 4), Text(dueDate != null ? DateFormat('MMM dd, hh:mm a').format(dueDate) : "No Due Date", style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12))]), const SizedBox(height: 16), Text(assignmentData['title'] ?? 'Assignment', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey[900])), const SizedBox(height: 8), Text("Assigned by ${assignmentData['teacherName'] ?? 'Teacher'}", style: GoogleFonts.poppins(fontSize: 14, color: Colors.blueGrey[500]))])), const SizedBox(height: 24), Text("Instructions", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])), const SizedBox(height: 12), Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Text(assignmentData['description'] ?? 'No instructions.', style: GoogleFonts.poppins(fontSize: 15, color: Colors.blueGrey[700], height: 1.6))), const Spacer(), SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(onPressed: () => _launchAssignedTool(context, tool), icon: const Icon(Icons.rocket_launch, color: Colors.white), label: Text("Launch $tool", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4)))])));
  }
}

class _GlassAppCard extends StatelessWidget {
  final DashboardItem item;
  final bool isPopup;
  const _GlassAppCard({required this.item, this.isPopup = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if(isPopup) Navigator.pop(context); // Close dialog
        item.onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isPopup ? Colors.grey.shade200 : Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: item.accentColor.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.accentColor, size: 20),
            ),
            const Spacer(),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]),
            ),
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.blueGrey[400]),
            ),
          ],
        ),
      ),
    );
  }
}

class PastelAnimatedBackground extends StatefulWidget { const PastelAnimatedBackground({super.key}); @override State<PastelAnimatedBackground> createState() => _PastelAnimatedBackgroundState(); }
class _PastelAnimatedBackgroundState extends State<PastelAnimatedBackground> { late Timer timer; final Random random = Random(); double top1 = 0.1, left1 = 0.1, top2 = 0.5, left2 = 0.5; @override void initState() { super.initState(); timer = Timer.periodic(const Duration(seconds: 5), (timer) { if (mounted) setState(() { top1 = random.nextDouble(); left1 = random.nextDouble(); top2 = random.nextDouble(); left2 = random.nextDouble(); }); }); } @override void dispose() { timer.cancel(); super.dispose(); } @override Widget build(BuildContext context) { final size = MediaQuery.of(context).size; return ClipRect(child: Stack(children: [AnimatedPositioned(duration: const Duration(seconds: 5), curve: Curves.easeInOut, top: top1 * (size.height - 200), left: left1 * (size.width - 200), child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.15)))), AnimatedPositioned(duration: const Duration(seconds: 5), curve: Curves.easeInOut, top: top2 * (size.height - 200), left: left2 * (size.width - 200), child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purple.withOpacity(0.15)))), BackdropFilter(filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50), child: Container(color: Colors.white.withOpacity(0.1)))])); } }

class DashboardItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  DashboardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });
}