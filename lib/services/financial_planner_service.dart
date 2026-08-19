import '../models/budget.dart';
import '../models/expense.dart';
import '../models/savings_contribution.dart';
import '../models/savings_goal.dart';

class FinancialSnapshot {
  final BudgetPlan plan;
  final BudgetPeriodInfo period;
  final double periodBudget;
  final List<Expense> expenses;
  final double spent;
  final double committed;
  final double savedThisPeriod;
  final double available;
  final double requiredSavingsThisPeriod;
  final double savingsReserve;
  final double safeDailySpend;
  final double projectedSpend;
  final Map<String, double> futureAllocation;
  final List<SavingsGoal> goals;
  final double carryForwardAmount;

  const FinancialSnapshot({
    required this.plan,
    required this.period,
    required this.periodBudget,
    required this.expenses,
    required this.spent,
    required this.committed,
    required this.savedThisPeriod,
    required this.available,
    required this.requiredSavingsThisPeriod,
    required this.savingsReserve,
    required this.safeDailySpend,
    required this.projectedSpend,
    required this.futureAllocation,
    required this.goals,
    this.carryForwardAmount = 0,
  });
}

class FinancialPlannerService {
  double currentPeriodBudget(BudgetPlan plan, BudgetPeriodInfo period) {
    final allocations = plan.normalizedAllocations;
    if (plan.period == BudgetPeriod.monthly) return plan.amount;
    return allocations[_periodIndex(plan, period)];
  }

  FinancialSnapshot buildSnapshot({
    required BudgetPlan plan,
    required BudgetPeriodInfo period,
    required List<Expense> periodExpenses,
    required List<Expense> allExpenses,
    required List<SavingsGoal> goals,
    required List<SavingsContribution> savingsContributions,
  }) {
    final allocations = plan.normalizedAllocations;
    final periodIndex = plan.period == BudgetPeriod.yearly
        ? _periodIndex(plan, period)
        : 0;
    final basePeriodBudget = plan.period == BudgetPeriod.yearly
        ? allocations[periodIndex]
        : plan.amount;

    final carryForward = plan.carryForward
        ? _previousUnused(plan, period, allExpenses, periodIndex, allocations)
        : 0.0;
    final periodBudget = basePeriodBudget + carryForward;

    final spent = periodExpenses
        .where((expense) => expense.status == ExpenseStatus.paid)
        .fold<double>(0, (sum, expense) => sum + expense.amount);

    final committed = periodExpenses
        .where((expense) => expense.status == ExpenseStatus.upcoming)
        .fold<double>(0, (sum, expense) => sum + expense.amount);

    final savedThisPeriod = savingsContributions
        .where(
          (item) =>
              !item.date.isBefore(period.start) &&
              !item.date.isAfter(period.end),
        )
        .fold<double>(0, (sum, item) => sum + item.amount);

    final rawAvailable = periodBudget - spent - committed - savedThisPeriod;
    final available = _max(0, rawAvailable);

    // Savings goals are funded before discretionary future spending.
    // If a contribution has already been made in this cycle, only the
    // remaining required saving is reserved.
    final requiredSavings = goals.fold<double>(0, (sum, goal) {
      final alreadyContributed = savingsContributions
          .where(
            (item) =>
                item.goalId == goal.id &&
                !item.date.isBefore(period.start) &&
                !item.date.isAfter(period.end),
          )
          .fold<double>(0, (goalSum, item) => goalSum + item.amount);
      final remainingThisCycle = _max(
        0,
        goal.requiredMonthlySaving(period.start) - alreadyContributed,
      );
      return sum + remainingThisCycle;
    });

    final savingsReserve = _min(requiredSavings, available);
    final spendable = _max(0, available - savingsReserve);

    final days = period.daysRemaining < 1 ? 1 : period.daysRemaining;
    final safeDaily = spendable / days;

    final elapsedDays = period.daysElapsed < 1 ? 1 : period.daysElapsed;
    final currentDaily = (spent + committed) / elapsedDays;
    final projectedSpend = currentDaily * period.totalDays;

    return FinancialSnapshot(
      plan: plan,
      period: period,
      periodBudget: periodBudget,
      expenses: periodExpenses,
      spent: spent,
      committed: committed,
      savedThisPeriod: savedThisPeriod,
      available: available,
      requiredSavingsThisPeriod: requiredSavings,
      savingsReserve: savingsReserve,
      safeDailySpend: safeDaily,
      projectedSpend: projectedSpend,
      futureAllocation: _futureAllocation(
        periodExpenses: periodExpenses,
        allExpenses: allExpenses,
        spendable: spendable,
        savingsReserve: savingsReserve,
        period: period,
      ),
      goals: goals,
      carryForwardAmount: carryForward,
    );
  }

