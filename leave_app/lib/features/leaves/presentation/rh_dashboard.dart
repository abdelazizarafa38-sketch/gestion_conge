import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:leave_app/features/leaves/services/leave_service.dart';

class RhDashboard extends StatefulWidget {
  const RhDashboard({super.key});

  @override
  State<RhDashboard> createState() => _RhDashboardState();
}

class _RhDashboardState extends State<RhDashboard> {
  final LeaveService _leaveService = LeaveService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int _calculateDays(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Espace Modérateur RH"),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('leaves')
            .where('status', isEqualTo: 'pending_rh')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Aucune demande en attente de validation finale RH."),
            );
          }

          var leaves = snapshot.data!.docs;

          return ListView.builder(
            itemCount: leaves.length,
            itemBuilder: (context, index) {
              var leave = leaves[index];
              var leaveId = leave.id;
              var employeeId = leave['employeeId'] ?? '';
              var employeeName = leave['employeeName'] ?? 'Employé';
              var reason = leave['reason'] ?? 'Pas de motif';
              var type = leave['type'] ?? 'annual';
              
              DateTime startDate = (leave['startDate'] as Timestamp).toDate();
              DateTime endDate = (leave['endDate'] as Timestamp).toDate();
              int duration = _calculateDays(startDate, endDate);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                elevation: 3,
                child: ListTile(
                  title: Text("$employeeName — ${type == 'annual' ? 'Annuel' : 'Sans Solde'}"),
                  subtitle: Text("Période : ${startDate.toLocal().toString().split(' ')[0]} au ${endDate.toLocal().toString().split(' ')[0]}\nDurée : $duration jour(s)\nMotif : $reason"),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.teal, size: 30),
                        onPressed: () async {
                          await _leaveService.finalizeLeaveByRH(leaveId, employeeId, type, duration, true);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Congé définitivement approuvé !")),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.deepOrange, size: 30), // Correction de la couleur ici
                        onPressed: () async {
                          await _leaveService.finalizeLeaveByRH(leaveId, employeeId, type, duration, false);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Demande rejetée par les RH.")),
                          );
                        },
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