import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Créer une nouvelle demande de congé dans Firestore
  Future<void> createLeaveRequest({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required String typeConge, // 'paye' ou 'sans_solde'
  }) async {
    int nbJours = endDate.difference(startDate).inDays + 1;

    await _db.collection('leaves').add({
      'userId': userId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'nbJours': nbJours,
      'typeConge': typeConge,
      'status': 'En attente',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Valider/Refuser la demande et mettre à jour le solde uniquement si payé
  Future<void> updateLeaveStatus({
    required String docId,
    required String userId,
    required String newStatus,
    required String typeConge,
    required int nbJours,
  }) async {
    // 1. Mettre à jour le statut dans la collection 'leaves'
    await _db.collection('leaves').doc(docId).update({
      'status': newStatus,
    });

    // 2. Si approuvé ET congé payé, soustraire les jours du solde de l'utilisateur
    if (newStatus == 'Approuvé' && typeConge == 'paye') {
      await _db.collection('users').doc(userId).update({
        'soldeConges': FieldValue.increment(-nbJours),
      });
    }
  }
}