import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';

class FirestoreService {
  static const String _expensesKey = 'saved_expenses';

  Future<List<Expense>> _loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();

    final String? data = prefs.getString(_expensesKey);

    if (data == null || data.isEmpty) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(data);

    return decoded.map((item) {
      return Expense(
        id: item['id'],
        title: item['title'] ?? '',
        amount: (item['amount'] as num).toDouble(),
        category: item['category'] ?? '',
        date: DateTime.parse(item['date']),
      );
    }).toList();
  }

  Future<void> _saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();

    final data = expenses.map((expense) {
      return {
        'id': expense.id,
        'title': expense.title,
        'amount': expense.amount,
        'category': expense.category,
        'date': expense.date.toIso8601String(),
      };
    }).toList();

    await prefs.setString(
      _expensesKey,
      jsonEncode(data),
    );
  }

  Future<void> addExpense(Expense expense) async {
    final expenses = await _loadExpenses();

    final newExpense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: expense.title,
      amount: expense.amount,
      category: expense.category,
      date: expense.date,
    );

    expenses.insert(0, newExpense);

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