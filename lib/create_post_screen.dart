// lib/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isLoading = false;

  // REWARD LOGIC: Cost to post a question
  final int postCost = 5;

  Future<void> _submitPost() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Check User Balance First
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final currentBalance = userDoc.data()?['balance'] ?? 0;

    if (currentBalance < postCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not enough points! Help others to earn more.")),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 2. Perform the Transaction (Add Post AND Deduct Points)
      // We use a "Batch" to ensure both happen or neither happens
      final batch = FirebaseFirestore.instance.batch();

      // A. Create the Post reference
      final newPostRef = FirebaseFirestore.instance.collection('posts').doc();
      batch.set(newPostRef, {
        'title': _titleController.text,
        'body': _bodyController.text,
        'authorId': user.uid,
        'authorEmail': user.email,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // B. Deduct Points from User
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      batch.update(userRef, {
        'balance': FieldValue.increment(-postCost), // Subtract 5
      });

      // Commit changes
      await batch.commit();

      if (mounted) Navigator.pop(context); // Go back to Home
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ask Question (-$postCost pts)")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Title (e.g., CSC 3324 Help)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: "Details...",
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _submitPost,
                    icon: const Icon(Icons.send),
                    label: const Text("Post Question"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}