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
      // 2. Perform the Transaction (Add Post + Deduct Points + Record History)
      final batch = FirebaseFirestore.instance.batch();

      // A. Create the Post reference
      final newPostRef = FirebaseFirestore.instance.collection('posts').doc();
      batch.set(newPostRef, {
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'authorId': user.uid,
        'authorEmail': user.email,
        'likes': [], // Initialize empty likes
        'commentCount': 0, // Initialize count
        'timestamp': FieldValue.serverTimestamp(),
      });

      // B. Deduct Points from User
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      batch.update(userRef, {
        'balance': FieldValue.increment(-postCost),
      });

      // C. Create Transaction Record
      final transactionRef = userRef.collection('transactions').doc();
      batch.set(transactionRef, {
        'amount': -postCost,
        'description': "Posted a Question",
        'timestamp': FieldValue.serverTimestamp(),
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
      backgroundColor: const Color(0xFFF5F7FA), // Light Grey Background
      appBar: AppBar(
        title: const Text("Ask Question", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // INFO CARD (Cost Warning)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC72C).withOpacity(0.15), // Light Gold
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFC72C)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFF57F17)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Posting a question will cost you $postCost points from your wallet.",
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // INPUTS
            const Text("Title", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: "e.g., Help with CSC 3324",
                prefixIcon: Icon(Icons.title, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: "Describe your question or what you are looking for...",
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 30),

            // SUBMIT BUTTON
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00573F), // AUI Green
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submitPost,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text(
                        "POST QUESTION", 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}