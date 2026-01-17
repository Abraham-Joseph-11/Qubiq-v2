import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. TEACHER: Update their assignments
  Future<void> updateClassSettings(String teacherUid, Map<String, dynamic> newAssignments) async {
    await _db.collection('users').doc(teacherUid).update({
      'curriculum': newAssignments,
    });
  }

  // 2. STUDENT: Get their specific teacher
  Stream<DocumentSnapshot?> getMyTeacherStream(String institutionId, int grade) {
    return _db
        .collection('users')
        .where('institutionId', isEqualTo: institutionId)
        .where('role', isEqualTo: 'teacher')
        .where('assignedGrade', isEqualTo: grade)
        .limit(1) // Assuming 1 teacher per grade
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first : null);
  }
}