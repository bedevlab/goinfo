import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_post_screen.dart';
import 'edit_profile_screen.dart';
import 'comments_screen.dart';
import 'public_profile_screen.dart';
import 'messages_list_screen.dart';
import 'notifications_screen.dart'; // Ensure this file exists
import 'balance_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 0=Feed, 1=Messages, 2=Profile

  // --- LOGIC: DELETE POST ---
  void _deletePost(String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Post?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Optional: Delete comments subcollection here via Cloud Function in a real app
      // For MVP, just deleting the post document is enough to hide it.
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post deleted.")));
      }
    }
  }

  // --- LOGIC: LIKE POST & NOTIFY ---
  void _toggleLike(String postId, List<dynamic> likes, String postOwnerId) {
    final user = FirebaseAuth.instance.currentUser!;
    final ref = FirebaseFirestore.instance.collection('posts').doc(postId);

    if (likes.contains(user.uid)) {
      // Unlike
      ref.update({'likes': FieldValue.arrayRemove([user.uid])});
    } else {
      // Like
      ref.update({'likes': FieldValue.arrayUnion([user.uid])});

      // Send Notification (Only if I am not liking my own post)
      if (user.uid != postOwnerId) {
        FirebaseFirestore.instance.collection('notifications').add({
          'recipientId': postOwnerId,
          'message': "${user.email!.split('@')[0]} liked your post.",
          'type': 'like',
          'postId': postId,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    // ----------------------
    // TAB 1: COMMUNITY FEED
    // ----------------------
    final feedScreen = Scaffold(
      appBar: AppBar(
        title: const Text("Community Feed", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
          },
        ),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
            builder: (context, snapshot) {
              final balance = (snapshot.data?.data() as Map?)?['balance'] ?? 0;
              
              // Wrap with InkWell to make it clickable
              return InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BalanceHistoryScreen()));
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC72C).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFC72C)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Color(0xFFF57F17), size: 18),
                      const SizedBox(width: 4),
                      Text("$balance pts", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final posts = snapshot.data!.docs;
          if (posts.isEmpty) return const Center(child: Text("No questions yet. Ask one!"));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final postDoc = posts[index];
              final post = postDoc.data() as Map<String, dynamic>;
              final postId = postDoc.id;
              
              // Extract Data
              final List likes = post['likes'] ?? [];
              final bool isLiked = likes.contains(user.uid);
              final int likeCount = likes.length;
              final int commentCount = post['commentCount'] ?? 0; // Comment Count
              final String authorId = post['authorId'];
              final bool isMyPost = authorId == user.uid; // Ownership check

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER ---
                      Row(
                        children: [
                          // Clickable Profile
                          InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => PublicProfileScreen(userId: authorId, userEmail: post['authorEmail']),
                              ));
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.green.shade100,
                                  child: Text(post['authorEmail'][0].toUpperCase()),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post['authorEmail'].split('@')[0],
                                      style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                    ),
                                    const Text("Student", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Delete Button (Only visible if I own the post)
                          if (isMyPost)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey),
                              onPressed: () => _deletePost(postId),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // --- CONTENT ---
                      Text(post['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(post['body'], style: const TextStyle(color: Colors.black87)),
                      const SizedBox(height: 12),
                      const Divider(),
                      
                      // --- ACTIONS ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Like Button
                          TextButton.icon(
                            icon: Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined, color: isLiked ? const Color(0xFF00573F) : Colors.grey), 
                            label: Text(likeCount > 0 ? "$likeCount" : "Like", style: TextStyle(color: isLiked ? const Color(0xFF00573F) : Colors.grey)), 
                            onPressed: () => _toggleLike(postId, likes, authorId)
                          ),
                          // Comment Button (Navigates to CommentsScreen with Owner ID)
                          TextButton.icon(
                            icon: const Icon(Icons.comment_outlined, color: Colors.grey), 
                            label: Text(
                              commentCount > 0 ? "$commentCount Comments" : "Comment",
                              style: const TextStyle(color: Colors.grey)
                            ), 
                            onPressed: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => CommentsScreen(postId: postId, postOwnerId: authorId)
                            ))
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00573F),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );

    // ----------------------
    // TAB 2: MESSAGES
    // ----------------------
    const messagesScreen = MessagesListScreen();

    // ----------------------
    // TAB 3: MY PROFILE
    // ----------------------
    final profileScreen = Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const CircleAvatar(radius: 50, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 60, color: Colors.white)),
            const SizedBox(height: 16),
            Text(user.email!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text("AUI Student", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            
            // Edit Profile
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF00573F)),
              title: const Text("Edit Profile"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
            ),
            
            // Logout
             ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Log Out", style: TextStyle(color: Colors.red)),
              onTap: () => FirebaseAuth.instance.signOut(),
            ),
          ],
        ),
      ),
    );

    // ----------------------
    // MAIN SCAFFOLD (TABS)
    // ----------------------
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [feedScreen, messagesScreen, profileScreen],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: "Feed"),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: "Messages"),
          NavigationDestination(icon: Icon(Icons.person_outlined), selectedIcon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}