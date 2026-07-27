import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _expenses =>
      _firestore.collection('expenses');

  Future<void> addExpense(Expense expense) async {
    await _expenses.add(expense.toMap());
  }

  Future<List<Expense>> getExpenses() async {
    final snapshot = await _expenses
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return Expense.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }

  Future<void> deleteExpense(String documentId) async {
    await _expenses.doc(documentId).delete();
  }
}