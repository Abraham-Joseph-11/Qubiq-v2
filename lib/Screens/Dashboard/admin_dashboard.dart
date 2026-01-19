import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ Correct Import
import 'package:little_emmi/Screens/Auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // 👤 Admin Details
  String _adminSchoolId = "";
  String _adminName = "";

  // 📊 Dynamic Statistics
  int _studentCount = 0;
  int _teacherCount = 0;
  double _avgAttendance = 0.0;
  double _avgGrades = 0.0;
  double _avgSatisfaction = 0.0;

  // 📅 Attendance Viewer State
  DateTime _selectedDate = DateTime.now();
  String? _selectedClassForAttendance;

  // 🏫 Master List of Classes
  final List<String> _allSchoolClasses = [
    'Class 1-A', 'Class 1-B',
    'Class 5-A', 'Class 5-B',
    'Class 10-A', 'Robotics Club',
    'Math', 'Science', 'English'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchAdminDetails();
    _fetchSchoolStats();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  // 👤 1. FETCH ADMIN INFO
  Future<void> _fetchAdminDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            _adminSchoolId = data['schoolId'] ?? "";
            _adminName = data['name'] ?? "Admin";
          });
        }
      } catch (e) {
        debugPrint("Error fetching admin details: $e");
      }
    }
  }

  // 🏫 2. ASSIGN CLASSES DIALOG
  Future<void> _assignClassesToTeacher(String teacherId, String teacherName, List<dynamic> currentClasses) async {
    List<String> selectedClasses = List<String>.from(currentClasses);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text("Assign Classes: $teacherName", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 300,
                height: 300,
                child: Column(
                  children: [
                    Text("Select the classes this teacher manages:", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _allSchoolClasses.length,
                        itemBuilder: (context, index) {
                          final className = _allSchoolClasses[index];
                          final isSelected = selectedClasses.contains(className);
                          return CheckboxListTile(
                            title: Text(className),
                            value: isSelected,
                            activeColor: Colors.indigo,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  selectedClasses.add(className);
                                } else {
                                  selectedClasses.remove(className);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('users').doc(teacherId).update({
                      'assignedClasses': selectedClasses
                    });
                    if (mounted) Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Updated classes for $teacherName")));
                  },
                  child: const Text("Save Assignments"),
                )
              ],
            );
          }
      ),
    );
  }

  // 📢 3. BROADCAST DIALOG
  Future<void> _showBroadcastDialog() async {
    if (_adminSchoolId.isEmpty) await _fetchAdminDetails();
    if (_adminSchoolId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: No School ID found."), backgroundColor: Colors.red));
      return;
    }
    String message = "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Make Announcement"),
        content: TextField(
          onChanged: (v) => message = v,
          maxLines: 3,
          decoration: const InputDecoration(hintText: "Message to all students/teachers...", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (message.isEmpty) return;
              await FirebaseFirestore.instance.collection('broadcasts').add({
                'schoolId': _adminSchoolId,
                'sender': _adminName,
                'message': message,
                'timestamp': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Broadcast Sent!")));
            },
            child: const Text("Send"),
          )
        ],
      ),
    );
  }

  // 🔄 4. FETCH STATS
  Future<void> _fetchSchoolStats() async {
    try {
      final sSnap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').get();
      final tSnap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'teacher').get();

      double totalAtt = 0;
      double totalGrd = 0;
      int statCount = 0;

      for (var doc in sSnap.docs) {
        final data = doc.data();
        totalAtt += (data['attendance'] ?? 0).toDouble();
        totalGrd += (data['averageGrade'] ?? 0).toDouble();
        statCount++;
      }

      if (mounted) {
        setState(() {
          _studentCount = sSnap.size;
          _teacherCount = tSnap.size;
          _avgAttendance = statCount > 0 ? (totalAtt / statCount) / 100 : 0.0;
          _avgGrades = statCount > 0 ? (totalGrd / statCount) / 100 : 0.0;
          _avgSatisfaction = 0.88;
        });
      }
    } catch (e) { print(e); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      body: Stack(
        children: [
          const Positioned.fill(child: PastelAnimatedBackground()),
          SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(child: _buildTabBar()),
              ],
              body: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildOverviewTab(),
                  _buildUserListTab(role: 'teacher'),
                  _buildUserListTab(role: 'student'),
                  _buildAttendanceTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeader(BuildContext context) {
    String date = DateFormat.yMMMEd().format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date.toUpperCase(), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey.withOpacity(0.6))),
              const SizedBox(height: 4),
              Text("School Admin", style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            ],
          ),
          _GlassCard(
            borderRadius: 50, padding: const EdgeInsets.all(8),
            child: IconButton(
              icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
              onPressed: () => FirebaseAuth.instance.signOut().then(
                // ✅ FIXED: Removed isSchool: true
                      (_) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LittleEmmiLoginScreen()))
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      height: 75,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white), boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.04), blurRadius: 25, offset: const Offset(0, 8))]),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.blue.withOpacity(0.1))),
          labelColor: const Color(0xFF2563EB), unselectedLabelColor: Colors.blueGrey[300],
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [Tab(text: "Overview"), Tab(text: "Teachers"), Tab(text: "Students"), Tab(text: "Attendance")],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: _buildStatCard("Students", "$_studentCount", Icons.school_rounded, const Color(0xFF3B82F6), const Color(0xFFEFF6FF))),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard("Teachers", "$_teacherCount", Icons.cast_for_education_rounded, const Color(0xFFF59E0B), const Color(0xFFFFFBEB))),
          ]).animate().slideY(begin: 0.2, duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          _GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _buildCircularIndicator("Attendance", _avgAttendance, Colors.teal),
              Container(width: 1, height: 50, color: Colors.grey.withOpacity(0.2)),
              _buildCircularIndicator("Avg Grades", _avgGrades, Colors.indigo),
              Container(width: 1, height: 50, color: Colors.grey.withOpacity(0.2)),
              _buildCircularIndicator("Satisfaction", _avgSatisfaction, Colors.pinkAccent),
            ]),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 24),
          Text("Quick Actions", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          const SizedBox(height: 16),
          SizedBox(height: 100, child: ListView(scrollDirection: Axis.horizontal, children: [
            _buildActionBtn(Icons.campaign_rounded, "Broadcast", Colors.orange, _showBroadcastDialog),
            _buildActionBtn(Icons.calendar_month_rounded, "Events", Colors.purple, () {}),
            _buildActionBtn(Icons.settings_rounded, "Settings", Colors.grey, () {}),
          ])),
        ],
      ),
    );
  }

  Widget _buildUserListTab({required String role}) {
    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), child: _GlassCard(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(controller: _searchController, decoration: const InputDecoration(border: InputBorder.none, hintText: "Search...", icon: Icon(Icons.search))))),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: role).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final users = snapshot.data!.docs.where((doc) {
              final d = doc.data() as Map<String,dynamic>;
              return (d['name']??'').toString().toLowerCase().contains(_searchQuery);
            }).toList();

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final data = users[index].data() as Map<String, dynamic>;
                List<dynamic> assignedClasses = data['assignedClasses'] ?? [];

                return _GlassCard(
                  margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Row(children: [
                      Container(width: 50, height: 50, decoration: BoxDecoration(color: role == 'teacher' ? Colors.orange[50] : Colors.blue[50], borderRadius: BorderRadius.circular(14)), child: Icon(role=='teacher'?Icons.history_edu_rounded:Icons.backpack_rounded, color: role=='teacher'?Colors.orange:Colors.blue)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['name']??'Unknown', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)), Text(data['email']??'', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey))])),
                      if (role == 'teacher') IconButton(icon: const Icon(Icons.class_outlined, color: Colors.indigo), onPressed: () => _assignClassesToTeacher(users[index].id, data['name'], assignedClasses))
                    ]),
                    if (role == 'teacher' && assignedClasses.isNotEmpty) ...[
                      const Divider(), Align(alignment: Alignment.centerLeft, child: Wrap(spacing: 6, children: assignedClasses.map((c) => Chip(label: Text(c, style: const TextStyle(fontSize: 10)), backgroundColor: Colors.indigo[50])).toList()))
                    ]
                  ]),
                );
              },
            );
          },
        ),
      ),
    ]);
  }

  // --- 🆕 ATTENDANCE TAB (With Console Print) ---
  Widget _buildAttendanceTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16), margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("View Records", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(hint: const Text("Select Class"), value: _selectedClassForAttendance, isExpanded: true, items: _allSchoolClasses.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => _selectedClassForAttendance = v))))),
                const SizedBox(width: 12),
                GestureDetector(onTap: () async { DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now()); if (picked != null) setState(() => _selectedDate = picked); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(12)), child: Text(DateFormat('MMM dd').format(_selectedDate), style: TextStyle(color: Colors.indigo[900], fontWeight: FontWeight.bold)))),
              ]),
            ],
          ),
        ),
        Expanded(
          child: (_selectedClassForAttendance == null)
              ? Center(child: Text("Select class to view records", style: GoogleFonts.poppins(color: Colors.grey)))
              : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('attendance')
                .where('class', isEqualTo: _selectedClassForAttendance)
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                // ✅ PRINTING ERROR TO CONSOLE
                print("\n\n🔥 FIRESTORE ERROR: ${snapshot.error}\n\n");
                return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("Error! Check your Terminal for the Index Link.", style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)));
              }
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              var docs = snapshot.data!.docs.where((doc) {
                Timestamp ts = doc['date'];
                DateTime dt = ts.toDate();
                return dt.year == _selectedDate.year && dt.month == _selectedDate.month && dt.day == _selectedDate.day;
              }).toList();

              if (docs.isEmpty) return Center(child: Text("No records for this date.", style: GoogleFonts.poppins(color: Colors.grey)));

              var recordDoc = docs.first.data() as Map<String, dynamic>;
              Map<String, dynamic> records = recordDoc['records'] ?? {};

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').get(),
                builder: (context, studentSnap) {
                  if(!studentSnap.hasData) return const LinearProgressIndicator();
                  Map<String, String> studentNames = {};
                  for(var s in studentSnap.data!.docs) {
                    studentNames[s.id] = s['name'];
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      Center(child: Chip(label: Text("Marked by: ${recordDoc['teacher']}"), backgroundColor: Colors.green[50])),
                      ...records.entries.map((entry) {
                        String name = studentNames[entry.key] ?? "ID: ${entry.key}";
                        bool isPresent = entry.value == true;
                        return _GlassCard(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: isPresent ? Colors.green[100] : Colors.red[100], borderRadius: BorderRadius.circular(20)), child: Text(isPresent ? "Present" : "Absent", style: TextStyle(color: isPresent ? Colors.green[800] : Colors.red[800], fontSize: 12, fontWeight: FontWeight.bold)))
                        ]));
                      })
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- HELPERS ---
  Widget _buildStatCard(String title, String count, IconData icon, Color primary, Color bg) {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, color: primary, size: 24)), Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey[400])]), const SizedBox(height: 20), Text(count, style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold)), Text(title, style: GoogleFonts.poppins(fontSize: 14, color: Colors.blueGrey[500]))]));
  }
  Widget _buildCircularIndicator(String label, double percent, Color color) {
    return Column(children: [CircularPercentIndicator(radius: 35.0, lineWidth: 6.0, percent: percent, center: Text("${(percent * 100).toInt()}%", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: color)), progressColor: color, backgroundColor: color.withOpacity(0.1), circularStrokeCap: CircularStrokeCap.round), const SizedBox(height: 10), Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey[600]))]);
  }
  Widget _buildActionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(width: 80, margin: const EdgeInsets.only(right: 12), child: Column(children: [Container(height: 60, width: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: Icon(icon, color: color, size: 28)), const SizedBox(height: 8), Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.blueGrey[700]))])));
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child; final EdgeInsetsGeometry? padding; final EdgeInsetsGeometry? margin; final double borderRadius;
  const _GlassCard({required this.child, this.padding, this.margin, this.borderRadius = 20});
  @override
  Widget build(BuildContext context) => Container(margin: margin, decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))]), child: ClipRRect(borderRadius: BorderRadius.circular(borderRadius), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(padding: padding, decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(borderRadius), border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5)), child: child))));
}
class PastelAnimatedBackground extends StatelessWidget { const PastelAnimatedBackground({super.key}); @override Widget build(BuildContext context) => Container(color: const Color(0xFFF8FAFC)); }