import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../Models/AdminModels.dart'; // Import your existing models

class SchoolDataProvider extends ChangeNotifier {
  // --- 1. THE "DATABASE" (Lists of Data) ---
  final List<MockInstitution> _institutions = [
    // Default Data so the app isn't empty
    MockInstitution(id: 'inst-1', name: 'Global Tech Academy', teacherCount: 1, canUseMIT: true),
  ];

  final List<MockTeacher> _teachers = [
    MockTeacher(
        id: 'teacher-1',
        name: 'Ms. Frizzle',
        email: 'teacher@test.com',
        gradeLevel: 8,
        gradeAssignments: {
          8: {'chapter': 'Chapter 1: Basics', 'Python IDE': true}
        }
    ),
  ];

  // Map Student Email -> Assigned Teacher ID
  // (In a real app, students would have their own objects, but this is a shortcut)
  final Map<String, String> _studentEnrollments = {
    'student@test.com': 'teacher-1',
  };

  // --- 2. GETTERS (How screens read data) ---
  List<MockInstitution> get institutions => _institutions;
  List<MockTeacher> get teachers => _teachers;

  // Find a teacher by ID
  MockTeacher? getTeacherById(String id) {
    try {
      return _teachers.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  // Find which teacher a student is assigned to
  MockTeacher? getTeacherForStudent(String studentEmail) {
    final teacherId = _studentEnrollments[studentEmail];
    if (teacherId == null) return null;
    return getTeacherById(teacherId);
  }

  // --- 3. ACTIONS (How screens modify data) ---

  // Super Admin: Add Institution
  void addInstitution(String name) {
    _institutions.add(MockInstitution(id: const Uuid().v4(), name: name));
    notifyListeners(); // <--- Updates UI instantly
  }

  // Institution Admin: Add Teacher
  void addTeacher(String name, String email) {
    _teachers.add(MockTeacher(id: const Uuid().v4(), name: name, email: email));
    notifyListeners();
  }

  // Teacher: Update Curriculum
  void updateCurriculum(String teacherId, int grade, String key, dynamic value) {
    final index = _teachers.indexWhere((t) => t.id == teacherId);
    if (index != -1) {
      // Create a deep copy or modify the map directly if mutable
      if (!_teachers[index].gradeAssignments.containsKey(grade)) {
        _teachers[index].gradeAssignments[grade] = {};
      }
      _teachers[index].gradeAssignments[grade]![key] = value;
      notifyListeners(); // <--- This triggers the Student Dashboard to update
    }
  }
}