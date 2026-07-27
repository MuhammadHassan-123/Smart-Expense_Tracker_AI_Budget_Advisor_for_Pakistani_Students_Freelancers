import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String? id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "amount": amount,
      "category": category,
      "date": Timestamp.fromDate(date),
    };
  }

  factory Expense.fromMap(
      Map<String, dynamic> map,
      String documentId,
      ) {
    return Expense(
      id: documentId,
      title: map["title"] ?? "",
      amount: (map["amount"] as num).toDouble(),
      category: map["category"] ?? "",
      date: (map["date"] as Timestamp).toDate(),
    );
  }
}