import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

// Model for Institutions (Managed by Super Admin)
class MockInstitution {
  final String id;
  String name;
  int teacherCount; // <-- ADDED this getter for the Super Admin screen
  bool canUseMIT; // Example: App access control

  MockInstitution({
    required this.id,
    required this.name,
    this.teacherCount = 0, // Default to 0, will be updated by Admin
    this.canUseMIT = true
  });
}

// Model for Teachers (Managed by Institution Admin)
class MockTeacher {
  final String id;
  String name;
  String email;
  int gradeLevel; // 0 = unassigned, 1-12 = assigned

// This map holds assignments for all grades (e.g., Grade 8)
  final Map<int, Map<String, dynamic>> _globalAssignments = {
    8: { // Default assignments for Grade 8
      'chapter': 'Chapter 1: Basics',
      'Little Emmi': false,
      'Flowchart Coder': true,
      'MIT App Inventor': false,
      'Python IDE': false,
    }
  };
// --------------------------------------------------------------------

  // VVV --- Tracks content assigned to the teacher's grade --- VVV
  Map<int, Map<String, dynamic>> gradeAssignments;
  // ^^^ ----------------------------------------------------- ^^^

  MockTeacher({
    required this.id,
    required this.name,
    required this.email,
    this.gradeLevel = 0,
    this.gradeAssignments = const {}, // Initialize as an empty map
  });

  // VVV --- NEW: Method to access the global, live assignments for the user's grade --- VVV
  Map<String, dynamic> getCurrentAssignments() {
    return _globalAssignments[gradeLevel] ?? {};
  }

  // NEW: Method to modify assignments (used by the Teacher Dashboard)
  void setAssignment(String key, dynamic value) {
    if (gradeLevel != 0) {
      if (!_globalAssignments.containsKey(gradeLevel)) {
        _globalAssignments[gradeLevel] = {};
      }
      _globalAssignments[gradeLevel]![key] = value;
    }
  }

}