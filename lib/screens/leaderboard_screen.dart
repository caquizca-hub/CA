import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('totalScore', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading leaderboard'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          final users = snapshot.data!.docs.map((doc) {
            return UserModel.fromMap(doc.data() as Map<String, dynamic>);
          }).toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = users[index];
              final rank = index + 1;
              Color? rankColor;
              if (rank == 1)
                rankColor = Colors.amber;
              else if (rank == 2)
                rankColor = Colors.grey[400];
              else if (rank == 3)
                rankColor = Colors.brown[300];

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: rankColor ?? Colors.blue[100],
                    foregroundColor: rankColor != null
                        ? Colors.white
                        : Colors.blue[900],
                    child: Text(
                      '$rank',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    user.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Score: ${user.totalScore}'),
                  trailing: user.photoUrl.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(user.photoUrl),
                          radius: 16,
                        )
                      : const Icon(Icons.person),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
