// lib/public_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class PublicProfileScreen extends StatelessWidget {
  final String userId;
  final String userEmail;

  const PublicProfileScreen({super.key, required this.userId, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final isMe = userId == currentUserId;

    return Scaffold(
      appBar: AppBar(title: const Text("Student Profile")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final major = data?['major'] ?? "General";
          final bio = data?['bio'] ?? "No bio available.";
          final displayName = data?['displayName'] ?? userEmail.split('@')[0];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Color(0xFF00573F),
                  child: Icon(Icons.person, size: 70, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(displayName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                Text(major, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("About", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 10),
                      Text(bio, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // MESSAGE BUTTON
                if (!isMe) // Don't show button if it's my own profile
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00573F),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.message),
                      label: const Text("MESSAGE STUDENT"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(otherUserId: userId, otherUserEmail: userEmail),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}