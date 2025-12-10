import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  final String postOwnerId; // <--- NEW: We need to know who owns the post

  const CommentsScreen({super.key, required this.postId, required this.postOwnerId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _commentController = TextEditingController();

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    _commentController.clear();
    final user = FirebaseAuth.instance.currentUser!;
    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    final batch = FirebaseFirestore.instance.batch();


    final newCommentRef = postRef.collection('comments').doc();
    batch.set(newCommentRef, {
      'text': text,
      'authorEmail': user.email,
      'authorId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });



    batch.set(postRef, {
      'commentCount': FieldValue.increment(1)
    }, SetOptions(merge: true));


    if (user.uid != widget.postOwnerId) {
      final notifRef = FirebaseFirestore.instance.collection('notifications').doc();
      batch.set(notifRef, {
        'recipientId': widget.postOwnerId, // Send to Post Owner
        'message': "${user.email!.split('@')[0]} commented: $text",
        'type': 'comment',
        'postId': widget.postId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Comments")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final comments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final data = comments[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                      title: Text(data['authorEmail'].split('@')[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(data['text']),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black12)]),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(hintText: "Write a comment...", border: InputBorder.none),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF00573F)),
                  onPressed: _postComment,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}