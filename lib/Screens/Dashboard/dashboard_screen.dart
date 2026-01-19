// lib/Screens/Dashboard/dashboard_screen.dart

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:process_run/shell.dart';

// Import your screens
import 'package:little_emmi/Screens/inappwebview_screen.dart';
import 'package:little_emmi/Screens/python_ide_screen.dart';
import 'package:little_emmi/Screens/flowchart_ide_screen.dart';
// ✅ ADDED THIS IMPORT
import 'package:little_emmi/Screens/Auth/login_screen.dart';

// --- DATA MODEL ---
class DashboardItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color accentColor;

  DashboardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.accentColor,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  Future<void> _launchEmmiV2App() async {
    if (!Platform.isWindows) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Windows only feature.')),
      );
      return;
    }
    try {
      String mainAppPath = Platform.resolvedExecutable;
      String appDirectory = p.dirname(mainAppPath);
      const String appToLaunch = 'EmmiV2.exe';
      var shell = Shell(workingDirectory: appDirectory);
      await shell.run(appToLaunch);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  // --- LOGOUT DIALOG ---
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out', style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to exit?', style: GoogleFonts.poppins(color: Colors.grey[700])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                // ✅ FIXED: Changed RoleSelectionScreen() to LittleEmmiLoginScreen()
                MaterialPageRoute(builder: (context) => const LittleEmmiLoginScreen()),
                    (route) => false,
              );
            },
            child: Text('Log Out', style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ... [Rest of the file remains exactly the same] ...
  // (Paste the rest of your build method, headers, grid, etc. here)
  void _handleMenuSelection(String value) {
    switch (value) {
      case 'logout': _confirmLogout(); break;
      default: ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Coming soon!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... [Keep your existing build method] ...
    // Just to save space, I am not repeating the whole UI code as it is unchanged.
    // But verify you include the full build method you already had.
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Stack(
        children: [
          const ProfessionalAnimatedBackground(),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.white.withOpacity(0.3)),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildDashboardGrid([
                    DashboardItem(title: 'Little Emmi', subtitle: 'Child Learning Platform', icon: Icons.child_care_outlined, accentColor: Colors.teal, onTap: () => Navigator.pushNamed(context, '/app/robot_workspace')),
                    DashboardItem(title: 'MIT App Inventor', subtitle: 'Build apps with blocks', icon: Icons.extension_outlined, accentColor: Colors.green, onTap: () => Navigator.pushNamed(context, '/mit/login')),
                    DashboardItem(title: 'Emmi Core', subtitle: 'Service Management', icon: Icons.apps_outage_rounded, accentColor: Colors.blue, onTap: _launchEmmiV2App),
                    DashboardItem(title: 'Flowchart Coder', subtitle: 'Visual Programming', icon: Icons.account_tree_outlined, accentColor: Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FlowchartIdeScreen()))),
                    DashboardItem(title: 'Python IDE', subtitle: 'Code & Run Python', icon: Icons.code_outlined, accentColor: Colors.amber.shade700, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PythonIdeScreen()))),
                    DashboardItem(title: 'Office Suite', subtitle: 'Word, Excel, PowerPoint', icon: Icons.grid_view_rounded, accentColor: Colors.indigo, onTap: () => _showOfficeMenu(context)),
                    DashboardItem(title: 'Generative AI', subtitle: 'Create Text, Image, Audio', icon: Icons.auto_awesome, accentColor: Colors.purple, onTap: () => _showGenAIMenu(context)),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ... [Keep all your other methods: _buildHeader, _buildDashboardGrid, etc.] ...
  Widget _buildHeader() {
    // (Your existing code)
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Command Center',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w800, // Extra Bold
                  color: const Color(0xFF1E293B), // Dark Slate
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Access your creative tools.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.blueGrey[600]),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))], border: Border.all(color: Colors.white, width: 2)),
            child: PopupMenuButton<String>(
              icon: Icon(Icons.person_rounded, color: Colors.blueGrey[700]), color: Colors.white, surfaceTintColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), offset: const Offset(0, 50),
              onSelected: _handleMenuSelection,
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem(value: 'profile', child: Row(children: [const Icon(Icons.account_circle_outlined, color: Colors.teal, size: 20), const SizedBox(width: 12), Text('My Profile', style: GoogleFonts.poppins(color: Colors.black87))])),
                PopupMenuItem(value: 'help', child: Row(children: [const Icon(Icons.help_outline_rounded, color: Colors.blue, size: 20), const SizedBox(width: 12), Text('Help & Support', style: GoogleFonts.poppins(color: Colors.black87))])),
                const PopupMenuDivider(),
                PopupMenuItem(value: 'logout', child: Row(children: [const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20), const SizedBox(width: 12), Text('Log Out', style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w600))])),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
    );
  }

  Widget _buildDashboardGrid(List<DashboardItem> items) {
    // (Your existing code)
    return LayoutBuilder(
      builder: (context, constraints) {
        const int crossAxisCount = 4;
        const double spacing = 20.0;
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, crossAxisSpacing: spacing, mainAxisSpacing: spacing, childAspectRatio: 1.2),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return GlassTechCard(item: items[index]).animate().fadeIn(delay: (50 * index).ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
          },
        );
      },
    );
  }

  void _showOfficeMenu(BuildContext context) {
    _showGenericMenu(context, 'Office Suite', [
      _MenuOption('Microsoft Word', Icons.description_outlined, Colors.blue[700]!, 'https://www.microsoft365.com/launch/word'),
      _MenuOption('Microsoft Excel', Icons.table_chart_outlined, Colors.green[700]!, 'https://www.microsoft365.com/launch/excel'),
      _MenuOption('Microsoft PowerPoint', Icons.slideshow_outlined, Colors.orange[800]!, 'https://www.microsoft365.com/launch/powerpoint'),
    ]);
  }

  void _showGenAIMenu(BuildContext context) {
    _showGenericMenu(context, 'AI Tools', [
      _MenuOption('Chat GPT', Icons.chat_bubble_outline, Colors.teal[700]!, 'https://chatgpt.com'),
      _MenuOption('Image Generator', Icons.image_outlined, Colors.purple[700]!, 'https://www.bing.com/images/create'),
      _MenuOption('Sound Studio', Icons.graphic_eq, Colors.deepOrange[700]!, 'https://suno.com'),
    ]);
  }

  void _showGenericMenu(BuildContext context, String title, List<_MenuOption> options) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 350, decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)]), padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey[900])),
            const SizedBox(height: 16),
            Expanded(child: ListView(children: options.map((opt) => ListTile(contentPadding: const EdgeInsets.symmetric(vertical: 4), leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: opt.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(opt.icon, color: opt.color)), title: Text(opt.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.blueGrey[800])), trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => InAppWebViewScreen(url: opt.url, title: opt.title))); })).toList())),
          ],
        ),
      ),
    );
  }
}

