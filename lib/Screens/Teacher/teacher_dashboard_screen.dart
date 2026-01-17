import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Models/AdminModels.dart'; // Ensure this path is correct

// --- DATA CONSTANTS ---
const List<String> availableChapters = [
  'Chapter 1: Basics',
  'Chapter 2: Variables',
  'Chapter 3: Loops',
  'Chapter 4: Functions',
  'Chapter 5: AI Concepts'
];

const Map<String, IconData> availableApps = {
  'Little Emmi': Icons.child_care_outlined,
  'Flowchart Coder': Icons.account_tree_outlined,
  'MIT App Inventor': Icons.extension_outlined,
  'Python IDE': Icons.code_outlined,
};

class TeacherDashboardScreen extends StatefulWidget {
  final MockTeacher teacher;

  const TeacherDashboardScreen({
    super.key,
    required this.teacher,
  });

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  late MockTeacher _currentTeacher;

  // --- THEME COLORS ---
  final Color backgroundColor = const Color(0xFF1A1A2E);
  final Color cardColor = const Color(0xFF16213E);
  final Color accentColor = const Color(0xFF00BFA6);

  @override
  void initState() {
    super.initState();
    _currentTeacher = widget.teacher;
  }

  // --- LOGIC ---
  void _assignChapter(String chapter) {
    setState(() {
      final grade = _currentTeacher.gradeLevel;
      if (grade == 0) return;

      final gradeMap = _currentTeacher.gradeAssignments[grade] ?? {};
      gradeMap['chapter'] = chapter;
      _currentTeacher.gradeAssignments[grade] = gradeMap;
    });
  }

  void _toggleAppAccess(String appName, bool access) {
    setState(() {
      final grade = _currentTeacher.gradeLevel;
      if (grade == 0) return;

      final gradeMap = _currentTeacher.gradeAssignments[grade] ?? {};
      gradeMap[appName] = access;
      _currentTeacher.gradeAssignments[grade] = gradeMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    final grade = _currentTeacher.gradeLevel;
    final assignedChapter = _currentTeacher.gradeAssignments[grade]?['chapter'];

    // 1. Unassigned View
    if (grade == 0) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          title: const Text('Teacher Dashboard'),
          leading: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ),
        body: Center(
          child: Text(
            'You are not currently assigned to a class.',
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.white70),
          ),
        ),
      );
    }

    // 2. Main Dashboard
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.white70),
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          tooltip: 'Logout',
        ),
        title: Text(
          'Grade $grade Manager',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: accentColor.withOpacity(0.2),
                  child: Text(
                    _currentTeacher.name.isNotEmpty ? _currentTeacher.name.substring(0, 1) : 'T',
                    style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome Back,', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54)),
                    Text(_currentTeacher.name, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- SECTION 1: CHAPTER ASSIGNMENT ---
            Text('Curriculum Control', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: accentColor)),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Chapter', style: GoogleFonts.poppins(color: Colors.white70)),
                  const SizedBox(height: 5),
                  Text(
                    assignedChapter ?? 'Not Assigned',
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    dropdownColor: cardColor,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black12,
                      labelText: 'Change Chapter',
                      labelStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: Icon(Icons.menu_book, color: accentColor),
                    ),
                    value: assignedChapter,
                    items: availableChapters.map((chapter) {
                      return DropdownMenuItem(
                        value: chapter,
                        child: Text(chapter),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) _assignChapter(value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- SECTION 2: APP ACCESS ---
            Text('App Permissions', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: accentColor)),
            const SizedBox(height: 10),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: availableApps.length,
              itemBuilder: (context, index) {
                final appName = availableApps.keys.elementAt(index);
                final appIcon = availableApps.values.elementAt(index);
                final hasAccess = _currentTeacher.gradeAssignments[grade]?[appName] ?? false;

                return Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(15),
                    border: hasAccess ? Border.all(color: accentColor.withOpacity(0.5)) : null,
                  ),
                  child: SwitchListTile(
                    activeColor: accentColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    title: Text(appName, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.white, fontSize: 13)),
                    secondary: Icon(appIcon, color: hasAccess ? accentColor : Colors.white24, size: 20),
                    value: hasAccess,
                    onChanged: (bool value) {
                      _toggleAppAccess(appName, value);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}