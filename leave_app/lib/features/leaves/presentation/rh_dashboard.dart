import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RhDashboard extends StatefulWidget {
  const RhDashboard({super.key});

  @override
  State<RhDashboard> createState() => _RhDashboardState();
}

class _RhDashboardState extends State<RhDashboard> {
  
  Future<void> _updateLeaveStatus(String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('leaves').doc(docId).update({
        'status': newStatus,
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Validation finale enregistrée : $newStatus 🎖️'),
          backgroundColor: newStatus == 'approuvé' ? Colors.green : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur de mise à jour : ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  int _calculateDays(String startStr, String endStr) {
    try {
      final start = DateTime.parse(startStr);
      final end = DateTime.parse(endStr);
      return end.difference(start).inDays + 1;
    } catch (_) {
      return 0;
    }
  }

  String _formatDisplayDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Espace RH', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF475569), 
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('leaves')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF475569)));
          }

          final docs = snapshot.data?.docs ?? [];
          
          int totalRequests = docs.length;
          int approvedCount = docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'approuvé').length;
          int pendingCount = docs.where((d) => 
            (d.data() as Map<String, dynamic>)['status'] == 'en attente' || 
            (d.data() as Map<String, dynamic>)['status'] == 'approuvé par manager'
          ).length;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vue d\'ensemble des effectifs',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCard('Total', totalRequests.toString(), Colors.blueAccent),
                    const SizedBox(width: 12),
                    _buildStatCard('Approuvés (Final)', approvedCount.toString(), Colors.green),
                    const SizedBox(width: 12),
                    _buildStatCard('En cours de traitement', pendingCount.toString(), Colors.orange),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Historique global et Actions RH',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: docs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open_rounded, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              const Text('Aucun enregistrement trouvé', style: TextStyle(color: Color(0xFF64748B))),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            
                            final String docId = doc.id;
                            final String employeeName = data['employeeName'] ?? 'Employé';
                            final String reason = data['reason'] ?? 'Aucun motif';
                            final String startDate = data['startDate'] ?? '';
                            final String endDate = data['endDate'] ?? '';
                            final String status = data['status'] ?? 'en attente';
                            final int totalDays = _calculateDays(startDate, endDate);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x02000000), blurRadius: 8, offset: Offset(0, 2))
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: const Color(0xFFF1F5F9),
                                            child: Text(
                                              employeeName.isNotEmpty ? employeeName[0] : 'E',
                                              style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            employeeName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                          ),
                                        ],
                                      ),
                                      _buildMiniStatusBadge(status),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text('Motif : $reason', style: const TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Du ${_formatDisplayDate(startDate)} au ${_formatDisplayDate(endDate)} ($totalDays jours)',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),

                                  if (status == 'approuvé par manager') ...[
                                    const SizedBox(height: 14),
                                    const Divider(color: Color(0xFFF1F5F9)),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () => _updateLeaveStatus(docId, 'refusé'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.redAccent,
                                            side: const BorderSide(color: Colors.redAccent),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          icon: const Icon(Icons.close_rounded, size: 16),
                                          label: const Text('Refuser définitivement', style: TextStyle(fontSize: 12)),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton.icon(
                                          onPressed: () => _updateLeaveStatus(docId, 'approuvé'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF475569),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          icon: const Icon(Icons.verified_rounded, size: 16),
                                          label: const Text('Validation Finale', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    )
                                  ]
                                ],
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

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatusBadge(String status) {
    Color color;
    String text = status.toUpperCase();

    switch (status) {
      case 'approuvé':
        color = Colors.green;
        text = "CONFIRMÉ RH";
        break;
      case 'approuvé par manager':
        color = Colors.blue;
        text = "ATTENTE RH";
        break;
      case 'refusé':
        color = Colors.redAccent;
        text = "REFUSÉ";
        break;
      default:
        color = Colors.orange;
        text = "ATTENTE MGR";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}