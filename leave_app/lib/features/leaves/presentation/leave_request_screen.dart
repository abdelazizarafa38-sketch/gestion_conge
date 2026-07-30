import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  String _leaveType = 'Congé Payé (Déduit du solde)';
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  int get _calculatedDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner les dates de début et fin')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('leaves').add({
        'userId': user?.uid ?? 'inconnu',
        'userEmail': user?.email ?? 'employe@test.com',
        'leaveType': _leaveType,
        'startDate': Timestamp.fromDate(_startDate!),
        'endDate': Timestamp.fromDate(_endDate!),
        'duration': _calculatedDays,
        'reason': _reasonController.text.trim(),
        'status': 'En attente',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande envoyée avec succès !'), backgroundColor: Colors.green),
        );
        _reasonController.clear();
        setState(() {
          _startDate = null;
          _endDate = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'envoi : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF3F51B5),
          foregroundColor: Colors.white,
          title: const Text('Espace Employé'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Retour',
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/role_selection');
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Déconnexion',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.add_circle_outline), text: 'Nouvelle Demande'),
              Tab(icon: Icon(Icons.history), text: 'Mes Demandes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Onglet 1 : Formulaire
            _buildFormTab(user?.uid),
            // Onglet 2 : Historique
            _buildHistoryTab(user?.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildFormTab(String? uid) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              // Solde de congés
              if (uid != null)
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                  builder: (context, snapshot) {
                    int solde = 25;
                    if (snapshot.hasData && snapshot.data!.data() != null) {
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      solde = data['solde'] ?? 25;
                    }
                    return Card(
                      color: Colors.indigo.shade50,
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance_wallet, color: Colors.indigo, size: 28),
                            const SizedBox(width: 16),
                            Text(
                              'Solde de congés disponible : $solde jours',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // Card Formulaire
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nouvelle Demande', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Text('Remplissez les détails du congé', style: TextStyle(color: Colors.grey)),
                        const Divider(height: 30),

                        DropdownButtonFormField<String>(
                          initialValue: _leaveType,
                          decoration: const InputDecoration(
                            labelText: 'Type de congé',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: ['Congé Payé (Déduit du solde)', 'Congé Sans Solde', 'Maladie']
                              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (val) => setState(() => _leaveType = val!),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today),
                                label: Text(_startDate == null ? 'Date Début' : DateFormat('dd/MM/yyyy').format(_startDate!)),
                                onPressed: () => _selectDate(context, true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today),
                                label: Text(_endDate == null ? 'Date Fin' : DateFormat('dd/MM/yyyy').format(_endDate!)),
                                onPressed: () => _selectDate(context, false),
                              ),
                            ),
                          ],
                        ),
                        if (_calculatedDays > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('Durée totale : $_calculatedDays jour(s)', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                          ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _reasonController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Motif du congé',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.notes),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez rédiger un motif' : null,
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3F51B5),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _isLoading ? null : _submitRequest,
                            icon: const Icon(Icons.send),
                            label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Envoyer la demande'),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab(String? uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leaves')
          .where('userId', isEqualTo: uid ?? 'inconnu')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Aucune demande enregistrée.'));
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final status = data['status'] ?? 'En attente';
            Color statusColor = Colors.orange;
            if (status == 'Validé' || status == 'Approuvé') statusColor = Colors.green;
            if (status == 'Refusé') statusColor = Colors.red;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(data['leaveType'] ?? 'Congé', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Motif : ${data['reason'] ?? ''}\nDurée : ${data['duration'] ?? 0} jour(s)'),
                trailing: Chip(
                  label: Text(status, style: const TextStyle(color: Colors.white)),
                  backgroundColor: statusColor,
                ),
              ),
            );
          },
        );
      },
    );
  }
}