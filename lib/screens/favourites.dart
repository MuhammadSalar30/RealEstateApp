import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'propertydetailpage.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Please log in to view favorites.'));
    }

    final favoritesRef = FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Wishlisted Properties"),
        backgroundColor: Colors.blue.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: favoritesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No wishlisted properties found."));
          }

          final properties = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final data = properties[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                child: ListTile(
                  leading: data['image'] != null
                      ? Image.network(
                          data['image'],
                          width: 60,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image, size: 40),
                  title: Text(data['type'] ?? 'Property'),
                  subtitle: Text(data['location'] ?? ''),
                  trailing: const Icon(Icons.favorite, color: Colors.red),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PropertyDetailPage(data: data),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
