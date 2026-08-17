import 'package:flutter/material.dart';

import '../models/budget.dart';
import '../models/expense.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/spending_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  String _money(double v) => 'Rs. ${v.toStringAsFixed(0)}';
  String _date(DateTime d) => '${d.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]}';

  Map<String, double> _categoryTotals(List<Expense> expenses) {
    final result = <String, double>{};
    for (final e in expenses) {
      result[e.category] = (result[e.category] ?? 0) + e.amount;
    }
    return result;
  }

  double _periodSpent(List<Expense> allExpenses, BudgetPeriodInfo period) {
    return allExpenses
        .where((e) => e.status == ExpenseStatus.paid && !e.date.isBefore(period.start) && !e.date.isAfter(period.end))
        .fold<double>(0, (sum, e) => sum + e.amount);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) => guardBuild('Analytics', () => AppState.instance.refresh(), () {
        final theme = Theme.of(context);
        final state = AppState.instance;
        final plan = state.plan;
        final period = state.currentPeriod;
        final periodExpenses = state.periodExpenses(period);
        final allExpenses = state.expenses;
        final snapshot = state.snapshot();
        final categoryTotals = _categoryTotals(periodExpenses);
        final total = periodExpenses.fold<double>(0, (sum, e) => sum + e.amount);
        final topCategory = categoryTotals.isEmpty ? 'No spending' : categoryTotals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
        final yearPeriods = plan.period == BudgetPeriod.yearly
            ? state.yearlyPeriodsFrom(period.start)
            : <BudgetPeriodInfo>[];

        return Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(title: const Text('Analytics')),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: state.refresh,
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
                children: [
                  Text('Understand your spending', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 5),
                  Text('${plan.periodLabel} view • ${_date(period.start)} – ${_date(period.end)}', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 20),
                  FadeSlideIn(
                    child: Row(
                      children: [
                        Expanded(child: _Metric(label: 'Spent', value: _money(total))),
                        const SizedBox(width: 10),
                        Expanded(child: _Metric(label: 'Top category', value: topCategory)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeSlideIn(index: 1, child: _Metric(label: 'Safe daily spend', value: _money(snapshot.safeDailySpend))),
                  const SizedBox(height: 24),
                  Text('Category mix', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    index: 2,
                    child: FlatSurface(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                      child: periodExpenses.isEmpty
                          ? const SizedBox(height: 220, child: Center(child: Text('No spending recorded for this period.')))
                          : SpendingChart(expenses: periodExpenses),
                    ),
                  ),
                  if (plan.period == BudgetPeriod.yearly) ...[
                    const SizedBox(height: 28),
                    Text('Year at a glance', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text('Your 12 budget months with planned and actual spending.', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 14),
                    ...List.generate(yearPeriods.length, (index) {
                      final p = yearPeriods[index];
                      final spent = _periodSpent(allExpenses, p);
                      final target = plan.normalizedAllocations[index];
                      final ratio = target <= 0 ? 0.0 : (spent / target).clamp(0.0, 1.0).toDouble();
                      final isCurrent = p.start == period.start;
                      return FadeSlideIn(
                        index: index + 3,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: FlatSurface(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(child: Text('${_date(p.start)} – ${_date(p.end)}', style: const TextStyle(fontWeight: FontWeight.w700))),
                                  if (isCurrent) const StatusPill(label: 'Current', color: AppColors.primary),
                                ]),
                                const SizedBox(height: 9),
                                Row(children: [
                                  Expanded(child: AnimatedBar(value: ratio, minHeight: 7)),
                                  const SizedBox(width: 12),
                                  Text('${ratio * 100 >= 100 ? 100 : (ratio * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w800)),
                                ]),
                                const SizedBox(height: 8),
                                Row(children: [
                                  Expanded(child: Text('Spent ${_money(spent)}', style: theme.textTheme.bodySmall)),
                                  Text('Plan ${_money(target)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                ]),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 22),
                  Text('Category details', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 10),
                  if (categoryTotals.isEmpty)
                    FlatSurface(padding: const EdgeInsets.all(18), child: Text('Add expenses to see category details.', style: theme.textTheme.bodyMedium))
                  else
                    ...((categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
                        .toList()
                        .asMap()
                        .entries
                        .map((row) => FadeSlideIn(
                              index: row.key,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: FlatSurface(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  child: Row(
                                    children: [
                                      IconBadge(icon: Icons.category_rounded, color: AppColors.forCategory(row.value.key), size: 38, iconSize: 18),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(row.value.key, style: const TextStyle(fontWeight: FontWeight.w700))),
                                      Text(_money(row.value.value), style: const TextStyle(fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                                ),
                              ),
                            ))),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => FlatSurface(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
      );
}
