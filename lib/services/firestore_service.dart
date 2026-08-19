import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/budget.dart';
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
          recurrence: ExpenseRecurrence.values.firstWhere(
            (value) => value.name == map['recurrence']?.toString(),
            orElse: () => ExpenseRecurrence.none,
          ),
          recurrenceId: map['recurrenceId']?.toString(),
        ));
      } catch (_) {
        // Skip only malformed entries.
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
      'recurrence': expense.recurrence.name,
      'recurrenceId': expense.recurrenceId,
    }).toList();
    await prefs.setString(_expensesKey, jsonEncode(data));
  }

  Future<void> addExpense(Expense expense) async {
    final expenses = await _loadExpenses();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final recurring = expense.type == ExpenseType.fixed &&
        expense.recurrence != ExpenseRecurrence.none;

    final newExpense = Expense(
      id: id,
      title: expense.title,
      amount: expense.amount,
      category: expense.category,
      date: expense.date,
      type: expense.type,
      // A recurring fixed expense is a commitment for its current
      // occurrence. The user can explicitly mark that occurrence paid.
      status: recurring ? ExpenseStatus.upcoming : expense.status,
      recurrence: expense.type == ExpenseType.fixed
          ? expense.recurrence
          : ExpenseRecurrence.none,
      recurrenceId: recurring ? id : null,
    );
    expenses.insert(0, newExpense);
    await _saveExpenses(expenses);
  }

  Future<void> updateExpense(Expense expense) async {
    final id = expense.id;

    if (id == null || id.isEmpty) {
      throw Exception('Cannot update an expense without an ID.');
    }

    final expenses = await _loadExpenses();
    final index = expenses.indexWhere((item) => item.id == id);

    if (index == -1) {
      throw Exception('Expense not found.');
    }

    expenses[index] = Expense(
      id: expense.id,
      title: expense.title,
      amount: expense.amount,
      category: expense.category,
      date: expense.date,
      type: expense.type,
      status: expense.status,
      recurrence: expense.recurrence,
      recurrenceId: expense.recurrenceId,
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

  /// Materializes only occurrences whose due date falls inside the current
  /// financial period. It never pre-creates future periods.
  ///
  /// Existing recurring records act as the recurring rule. All occurrences
  /// share the same recurrenceId, while each occurrence has its own expense
  /// id and date/status, so marking one occurrence paid never changes another.
  Future<List<Expense>> ensureRecurringExpensesForPeriod(
    BudgetPeriodInfo period,
  ) async {
    final expenses = await _loadExpenses();
    if (expenses.isEmpty) return expenses;

    final recurring = expenses
        .where(
          (expense) =>
              expense.type == ExpenseType.fixed &&
              expense.recurrence != ExpenseRecurrence.none &&
              (expense.recurrenceId?.isNotEmpty ?? false),
        )
        .toList();

    if (recurring.isEmpty) return expenses;

    final byRecurrenceId = <String, List<Expense>>{};
    for (final expense in recurring) {
      final key = expense.recurrenceId!;
      (byRecurrenceId[key] ??= <Expense>[]).add(expense);
    }

    bool changed = false;

    for (final group in byRecurrenceId.entries) {
      final records = group.value
        ..sort((a, b) => a.date.compareTo(b.date));
      final template = records.first;

      final dueDates = _occurrencesForPeriod(
        template.date,
        template.recurrence,
        period,
      );

      for (final dueDate in dueDates) {
        if (_hasOccurrence(
          expenses,
          group.key,
          dueDate,
        )) {
          continue;
        }

        expenses.add(
          Expense(
            id: '${group.key}:${_dateKey(dueDate)}',
            title: template.title,
            amount: template.amount,
            category: template.category,
            date: dueDate,
            type: ExpenseType.fixed,
            status: ExpenseStatus.upcoming,
            recurrence: template.recurrence,
            recurrenceId: group.key,
          ),
        );
        changed = true;
      }
    }

    if (changed) {
      expenses.sort((a, b) => b.date.compareTo(a.date));
      await _saveExpenses(expenses);
    }

    return expenses;
  }

  bool _hasOccurrence(
    List<Expense> expenses,
    String recurrenceId,
    DateTime dueDate,
  ) {
    final key = _dateKey(dueDate);
    return expenses.any(
      (expense) =>
          expense.recurrenceId == recurrenceId &&
          _dateKey(expense.date) == key,
    );
  }

  List<DateTime> _occurrencesForPeriod(
    DateTime start,
    ExpenseRecurrence recurrence,
    BudgetPeriodInfo period,
  ) {
    if (recurrence == ExpenseRecurrence.none) return const [];

    final dates = <DateTime>[];
    var cursor = _firstOccurrenceOnOrAfter(
      start,
      recurrence,
      period.start,
    );

    var safety = 0;
    while (!cursor.isAfter(period.end) && safety < 400) {
      if (!cursor.isBefore(period.start)) {
        dates.add(cursor);
      }
      final next = _nextOccurrence(cursor, recurrence);
      if (next == cursor) break;
      cursor = next;
      safety++;
    }

    return dates;
  }

  DateTime _firstOccurrenceOnOrAfter(
    DateTime template,
    ExpenseRecurrence recurrence,
    DateTime periodStart,
  ) {
    var cursor = template;
    if (!cursor.isBefore(periodStart)) return cursor;

    switch (recurrence) {
      case ExpenseRecurrence.daily:
        final days = periodStart.difference(_dateOnly(cursor)).inDays;
        final step = days < 0 ? 0 : days;
        return _dateOnly(cursor).add(Duration(days: step));
      case ExpenseRecurrence.weekly:
        final days = periodStart.difference(_dateOnly(cursor)).inDays;
        final weeks = days <= 0 ? 0 : (days / 7).floor();
        var candidate = _dateOnly(cursor).add(Duration(days: weeks * 7));
        while (candidate.isBefore(periodStart)) {
          candidate = candidate.add(const Duration(days: 7));
        }
        return candidate;
      case ExpenseRecurrence.monthly:
        var candidate = _sameDayInMonth(
          cursor,
          periodStart.year,
          periodStart.month,
        );
        if (candidate.isBefore(periodStart)) {
          candidate = _sameDayInMonth(
            cursor,
            periodStart.month == 12 ? periodStart.year + 1 : periodStart.year,
            periodStart.month == 12 ? 1 : periodStart.month + 1,
          );
        }
        return candidate;
      case ExpenseRecurrence.yearly:
        var candidate = _sameDayInMonth(
          cursor,
          periodStart.year,
          cursor.month,
        );
        if (candidate.isBefore(periodStart)) {
          candidate = DateTime(
            periodStart.year + 1,
            cursor.month,
            _safeDay(periodStart.year + 1, cursor.month, cursor.day),
          );
        }
        return candidate;
      case ExpenseRecurrence.none:
        return cursor;
    }
  }

  DateTime _nextOccurrence(
    DateTime current,
    ExpenseRecurrence recurrence,
  ) {
    switch (recurrence) {
      case ExpenseRecurrence.daily:
        return current.add(const Duration(days: 1));
      case ExpenseRecurrence.weekly:
        return current.add(const Duration(days: 7));
      case ExpenseRecurrence.monthly:
        return _sameDayInMonth(
          current,
          current.month == 12 ? current.year + 1 : current.year,
          current.month == 12 ? 1 : current.month + 1,
        );
      case ExpenseRecurrence.yearly:
        return DateTime(
          current.year + 1,
          current.month,
          _safeDay(current.year + 1, current.month, current.day),
        );
      case ExpenseRecurrence.none:
        return current;
    }
  }

  DateTime _sameDayInMonth(
    DateTime source,
    int year,
    int month,
  ) {
    return DateTime(
      year,
      month,
      _safeDay(year, month, source.day),
    );
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  int _safeDay(int year, int month, int requestedDay) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return requestedDay.clamp(1, lastDay).toInt();
  }

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
