import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  // Fonction pour mettre à jour le statut initial du manager (Accepté / Refusé)
  Future<void> _updateManagerStatus(String docId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('leaves').doc(docId).update({
        'managerStatus': status,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demande $status avec succès !'),
          backgroundColor: status == 'Accepté' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fonction pour modifier les dates du congé
  Future<void> _editLeaveDates(
    String docId,
    DateTime currentStartDate,
    DateTime currentEndDate,
  ) async {
    DateTime? pickedStartDate = await showDatePicker(
      context: context,
      initialDate: currentStartDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      helpText: "Modifier la date de début",
    );

    if (!mounted) return;
    if (pickedStartDate == null) return;

    DateTime? pickedEndDate = await showDatePicker(
      context: context,
      initialDate: currentEndDate,
      firstDate: pickedStartDate,
      lastDate: DateTime(2030),
      helpText: "Modifier la date de fin",
    );

    if (!mounted) return;
    if (pickedEndDate == null) return;

    try {
      await FirebaseFirestore.instance.collection('leaves').doc(docId).update({
        'startDate': Timestamp.fromDate(pickedStartDate),
        'endDate': Timestamp.fromDate(pickedEndDate),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dates du congé modifiées avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la modification : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Manager - Gestion des Congés'),
        backgroundColor: const Color(0xFF3F51B5),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('leaves').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Aucune demande de congé enregistrée.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final employeeName = data['employeeName'] ?? 'Employé';
              final reason = data['reason'] ?? 'Non spécifié';
              final managerStatus = data['managerStatus'] ?? 'En attente';

              DateTime startDate = _parseDate(data['startDate']);
              DateTime endDate = _parseDate(data['endDate']);

              // Couleur dynamique selon le statut du manager
              Color statusColor = Colors.orange;
              if (managerStatus == 'Accepté') statusColor = Colors.green;
              if (managerStatus == 'Refusé') statusColor = Colors.red;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            employeeName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Chip(
                            label: Text(
                              managerStatus,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Motif : $reason\nDu : ${startDate.day}/${startDate.month}/${startDate.year} au ${endDate.day}/${endDate.month}/${endDate.year}',
                        style: const TextStyle(height: 1.4),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Bouton Refuser
                          OutlinedButton.icon(
                            onPressed: () => _updateManagerStatus(doc.id, 'Refusé'),
                            icon: const Icon(Icons.close, color: Colors.red, size: 18),
                            label: const Text('Refuser', style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          // Bouton Accepter
                          ElevatedButton.icon(
                            onPressed: () => _updateManagerStatus(doc.id, 'Accepté'),
                            icon: const Icon(Icons.check, color: Colors.white, size: 18),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            label: const Text('Accepter', style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          // Bouton Modifier les dates
                          IconButton(
                            icon: const Icon(
                              Icons.edit_calendar,
                              color: Color(0xFF3F51B5),
                              size: 26,
                            ),
                            tooltip: 'Modifier les dates',
                            onPressed: () => _editLeaveDates(doc.id, startDate, endDate),
                          ),
                        ],
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