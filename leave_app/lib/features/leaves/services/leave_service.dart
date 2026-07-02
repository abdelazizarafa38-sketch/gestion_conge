import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Soumettre une nouvelle demande de congé
  Future<void> submitLeaveRequest(String employeeId, String name, String type, DateTime start, DateTime end, String reason) async {
    await _db.collection('leaves').add({
      'employeeId': employeeId,
      'employeeName': name,
      'type': type, 
      'startDate': start,
      'endDate': end,
      'reason': reason,
      'status': 'pending_manager', 
      'comment': '',
    });
  }

  // Action intermédiaire du Responsable (N+1)
  Future<void> updateStatusByManager(String leaveId, String newStatus) async {
    await _db.collection('leaves').doc(leaveId).update({
      'status': newStatus,
    });
  }

  // Action finale des RH
  Future<void> finalizeLeaveByRH(String leaveId, String employeeId, String leaveType, int durationInDays, bool isApproved) async {
    DocumentReference leaveRef = _db.collection('leaves').doc(leaveId);
    DocumentReference userRef = _db.collection('users').doc(employeeId);

    if (isApproved) {
      await _db.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction.get(userRef);
        
        if (!userSnapshot.exists) throw Exception("Utilisateur introuvable !");

        if (leaveType == 'annual') {
          int currentBalance = userSnapshot['annualLeaveBalance'] ?? 0;
          transaction.update(userRef, {'annualLeaveBalance': currentBalance - durationInDays});
        } else if (leaveType == 'unpaid') {
          int currentUnpaid = userSnapshot['unpaidLeaveTaken'] ?? 0;
          transaction.update(userRef, {'unpaidLeaveTaken': currentUnpaid + durationInDays});
        }

        transaction.update(leaveRef, {'status': 'approved'});
      });
    } else {
      await leaveRef.update({'status': 'rejected_by_rh'});
    }
  }
}