  /// Recommends how the money still left this period should be split.
  ///
  /// This is deliberately NOT "divide by every possible category" -- it
  /// only proposes a category if the person's own spending shows it's
  /// actually relevant to them, ranked by real recent spend, capped to a
  /// handful of the biggest ones, plus a savings reserve and a modest
  /// emergency buffer. A category they never spend in simply doesn't
  /// appear.
  Map<String, double> _futureAllocation({
    required List<Expense> periodExpenses,
    required List<Expense> allExpenses,
    required double spendable,
    required double savingsReserve,
    required BudgetPeriodInfo period,
  }) {
    final result = <String, double>{};

    // Savings is deliberately inserted first. This makes it visually and
    // conceptually clear that goals are reserved before optional spending.
    if (savingsReserve > 0) {
      result['Savings'] = savingsReserve;
    }

    if (spendable <= 0) return result;

    final blockedCategories = <String>{};
    final variableHistory = <String, double>{};

    void tally(Iterable<Expense> source) {
      for (final expense in source) {
        final canonical = _canonicalCategory(expense.category, expense.title);
        final fixedLike = _looksLikeFixedCommitment(expense);

        if (expense.type == ExpenseType.fixed || fixedLike) {
          // Fixed-like items already paid or committed shouldn't receive a
          // second future allocation in the same cycle.
          blockedCategories.add(canonical);
        } else if (expense.status == ExpenseStatus.paid) {
          variableHistory[canonical] =
              (variableHistory[canonical] ?? 0) + expense.amount;
        }
      }
    }

    tally(periodExpenses);

    // Early in a fresh cycle there may be no spending logged yet -- fall
    // back to the last 30 days so the recommendation still reflects real
    // habits instead of guessing blind.
    if (variableHistory.isEmpty) {
      final lookback = period.start.subtract(const Duration(days: 30));
      tally(
        allExpenses.where(
          (expense) =>
              !expense.date.isBefore(lookback) &&
              expense.date.isBefore(period.start),
        ),
      );
    }

    final ranked = variableHistory.entries
        .where(
          (entry) =>
              entry.value > 0 &&
              !_isBlockedCategory(entry.key, blockedCategories),
        )
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Keep the plan lean: the biggest few categories the person actually
    // spends in, not a slice for every category that exists.
    final topCategories = ranked.take(4).toList();

    if (topCategories.isEmpty) {
      // No usable spending history at all -- brand-new account, or every
      // logged expense so far was fixed/committed. Offer two honest,
      // general buckets rather than fabricating a per-category guess.
      result['Everyday spending'] = spendable * 0.65;
      result['Emergency buffer'] = spendable * 0.35;
      return result;
    }

    var remaining = spendable;
    final hasEmergency = topCategories.any((entry) => entry.key == 'Emergency');
    if (!hasEmergency) {
      // Standard, sensible financial advice: keep a small buffer before
      // splitting the rest across regular spending categories.
      final buffer = spendable * 0.12;
      result['Emergency buffer'] = buffer;
      remaining -= buffer;
    }

    final weightTotal = topCategories.fold<double>(0, (sum, e) => sum + e.value);
    if (weightTotal > 0) {
      for (final entry in topCategories) {
        final share = remaining * (entry.value / weightTotal);
        if (share > 0) result[entry.key] = share;
      }
    }

    return result;
  }

  double _previousUnused(
    BudgetPlan plan,
    BudgetPeriodInfo current,
    List<Expense> allExpenses,
    int currentIndex,
    List<double> allocations,
  ) {
    final previousStart = DateTime(
      current.start.year,
      current.start.month - 1,
      current.start.day,
    );
    final previousEnd = current.start.subtract(const Duration(days: 1));
    final previousExpenses = allExpenses.where(
      (expense) =>
          !expense.date.isBefore(previousStart) &&
          !expense.date.isAfter(previousEnd),
    );

    final previousSpent = previousExpenses
        .where((expense) => expense.status == ExpenseStatus.paid)
        .fold<double>(0, (sum, expense) => sum + expense.amount);
    final previousCommitted = previousExpenses
        .where((expense) => expense.status == ExpenseStatus.upcoming)
        .fold<double>(0, (sum, expense) => sum + expense.amount);
    final previousTarget = plan.period == BudgetPeriod.yearly
        ? allocations[(currentIndex - 1 + 12) % 12]
        : plan.amount;

    return _max(0, previousTarget - previousSpent - previousCommitted);
  }

  bool _isBlockedCategory(String category, Set<String> blocked) {
    if (category == 'Bills & Internet') {
      return blocked.contains('Bills & Internet') ||
          blocked.contains('Internet');
    }
    return blocked.contains(category);
  }

  bool _looksLikeFixedCommitment(Expense expense) {
    final text = '${expense.title} ${expense.category}'.toLowerCase();
    const keywords = [
      'hostel',
      'rent',
      'housing',
      'mess',
      'meal plan',
      'tuition',
      'semester fee',
      'internet package',
      'subscription',
      'utility',
    ];
    return keywords.any(text.contains);
  }

  String _canonicalCategory(String category, String title) {
    final value = '$category $title'.toLowerCase();
    if (value.contains('hostel') ||
        value.contains('rent') ||
        value.contains('housing')) {
      return 'Housing';
    }
    if (value.contains('mess') || value.contains('meal plan')) {
      return 'Food';
    }
    if (value.contains('internet') ||
        value.contains('jazz') ||
        value.contains('zong') ||
        value.contains('ufone') ||
        value.contains('telenor')) {
      return 'Internet';
    }
    if (category == 'Bills') return 'Bills & Internet';
    return category;
  }

  int _periodIndex(BudgetPlan plan, BudgetPeriodInfo current) {
    var anchor = DateTime(
      current.start.year,
      plan.startDate.month,
      _safeDay(
        current.start.year,
        plan.startDate.month,
        plan.startDate.day,
      ),
    );
    if (current.start.isBefore(anchor)) {
      anchor = DateTime(
        anchor.year - 1,
        anchor.month,
        _safeDay(anchor.year - 1, anchor.month, plan.startDate.day),
      );
    }

    return ((current.start.year - anchor.year) * 12 +
            current.start.month - anchor.month)
        .clamp(0, 11)
        .toInt();
  }

  int _safeDay(int year, int month, int requested) {
    final last = DateTime(year, month + 1, 0).day;
    return requested.clamp(1, last).toInt();
  }

  double _min(double a, double b) => a < b ? a : b;
  double _max(double a, double b) => a > b ? a : b;
}
