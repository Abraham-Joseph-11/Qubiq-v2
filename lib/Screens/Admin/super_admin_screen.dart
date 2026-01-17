import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../Models/AdminModels.dart'; // Import MockInstitution

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  // MOCK STATE: Institutions List
  final List<MockInstitution> _institutions = [
    MockInstitution(id: Uuid().v4(), name: 'Global Tech Academy', teacherCount: 15, canUseMIT: true),
    MockInstitution(id: Uuid().v4(), name: 'Future Coders School', teacherCount: 8, canUseMIT: false),
  ];

  final TextEditingController _nameController = TextEditingController();

  void _addInstitution() {
    setState(() {
      final newName = _nameController.text.trim();
      if (newName.isNotEmpty) {
        _institutions.add(MockInstitution(id: Uuid().v4(), name: newName, teacherCount: 0));
        _nameController.clear();
        Navigator.pop(context);
      }
    });
  }

  void _deleteInstitution(String id) {
    setState(() {
      _institutions.removeWhere((inst) => inst.id == id);
    });
  }

  void _toggleAppControl(MockInstitution inst) {
    setState(() {
      // Logic to toggle access for MIT App Inventor
      final index = _institutions.indexWhere((i) => i.id == inst.id);
      if (index != -1) {
        _institutions[index].canUseMIT = !inst.canUseMIT; // Toggle access
      }
    });
  }

  void _showAddInstitutionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Institution'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Institution Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: _addInstitution,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          tooltip: 'Logout',
        ),
        title: Text('Super Admin Console', style: GoogleFonts.poppins()),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business),
            onPressed: _showAddInstitutionDialog,
            tooltip: 'Add Institution',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _institutions.isEmpty
          ? const Center(child: Text('No institutions found.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _institutions.length,
        itemBuilder: (context, index) {
          final inst = _institutions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 4,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal.shade100,
                child: Text('${index + 1}', style: TextStyle(color: Colors.teal.shade900)),
              ),
              title: Text(inst.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              subtitle: Text('Teachers: ${inst.teacherCount}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Control Button (Controls MIT access)
                  IconButton(
                    icon: Icon(inst.canUseMIT ? Icons.check_circle : Icons.block,
                        color: inst.canUseMIT ? Colors.green : Colors.red),
                    onPressed: () => _toggleAppControl(inst),
                    tooltip: inst.canUseMIT ? 'MIT Access Granted' : 'MIT Access Blocked',
                  ),
                  // Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteInstitution(inst.id),
                    tooltip: 'Delete Institution',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}