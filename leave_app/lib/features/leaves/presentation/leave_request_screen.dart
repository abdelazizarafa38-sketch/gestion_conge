import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:leave_app/features/leaves/services/leave_service.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final LeaveService _leaveService = LeaveService();
  final _formKey = GlobalKey<FormState>();
  
  String _leaveType = 'annual';
  String _reason = '';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await _leaveService.submitLeaveRequest(
        user.uid,
        "Abdelaziz", 
        _leaveType,
        _startDate,
        _endDate,
        _reason,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande soumise avec succès !')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nouvelle Demande de Congé")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _leaveType,
                items: const [
                  DropdownMenuItem(value: 'annual', child: Text('Congé Annuel (Soldé)')),
                  DropdownMenuItem(value: 'unpaid', child: Text('Congé Sans Solde')),
                ],
                onChanged: (val) => setState(() => _leaveType = val!),
                decoration: const InputDecoration(labelText: "Type de congé"),
              ),
              const SizedBox(height: 15),
              TextFormField(
                decoration: const InputDecoration(labelText: "Motif du congé"),
                validator: (val) => val == null || val.isEmpty ? 'Veuillez entrer un motif' : null,
                onSaved: (val) => _reason = val ?? '',
              ),
              const SizedBox(height: 20),
              ListTile(
                title: Text("Date de début : ${_startDate.toLocal()}".split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2028),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
              ),
              ListTile(
                title: Text("Date de fin : ${_endDate.toLocal()}".split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: _startDate,
                    lastDate: DateTime(2028),
                  );
                  if (picked != null) setState(() => _endDate = picked);
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submit,
                child: const Text("Envoyer la demande"),
              )
            ],
          ),
        ),
      ),
    );
  }
}