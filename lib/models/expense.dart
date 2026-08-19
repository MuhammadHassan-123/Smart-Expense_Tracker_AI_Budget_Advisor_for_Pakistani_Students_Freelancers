import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseType { variable, fixed }
enum ExpenseStatus { paid, upcoming }
enum ExpenseRecurrence { none, daily, weekly, monthly, yearly }

extension ExpenseRecurrenceLabel on ExpenseRecurrence {
  String get label {
    switch (this) {
      case ExpenseRecurrence.none:
        return 'None / Not sure';
      case ExpenseRecurrence.daily:
        return 'Daily';
      case ExpenseRecurrence.weekly:
        return 'Weekly';
      case ExpenseRecurrence.monthly:
        return 'Monthly';
      case ExpenseRecurrence.yearly:
        return 'Yearly';
    }
  }
}

class Expense {
  final String? id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final ExpenseType type;
  final ExpenseStatus status;
  final ExpenseRecurrence recurrence;
  final String? recurrenceId;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.type = ExpenseType.variable,
    this.status = ExpenseStatus.paid,
    this.recurrence = ExpenseRecurrence.none,
    this.recurrenceId,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'amount': amount,
        'category': category,
        'date': Timestamp.fromDate(date),
        'type': type.name,
        'status': status.name,
        'recurrence': recurrence.name,
        'recurrenceId': recurrenceId,
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
      recurrence: ExpenseRecurrence.values.firstWhere(
        (value) => value.name == map['recurrence']?.toString(),
        orElse: () => ExpenseRecurrence.none,
      ),
      recurrenceId: map['recurrenceId']?.toString(),
    );
  }
}
