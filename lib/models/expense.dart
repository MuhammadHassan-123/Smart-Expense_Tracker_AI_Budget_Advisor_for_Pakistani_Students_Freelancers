import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseType { variable, fixed }
enum ExpenseStatus { paid, upcoming }

class Expense {
  final String? id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final ExpenseType type;
  final ExpenseStatus status;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.type = ExpenseType.variable,
    this.status = ExpenseStatus.paid,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'amount': amount,
        'category': category,
        'date': Timestamp.fromDate(date),
        'type': type.name,
        'status': status.name,
      };

  factory Expense.fromMap(Map<String, dynamic> map, String documentId) {
    return Expense(
      id: documentId,
      title: map['title'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      type: ExpenseType.values.firstWhere(
        (value) => value.name == map['type']?.toString(),
        orElse: () => ExpenseType.variable,
      ),
      status: ExpenseStatus.values.firstWhere(
        (value) => value.name == map['status']?.toString(),
        orElse: () => ExpenseStatus.paid,
      ),
    );
  }
}
