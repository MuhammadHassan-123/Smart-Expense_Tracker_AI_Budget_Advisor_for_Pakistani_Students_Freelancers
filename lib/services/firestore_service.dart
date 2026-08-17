import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';

class FirestoreService {
  static const String _expensesKey = 'saved_expenses';

  Future<List<Expense>> _loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_expensesKey);
    if (data == null || data.isEmpty) return [];

    List<dynamic> decoded;
    try {
      decoded = jsonDecode(data) as List<dynamic>;
    } catch (_) {
      // Corrupted store (e.g. a partial write). Losing this is better
      // than the whole app failing to load anything at all.
      return [];
    }

    final expenses = <Expense>[];
    for (final item in decoded) {
      try {
        final map = Map<String, dynamic>.from(item as Map);
        expenses.add(Expense(
          id: map['id']?.toString(),
          title: map['title'] ?? '',
          amount: (map['amount'] as num).toDouble(),
          category: map['category'] ?? '',
          date: DateTime.parse(map['date'].toString()),
          type: ExpenseType.values.firstWhere(
            (value) => value.name == map['type']?.toString(),
            orElse: () => ExpenseType.variable,
          ),
          status: ExpenseStatus.values.firstWhere(
            (value) => value.name == map['status']?.toString(),
            orElse: () => ExpenseStatus.paid,
          ),
        ));
      } catch (_) {
        // Skip just this one malformed entry rather than losing every
        // expense (and, transitively, every other screen that loads
        // alongside expenses) over a single bad record.
      }
    }
    return expenses;
  }

  Future<void> _saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final data = expenses.map((expense) => {
      'id': expense.id,
      'title': expense.title,
      'amount': expense.amount,
      'category': expense.category,
      'date': expense.date.toIso8601String(),
      'type': expense.type.name,
      'status': expense.status.name,
    }).toList();
    await prefs.setString(_expensesKey, jsonEncode(data));
  }

  Future<void> addExpense(Expense expense) async {
    final expenses = await _loadExpenses();
    final newExpense = Expense(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: expense.title,
      amount: expense.amount,
      category: expense.category,
      date: expense.date,
      type: expense.type,
      status: expense.status,
    );
    expenses.insert(0, newExpense);
    await _saveExpenses(expenses);
  }
  Future<void> updateExpense(
    Expense expense,
  ) async {
    final id = expense.id;

    if (id == null || id.isEmpty) {
      throw Exception(
        'Cannot update an expense without an ID.',
      );
    }

    final expenses = await _loadExpenses();

    final index = expenses.indexWhere(
      (item) => item.id == id,
    );

    if (index == -1) {
      throw Exception(
        'Expense not found.',
      );
    }

    expenses[index] = Expense(
      id: expense.id,
      title: expense.title,
      amount: expense.amount,
      category: expense.category,
      date: expense.date,
      type: expense.type,
      status: expense.status,
    );

    await _saveExpenses(expenses);
  }

  Stream<List<Expense>> getExpenses() async* {
    yield await _loadExpenses();
  }

  Future<void> deleteExpense(String id) async {
    final expenses = await _loadExpenses();
    expenses.removeWhere((expense) => expense.id == id);
    await _saveExpenses(expenses);
  }
}
