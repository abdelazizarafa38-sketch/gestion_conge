import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:leave_app/features/leaves/services/leave_service.dart';

class ManagerDashboard extends StatefulWidget {
  @override
  _ManagerDashboardState createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  final LeaveService _leaveService = LeaveService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Espace Responsable (N+1)"),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('leaves')
            .where('status', isEqualTo: 'pending_manager')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Aucune demande de congé en attente."));
          }

          var leaves = snapshot.data!.docs;

          return ListView.builder(
            itemCount: leaves.length,
            itemBuilder: (context, index) {
              var leave = leaves[index];
              var leaveId = leave.id;
              var employeeName = leave['employeeName'] ?? 'Employé';
              var reason = leave['reason'] ?? 'Pas de motif';
              var type = leave['type'] == 'annual' ? 'Annuel' : 'Sans Solde';

              return Card(
                margin: EdgeInsets.all(10),
                elevation: 4,
                child: ListTile(
                  title: Text("$employeeName - Congé $type"),
                  subtitle: Text("Motif : $reason"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check_circle, color: Colors.green, size: 30),
                        onPressed: () async {
                          await _leaveService.updateStatusByManager(leaveId, 'pending_rh');
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Demande validée et envoyée aux RH !")),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.cancel, color: Colors.red, size: 30),
                        onPressed: () async {
                          await _leaveService.updateStatusByManager(leaveId, 'rejected_by_manager');
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Demande refusée.")),
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