import 'package:flutter/material.dart';
import '../services/leave_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaveRequestScreen extends StatefulWidget {
  @override
  _LeaveRequestScreenState createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final LeaveService _leaveService = LeaveService();
  final _formKey = GlobalKey<FormState>();
  
  String _leaveType = 'annual'; // 'annual' ou 'unpaid'
  String _reason = '';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(days: 2));

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      String uid = FirebaseAuth.instance.currentUser!.uid;
      
      // Envoi de la demande à Firestore via notre service
      await _leaveService.submitLeaveRequest(
        uid,
        "Abdelaziz", 
        _leaveType,
        _startDate,
        _endDate,
        _reason,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demande soumise avec succès !')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nouvelle Demande de Congé")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _leaveType,
                items: [
                  DropdownMenuItem(value: 'annual', child: Text('Congé Annuel (Soldé)')),
                  DropdownMenuItem(value: 'unpaid', child: Text('Congé Sans Solde')),
                ],
                onChanged: (val) => setState(() => _leaveType = val!),
                decoration: InputDecoration(labelText: "Type de congé"),
              ),
              SizedBox(height: 15),
              TextFormField(
                decoration: InputDecoration(labelText: "Motif du congé"),
                validator: (val) => val!.isEmpty ? 'Veuillez entrer un motif' : null,
                onSave: (val) => _reason = val!,
              ),
              SizedBox(height: 20),
              ListTile(
                title: Text("Date de début : ${_startDate.toLocal()}".split(' ')[0]),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2027),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
              ),
              ListTile(
                title: Text("Date de fin : ${_endDate.toLocal()}".split(' ')[0]),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: _startDate,
                    lastDate: DateTime(2027),
                  );
                  if (picked != null) setState(() => _endDate = picked);
                },
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submit,
                child: Text("Envoyer la demande"),
              )
            ],
          ),
        ),
      ),
    );
  }
}