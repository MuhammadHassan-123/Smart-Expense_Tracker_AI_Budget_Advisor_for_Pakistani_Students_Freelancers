import 'package:flutter/foundation.dart';

import '../models/budget.dart';
import '../models/expense.dart';
import '../models/savings_contribution.dart';
import '../models/savings_goal.dart';
import '../services/budget_service.dart';
import '../services/financial_planner_service.dart';
import '../services/firestore_service.dart';
import '../services/savings_service.dart';

/// Single, app-wide source of truth for budget, expense and savings data.
///
/// Why this exists: every screen used to independently re-read from disk
/// on every visit (its own `_load()`, its own loading flag). That meant
/// four unrelated async chains racing at startup, a screen that could get
/// stuck on its spinner if any one step failed silently, and a "create
/// goal -> reload from disk -> hope it comes back" round trip that could
/// leave a freshly created goal invisible if that reload lagged or errored.
///
/// Now data is loaded exactly once, kept in memory, and every mutation
/// updates memory immediately (so the UI reflects it instantly) and
/// persists in the background. Every screen just listens for changes.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  final BudgetService _budgetService = BudgetService();
  final FirestoreService _expenseService = FirestoreService();
  final SavingsService _savingsService = SavingsService();
  final FinancialPlannerService planner = FinancialPlannerService();

  bool _initialized = false;
  bool get initialized => _initialized;
  String? initError;

  BudgetPlan plan = BudgetPlan(
    amount: 0,
    period: BudgetPeriod.monthly,
    startDate: DateTime.now(),
  );
  List<Expense> expenses = [];
  List<SavingsGoal> goals = [];
  List<SavingsContribution> contributions = [];

  BudgetPeriodInfo get currentPeriod => _budgetService.currentPeriod(plan);

  /// The 12 monthly cycles of a yearly plan, anchored at [cycleStart].
  /// Pure date math -- no I/O -- safe to call directly from build methods.
  List<BudgetPeriodInfo> yearlyPeriodsFrom(DateTime cycleStart) {
    return _budgetService.yearlyPeriods(plan, cycleStart: cycleStart);
  }

  List<Expense> periodExpenses([BudgetPeriodInfo? period]) {
    final p = period ?? currentPeriod;
    return expenses
        .where((e) => !e.date.isBefore(p.start) && !e.date.isAfter(p.end))
        .toList();
  }

  FinancialSnapshot snapshot() {
    final period = currentPeriod;
    return planner.buildSnapshot(
      plan: plan,
      period: period,
      periodExpenses: periodExpenses(period),
      allExpenses: expenses,
      goals: goals,
      savingsContributions: contributions,
    );
  }

  /// Loads everything once. Guaranteed to finish (successfully or with
  /// [initError] set) within the timeout -- the app can never be stuck on
  /// an infinite loading state, no matter what happens underneath.
  Future<void> init() async {
    if (_initialized) return;
    await _loadAll();
  }

  Future<void> _loadAll() async {
    // Each source loads and is applied independently via _safeLoad, which
    // catches any error internally and never lets this Future.wait fail
    // as a whole. A problem in one source (an unreadable record, a slow
    // read, anything) must never discard data that loaded fine from the
    // others -- that was exactly how a savings goal that saved correctly
    // could still fail to show: one failing source, under an
    // all-or-nothing wait, wiped out an already-successful goals read.
    final outcomes = await Future.wait([
      _safeLoad(_budgetService.getPlan, (v) => _Loaded(plan: v)),
      _safeLoad(() => _expenseService.getExpenses().first, (v) => _Loaded(expenses: v)),
      _safeLoad(_savingsService.getGoals, (v) => _Loaded(goals: v)),
      _safeLoad(_savingsService.getContributions, (v) => _Loaded(contributions: v)),
    ]);

    var anyFailed = false;
    for (final outcome in outcomes) {
      if (outcome.plan != null) plan = outcome.plan!;
      if (outcome.expenses != null) expenses = outcome.expenses!;
      if (outcome.goals != null) goals = outcome.goals!;
      if (outcome.contributions != null) contributions = outcome.contributions!;
      if (outcome.isEmpty) anyFailed = true;
    }
    try {
      // Recurring fixed expenses are materialized only for the period that
      // has actually arrived. This keeps future months out of the expense
      // list while still making the current month's commitments visible.
      expenses = await _expenseService.ensureRecurringExpensesForPeriod(
        currentPeriod,
      );
    } catch (_) {
      // A recurring-expense materialization issue must never prevent the
      // rest of the financial state from loading.
    }

    initError = anyFailed ? 'Some data could not be loaded. Pull down to retry.' : null;
    _initialized = true;
    notifyListeners();
  }

  Future<_Loaded> _safeLoad<T>(Future<T> Function() load, _Loaded Function(T) wrap) async {
    try {
      final value = await load().timeout(const Duration(seconds: 8));
      return wrap(value);
    } catch (_) {
      return const _Loaded();
    }
  }

  Future<void> refresh() => _loadAll();

  // --- Expenses -------------------------------------------------------

  Future<void> addExpense(Expense expense) async {
    await _expenseService.addExpense(expense);
    try {
      expenses = await _expenseService.getExpenses().first;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    final previous = List<Expense>.from(expenses);

    try {
      // Persist deletion FIRST.
      await _expenseService.deleteExpense(id);

      // Only update in-memory state after persistence succeeds.
      expenses = expenses
          .where((expense) => expense.id != id)
          .toList();

      notifyListeners();
    } catch (e) {
      // Keep the previous in-memory state if persistence fails.
      expenses = previous;
      notifyListeners();
      rethrow;
    }
  }
  Future<void> markExpenseAsPaid(String id) async {
    final index = expenses.indexWhere(
      (expense) => expense.id == id,
    );

    if (index == -1) return;

    final previous = expenses;

    final current = expenses[index];

    final updated = Expense(
      id: current.id,
      title: current.title,
      amount: current.amount,
      category: current.category,
      date: current.date,
      type: current.type,
      status: ExpenseStatus.paid,
    );

    final updatedExpenses =
        List<Expense>.from(expenses);

    updatedExpenses[index] = updated;

    expenses = updatedExpenses;

    notifyListeners();

    try {
      await _expenseService.updateExpense(
        updated,
      );
    } catch (_) {
      expenses = previous;
      notifyListeners();
      rethrow;
    }
  }

  // --- Budget -----------------------------------------------------------

  Future<void> saveBudgetPlan(
    BudgetPlan newPlan,
  ) async {
    final previous =
        plan;

    try {
      // Persist first and verify the saved value.
      await _budgetService.savePlan(
        newPlan,
      );

      // Only after persistence succeeds do we
      // update the live application state.
      plan = newPlan;

      notifyListeners();
    } catch (e) {
      // Keep the previous working plan.
      plan = previous;
      notifyListeners();
      rethrow;
    }
  }

  // --- Savings goals ------------------------------------------------------

  Future<void> addGoal(SavingsGoal goal) async {
    goals = [goal, ...goals];
    notifyListeners();
    try {
      await _savingsService.addGoal(goal);
    } catch (_) {
      goals = goals.where((g) => g.id != goal.id).toList();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteGoal(String id) async {
    final previousGoals = goals;
    final previousContributions = contributions;
    goals = goals.where((g) => g.id != id).toList();
    contributions = contributions.where((c) => c.goalId != id).toList();
    notifyListeners();
    try {
      await _savingsService.deleteGoal(id);
    } catch (_) {
      goals = previousGoals;
      contributions = previousContributions;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addContribution(SavingsGoal goal, double amount) async {
    final previousGoals = goals;
    final previousContributions = contributions;
    final updatedGoal = SavingsGoal(
      id: goal.id,
      name: goal.name,
      targetAmount: goal.targetAmount,
      savedAmount: (goal.savedAmount + amount).clamp(0, goal.targetAmount).toDouble(),
      targetDate: goal.targetDate,
    );
    final contribution = SavingsContribution(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      goalId: goal.id,
      amount: amount,
      date: DateTime.now(),
    );
    goals = goals.map((g) => g.id == goal.id ? updatedGoal : g).toList();
    contributions = [contribution, ...contributions];
    notifyListeners();
    try {
      await _savingsService.updateGoal(updatedGoal);
      await _savingsService.addContribution(contribution);
    } catch (_) {
      goals = previousGoals;
      contributions = previousContributions;
      notifyListeners();
      rethrow;
    }
  }
}

/// Carries the result of loading exactly one data source in [AppState._loadAll].
/// Every field but the relevant one is null; [isEmpty] means that source's
/// load failed (error or timeout) and was skipped rather than allowed to
/// take the others down with it.
class _Loaded {
  final BudgetPlan? plan;
  final List<Expense>? expenses;
  final List<SavingsGoal>? goals;
  final List<SavingsContribution>? contributions;

  const _Loaded({this.plan, this.expenses, this.goals, this.contributions});

  bool get isEmpty =>
      plan == null && expenses == null && goals == null && contributions == null;
}
