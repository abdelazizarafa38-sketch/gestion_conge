import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  // Fonction pour déconnecter le manager
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/role_selection');
  }

  // Fonction pour changer le statut (Approuver / Refuser) + Calcul du solde
  Future<void> _updateStatus({
    required String docId,
    required String newStatus,
    required String userId,
    required String typeConge,
    required int nbJours,
  }) async {
    try {
      // 1. Mettre à jour le statut dans la collection 'leaves'
      await FirebaseFirestore.instance.collection('leaves').doc(docId).update({
        'status': newStatus,
      });

      // 2. Si le congé est approuvé ET payé, déduire du solde dans la collection 'users'
      if (newStatus == 'Approuvé' && typeConge == 'paye') {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'soldeConges': FieldValue.increment(-nbJours),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut mis à jour : $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Responsable / Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('leaves').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aucune demande de congé trouvée.'));
          }

          final leavesDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: leavesDocs.length,
            itemBuilder: (context, index) {
              final data = leavesDocs[index].data() as Map<String, dynamic>;
              final docId = leavesDocs[index].id;

              final String status = data['status'] ?? 'En attente';
              final String typeConge = data['typeConge'] ?? 'paye';
              final String userId = data['userId'] ?? '';
              final int nbJours = data['nbJours'] ?? 1;
              final String startDate = data['startDate'] ?? '';
              final String endDate = data['endDate'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    'Demande (${typeConge == 'paye' ? 'Congé Payé' : 'Congé Sans Solde'})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Du : ${startDate.split('T')[0]} au : ${endDate.split('T')[0]}\n'
                    'Durée : $nbJours jour(s) | Statut : $status',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _updateStatus(
                          docId: docId,
                          newStatus: 'Approuvé',
                          userId: userId,
                          typeConge: typeConge,
                          nbJours: nbJours,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _updateStatus(
                          docId: docId,
                          newStatus: 'Refusé',
                          userId: userId,
                          typeConge: typeConge,
                          nbJours: nbJours,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}