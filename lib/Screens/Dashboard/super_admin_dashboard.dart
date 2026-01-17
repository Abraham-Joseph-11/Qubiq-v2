import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'dart:math';

// ✅ Correct Import
import 'package:little_emmi/Screens/Auth/login_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0; // 0=Home, 1=Schools, 2=Licenses, 3=Admins, 4=Logs

  // 耳 THEME COLORS (Light Mode)
  final Color _bgMain = const Color(0xFFF8FAFC);
  final Color _bgSidebar = Colors.white;
  final Color _textPrimary = const Color(0xFF0F172A);
  final Color _textSecondary = const Color(0xFF64748B);
  final Color _accentColor = const Color(0xFF0EA5E9);
  final Color _border = const Color(0xFFE2E8F0);

  // 統 LOGGING HELPER
  Future<void> _logActivity(String action, String details) async {
    await _firestore.collection('admin_logs').add({
      'action': action,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- LOGIC: CREATE SCHOOL ---
  Future<void> _createNewSchool() async {
    String name = "";
    String schoolId = (1000 + Random().nextInt(9000)).toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text("Add New School", style: TextStyle(color: _textPrimary)),
        content: TextField(
          onChanged: (v) => name = v,
          decoration: InputDecoration(
            hintText: "Enter School Name",
            filled: true,
            fillColor: _bgMain,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accentColor, foregroundColor: Colors.white),
            onPressed: () async {
              if (name.isEmpty) return;
              await _firestore.collection('schools').doc(schoolId).set({
                'name': name,
                'schoolId': schoolId,
                'status': 'active',
                'paymentStatus': 'paid',
                'createdAt': FieldValue.serverTimestamp(),
              });

              await _logActivity("Created School", "Added school '$name' (ID: $schoolId)");

              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Create"),
          )
        ],
      ),
    );
  }

  // --- LOGIC: GENERATE KEY (3 Sets) ---
  Future<void> _generateLicenseKey() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));

    // Format: QBIQ-XXXX-XXXX
    String key = "QBIQ-${getRandomString(4)}-${getRandomString(4)}";

    await _firestore.collection('licenses').add({
      'key': key,
      'status': 'unused',
      'linkedDeviceId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _logActivity("Generated Key", "Created new license key: $key");
  }

  // --- LOGIC: ADD SUPER ADMIN ---
  Future<void> _addSuperAdmin() async {
    String email = "";
    String name = "";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text("Add New Admin", style: TextStyle(color: _textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (v) => name = v,
              decoration: InputDecoration(hintText: "Name", filled: true, fillColor: _bgMain, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (v) => email = v,
              decoration: InputDecoration(hintText: "Email", filled: true, fillColor: _bgMain, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accentColor, foregroundColor: Colors.white),
            onPressed: () async {
              if (email.isEmpty || name.isEmpty) return;

              // Note: This adds them to the database.
              // Actual Authentication creation usually happens on Sign Up or via Firebase Console.
              await _firestore.collection('super_admins').add({
                'name': name,
                'email': email,
                'role': 'super_admin',
                'createdAt': FieldValue.serverTimestamp(),
              });

              await _logActivity("Added Admin", "Promoted $name ($email) to Super Admin");

              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Add Admin"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgMain,
      body: Row(
        children: [
          // 1. SIDEBAR
          Container(
            width: 260,
            decoration: BoxDecoration(color: _bgSidebar, border: Border(right: BorderSide(color: _border))),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hexagon_outlined, color: _accentColor, size: 28),
                    const SizedBox(width: 10),
                    Text("QUBIQ ADMIN", style: TextStyle(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 50),
                _sidebarBtn("Dashboard", Icons.analytics_outlined, 0),
                _sidebarBtn("Manage Schools", Icons.school_outlined, 1),
                _sidebarBtn("License Keys", Icons.vpn_key_outlined, 2),
                _sidebarBtn("Super Admins", Icons.admin_panel_settings_outlined, 3),
                _sidebarBtn("Activity Logs", Icons.history_edu_outlined, 4),

                const Spacer(),

                // 坎 LOGOUT BUTTON
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: InkWell(
                    onTap: () async {
                      // 1. Sign out from Firebase
                      await FirebaseAuth.instance.signOut();

                      if (!context.mounted) return;

                      // 2. Navigate explicitly to the LoginScreen
                      // ✅ FIXED: Removed isSchool: true
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LittleEmmiLoginScreen(),
                        ),
                            (route) => false,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, color: Colors.red[400], size: 22),
                          const SizedBox(width: 14),
                          Text(
                              "Logout",
                              style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.w700)
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. MAIN CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: return _buildAnalyticsTab();
      case 1: return _buildSchoolsTab();
      case 2: return _buildLicensesTab();
      case 3: return _buildAdminsTab();
      case 4: return _buildLogsTab();
      default: return _buildAnalyticsTab();
    }
  }

  Widget _sidebarBtn(String label, IconData icon, int index) {
    bool isActive = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? _accentColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: _accentColor.withOpacity(0.2)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? _accentColor : _textSecondary, size: 22),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(color: isActive ? _accentColor : _textSecondary, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // --- TAB 0: ANALYTICS ---
  Widget _buildAnalyticsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Overview", style: TextStyle(color: _textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        Row(
          children: [
            _statCard("Total Schools", 'schools', Icons.school, Colors.indigo),
            const SizedBox(width: 20),
            _statCard("Total Licenses", 'licenses', Icons.vpn_key, Colors.teal),
            const SizedBox(width: 20),
            _activeRobotsCard(),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String title, String collection, IconData icon, Color color) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection(collection).snapshots(),
        builder: (context, snapshot) {
          String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";
          return Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: _textSecondary, fontSize: 14)),
                    Text(count, style: TextStyle(color: _textPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _activeRobotsCard() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('licenses').where('status', isEqualTo: 'active').snapshots(),
        builder: (context, snapshot) {
          String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";
          return Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.smart_toy, color: Colors.orange, size: 30),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Active Robots", style: TextStyle(color: _textSecondary, fontSize: 14)),
                    Text(count, style: TextStyle(color: _textPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- TAB 1: SCHOOLS ---
  Widget _buildSchoolsTab() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("School Accounts", style: TextStyle(color: _textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _accentColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
              onPressed: _createNewSchool,
              icon: const Icon(Icons.add),
              label: const Text("New School"),
            )
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('schools').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  String docId = snapshot.data!.docs[index].id;
                  bool isBlocked = data['status'] == 'blocked';

                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _border)),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("ID: ${data['schoolId']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: !isBlocked,
                            onChanged: (val) async {
                              await _firestore.collection('schools').doc(docId).update({'status': val ? 'active' : 'blocked'});
                              _logActivity(val ? "Unblocked School" : "Blocked School", "Modified access for ${data['name']}");
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () async {
                              await _firestore.collection('schools').doc(docId).delete();
                              _logActivity("Deleted School", "Deleted school: ${data['name']}");
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }

  // --- TAB 2: LICENSES ---
  Widget _buildLicensesTab() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Installation Keys", style: TextStyle(color: _textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
              onPressed: _generateLicenseKey,
              icon: const Icon(Icons.vpn_key),
              label: const Text("Generate New Key"),
            )
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('licenses').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  bool isUsed = data['status'] == 'active';
                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _border)),
                    child: ListTile(
                      leading: Icon(Icons.vpn_key, color: isUsed ? Colors.red : Colors.teal),
                      title: InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: data['key']));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied!")));
                          },
                          child: Text(data['key'], style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold))
                      ),
                      subtitle: Text(isUsed ? "Status: Active" : "Status: Unused"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () async {
                          await snapshot.data!.docs[index].reference.delete();
                          _logActivity("Deleted Key", "Removed license key: ${data['key']}");
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }

  // --- TAB 3: ADMINS ---
  Widget _buildAdminsTab() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Super Admins", style: TextStyle(color: _textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
              onPressed: _addSuperAdmin,
              icon: const Icon(Icons.person_add),
              label: const Text("Add Admin"),
            )
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('super_admins').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _border)),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.indigo[50], child: const Icon(Icons.person, color: Colors.indigo)),
                      title: Text(data['name']),
                      subtitle: Text(data['email']),
                      trailing: const Icon(Icons.verified_user, color: Colors.green),
                    ),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }

  // --- TAB 4: LOGS ---
  Widget _buildLogsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Activity Logs", style: TextStyle(color: _textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('admin_logs').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;

                  // Simple Date Formatting (Avoids external package)
                  DateTime? date = (data['timestamp'] as Timestamp?)?.toDate();
                  String timeStr = date != null ? "${date.hour}:${date.minute}  ${date.day}/${date.month}" : "Just now";

                  return Container(
                    padding: const EdgeInsets.all(15),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
                    child: Row(
                      children: [
                        Text(timeStr, style: TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['action'], style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold)),
                              Text(data['details'], style: TextStyle(color: _textSecondary, fontSize: 13)),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }
}