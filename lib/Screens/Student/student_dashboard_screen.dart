import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// VVV --- FIX: Point to the functional model file --- VVV
import '../../Models/AdminModels.dart';
// ^^^ ---------------------------------------------- ^^^

// Mock list of all apps and their icons/routes for the Student to use
const Map<String, dynamic> appRoutes = {
  'Little Emmi': {'route': '/app/robot_workspace', 'icon': Icons.child_care_outlined},
  'Flowchart Coder': {'route': '/app/flowchart_ide', 'icon': Icons.account_tree_outlined},
  'MIT App Inventor': {'route': '/mit/login', 'icon': Icons.extension_outlined},
  'Python IDE': {'route': '/app/python_ide', 'icon': Icons.code_outlined},
};

class StudentDashboardScreen extends StatelessWidget {
  final MockTeacher teacher; // Teacher's assignment data is passed here

  const StudentDashboardScreen({
    super.key,
    required this.teacher,
  });

  // --- Utility to Launch Apps (Routes) ---
  void _openApp(BuildContext context, String appName, String route) {
    // Note: Since this is an external app, we use pushNamed.
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final assignedGrade = teacher.gradeLevel;
    // Get the specific assignments for this student's grade (e.g., Grade 8 map)
    // This call is now defined in the imported MockTeacher
    final assignments = teacher.getCurrentAssignments();

    // Extract chapter and enabled apps
    final assignedChapter = assignments['chapter'] ?? 'Not Assigned';

    // Filter apps that have 'true' access based on the teacher's map
    final enabledApps = appRoutes.keys.where((appName) {
      return assignments[appName] == true;
    }).toList();


    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          tooltip: 'Logout',
        ),
        title: Text('Student Dashboard (Grade $assignedGrade)', style: GoogleFonts.poppins()),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Student!',
              style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),

            // --- 1. CURRENT CURRICULUM ASSIGNMENT ---
            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.menu_book, color: Colors.teal),
                title: Text('Current Chapter', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                // The assignedChapter will read "Chapter 1: Basics" from the mock data
                subtitle: Text(assignedChapter, style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 30),

            // --- 2. ASSIGNED APPS (Clickable) ---
            Text(
              'Assigned Coding Tools:',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 10),

            if (enabledApps.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'No apps have been assigned yet. Please check with your teacher.',
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.5,
                ),
                itemCount: enabledApps.length,
                itemBuilder: (context, index) {
                  final appName = enabledApps[index];
                  final appData = appRoutes[appName]!;

                  return Card(
                    color: Colors.lightGreen.shade50,
                    elevation: 3,
                    child: InkWell(
                      onTap: () => _openApp(context, appName, appData['route']),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(appData['icon'], size: 30, color: Colors.green.shade700),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                appName,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
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