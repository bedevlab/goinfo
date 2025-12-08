// lib/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _majorController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 1. Load existing data from database
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();

      if (data != null) {
        setState(() {
          _nameController.text = data['displayName'] ?? '';
          _majorController.text = data['major'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _isLoading = false;
        });
      }
    }
  }

  // 2. Save updates to database
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'displayName': _nameController.text.trim(),
        'major': _majorController.text.trim(),
        'bio': _bioController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully!")),
        );
        Navigator.pop(context); // Go back to profile
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar Placeholder
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF00573F),
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  // Form Fields
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Display Name",
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _majorController,
                    decoration: const InputDecoration(
                      labelText: "Major (e.g., Computer Science)",
                      prefixIcon: Icon(Icons.school),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: "Short Bio",
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 30),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00573F),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _saveProfile,
                      child: const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}