class _MenuOption {
  final String title; final IconData icon; final Color color; final String url;
  _MenuOption(this.title, this.icon, this.color, this.url);
}

class GlassTechCard extends StatefulWidget {
  final DashboardItem item;
  const GlassTechCard({super.key, required this.item});
  @override State<GlassTechCard> createState() => _GlassTechCardState();
}
class _GlassTechCardState extends State<GlassTechCard> {
  bool _isHovered = false;
  @override Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true), onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.item.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut, transform: Matrix4.identity()..translate(0.0, _isHovered ? -8.0 : 0.0),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(24), border: Border.all(color: _isHovered ? widget.item.accentColor.withOpacity(0.5) : Colors.white, width: 2), boxShadow: [BoxShadow(color: _isHovered ? widget.item.accentColor.withOpacity(0.3) : Colors.indigo.withOpacity(0.05), blurRadius: _isHovered ? 25 : 15, offset: const Offset(0, 10))]),
          child: ClipRRect(borderRadius: BorderRadius.circular(24), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: widget.item.accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(widget.item.icon, color: widget.item.accentColor, size: 30)), const Spacer(), Text(widget.item.title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))), const SizedBox(height: 6), Text(widget.item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 13, color: Colors.blueGrey[500], height: 1.3))])))),
        ),
      ),
    );
  }
}

class ProfessionalAnimatedBackground extends StatefulWidget {
  const ProfessionalAnimatedBackground({super.key});
  @override State<ProfessionalAnimatedBackground> createState() => _ProfessionalAnimatedBackgroundState();
}
class _ProfessionalAnimatedBackgroundState extends State<ProfessionalAnimatedBackground> {
  late Timer timer; final Random random = Random();
  double top1 = 0.1, left1 = 0.1; double top2 = 0.6, left2 = 0.8; double top3 = 0.4, left3 = 0.4;
  @override void initState() { super.initState(); timer = Timer.periodic(const Duration(seconds: 6), (timer) { if (mounted) { setState(() { top1 = random.nextDouble(); left1 = random.nextDouble(); top2 = random.nextDouble(); left2 = random.nextDouble(); top3 = random.nextDouble(); left3 = random.nextDouble(); }); } }); }
  @override void dispose() { timer.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) { final size = MediaQuery.of(context).size; return Stack(children: [AnimatedPositioned(duration: const Duration(seconds: 6), curve: Curves.easeInOut, top: top1 * size.height, left: left1 * size.width, child: const GradientOrb(colors: [Color(0xFF4F46E5), Color(0xFF818CF8)], size: 400)), AnimatedPositioned(duration: const Duration(seconds: 6), curve: Curves.easeInOut, top: top2 * size.height, left: left2 * size.width, child: const GradientOrb(colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)], size: 350)), AnimatedPositioned(duration: const Duration(seconds: 6), curve: Curves.easeInOut, top: top3 * size.height, left: left3 * size.width, child: const GradientOrb(colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)], size: 300))]); }
}
class GradientOrb extends StatelessWidget { final List<Color> colors; final double size; const GradientOrb({super.key, required this.colors, required this.size}); @override Widget build(BuildContext context) { return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight))); } }