import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../Models/AdminModels.dart'; // Import MockTeacher

class InstitutionAdminScreen extends StatefulWidget {
  const InstitutionAdminScreen({super.key});

  @override
  State<InstitutionAdminScreen> createState() => _InstitutionAdminScreenState();
}

class _InstitutionAdminScreenState extends State<InstitutionAdminScreen> {
  // MOCK STATE - Replace with Provider/Firestore later
  final List<MockTeacher> _teachers = [
    MockTeacher(id: Uuid().v4(), name: 'Ms. Smith', email: 'ms.s@inst.com', gradeLevel: 0),
    MockTeacher(id: Uuid().v4(), name: 'Mr. Jones', email: 'mr.j@inst.com', gradeLevel: 0),
    MockTeacher(id: Uuid().v4(), name: 'Dr. Lee', email: 'dr.l@inst.com', gradeLevel: 0),
    MockTeacher(id: Uuid().v4(), name: 'Mrs. Patel', email: 'mrs.p@inst.com', gradeLevel: 7), // Already assigned
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Grade list for GridView
  final List<int> _grades = List.generate(12, (index) => index + 1);

  void _addTeacher() {
    setState(() {
      final newName = _nameController.text.trim();
      final newEmail = _emailController.text.trim();
      if (newName.isNotEmpty && newEmail.isNotEmpty) {
        _teachers.add(MockTeacher(id: Uuid().v4(), name: newName, email: newEmail));
        _nameController.clear();
        _emailController.clear();
        Navigator.pop(context);
      }
    });
  }

  void _deleteTeacher(String id) {
    setState(() {
      _teachers.removeWhere((t) => t.id == id);
    });
  }

  void _assignTeacher(String teacherId, int grade) {
    setState(() {
      final teacherIndex = _teachers.indexWhere((t) => t.id == teacherId);
      if (teacherIndex != -1) {
        // Ensure the teacher is only assigned to one grade
        _teachers[teacherIndex].gradeLevel = grade;
      }
    });
  }

  void _unassignTeacher(String teacherId) {
    setState(() {
      final teacherIndex = _teachers.indexWhere((t) => t.id == teacherId);
      if (teacherIndex != -1) {
        _teachers[teacherIndex].gradeLevel = 0;
      }
    });
  }

  void _showAddTeacherDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Teacher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email (login ID)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: _addTeacher,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unassignedTeachers = _teachers.where((t) => t.gradeLevel == 0).toList();

    return Scaffold(
      appBar: AppBar(
        // VVV --- GO BACK TO LOGIN --- VVV
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          tooltip: 'Logout',
        ),
        // ^^^ -------------------------- ^^^
        title: Text('Institution Admin Panel', style: GoogleFonts.poppins()),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddTeacherDialog,
            tooltip: 'Add Teacher',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Panel 1: Unassigned Teachers (Source for Dragging)
          Container(
            width: 250,
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Unassigned Teachers', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: unassignedTeachers.map((teacher) => _buildTeacherDraggable(teacher)).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Panel 2: Grade Assignment Grid (Drop Targets)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: 12, // Grades 1 through 12
              itemBuilder: (context, index) {
                final grade = _grades[index];
                // Find the teacher currently assigned to this grade
                final assignedTeacher = _teachers.firstWhere(
                        (t) => t.gradeLevel == grade,
                    orElse: () => MockTeacher(id: 'none', name: 'Unassigned', email: 'none'));

                return DragTarget<String>(
                  onWillAccept: (teacherId) => true, // Accept any teacher ID
                  onAccept: (teacherId) {
                    // 1. If a teacher is already here, unassign them first
                    if (assignedTeacher.id != 'none') {
                      _unassignTeacher(assignedTeacher.id);
                    }
                    // 2. Assign the new teacher to this grade
                    _assignTeacher(teacherId, grade);
                  },
                  builder: (context, candidate, rejected) {
                    return _buildGradeDropTarget(grade, assignedTeacher, candidate.isNotEmpty);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherDraggable(MockTeacher teacher) {
    // The Draggable item passes the teacher's ID (String)
    return Draggable<String>(
      data: teacher.id,
      feedback: Material(
        elevation: 6,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.blueAccent, borderRadius: BorderRadius.circular(8)),
          child: Text(teacher.name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
      child: Card(
        color: Colors.white,
        child: ListTile(
          dense: true,
          title: Text(teacher.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black87)),
          trailing: IconButton(
            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
            onPressed: () => _deleteTeacher(teacher.id),
          ),
        ),
      ),
    );
  }

  Widget _buildGradeDropTarget(int grade, MockTeacher assignedTeacher, bool isDraggingOver) {
    final isAssigned = assignedTeacher.id != 'none';

    return Container(
      decoration: BoxDecoration(
        color: isDraggingOver ? Colors.blue.withOpacity(0.2) : (isAssigned ? Colors.lightBlue.shade50 : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isAssigned ? Colors.blueAccent : Colors.grey.shade300, width: isDraggingOver ? 3 : 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Grade $grade', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          if (isAssigned)
            Text(assignedTeacher.name, style: GoogleFonts.poppins(color: Colors.blueAccent.shade700, fontWeight: FontWeight.w600))
          else
            Text('Drag Teacher Here', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}