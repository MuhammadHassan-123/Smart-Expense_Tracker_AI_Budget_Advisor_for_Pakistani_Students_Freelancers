import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';

class FirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>
      get expenseCollection =>
          _firestore.collection("expenses");

  Future<void> addExpense(Expense expense) async {
    await expenseCollection.add(expense.toMap());
  }

  Stream<List<Expense>> getExpenses() {
    return expenseCollection
        .orderBy("date", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Expense.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> deleteExpense(String id) async {
    await expenseCollection.doc(id).delete();
  }

  Future<void> updateExpense(
      Expense expense,
      ) async {
    await expenseCollection
        .doc(expense.id)
        .update(expense.toMap());
  }
}