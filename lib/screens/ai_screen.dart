import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/ai_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/spending_chart.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _ai = AIService();

  String _summary = '';
  bool _summaryLoading = true;
  String? _summaryError;

  @override
  void initState() {
    super.initState();
    _refreshSummary();
  }

  // The financial numbers themselves come straight from AppState (instant,
  // already loaded). Only the written advice is generated asynchronously,
  // and only that part shows a small inline loading state -- the rest of
  // the screen (chart, metrics) is visible immediately.
  Future<void> _refreshSummary() async {
    setState(() {
      _summaryLoading = true;
      _summaryError = null;
    });

    final state = AppState.instance;
    final period = state.currentPeriod;
    final periodExpenses = state.periodExpenses(period);
    final categoryTotals = <String, double>{};
    for (final expense in periodExpenses.where((e) => e.status == ExpenseStatus.paid)) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    final snapshot = state.snapshot();

    try {
      final summary = await _ai
          .getSummary(
            periodLabel: state.plan.periodLabel,
            periodBudget: snapshot.periodBudget,
            spent: snapshot.spent,
            committed: snapshot.committed,
            savedThisPeriod: snapshot.savedThisPeriod,
            available: snapshot.available,
            savingsReserve: snapshot.savingsReserve,
            requiredSavingsThisPeriod: snapshot.requiredSavingsThisPeriod,
            safeDailySpend: snapshot.safeDailySpend,
            projectedSpend: snapshot.projectedSpend,
            daysRemaining: period.daysRemaining,
            futureAllocation: snapshot.futureAllocation,
            goals: state.goals,
            spendingByCategory: categoryTotals,
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _summaryLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _summaryLoading = false;
        _summaryError = _summary.isEmpty ? 'Could not prepare advice right now.' : 'Could not refresh -- showing the last advice.';
      });
    }
  }

  String _money(double v) => 'Rs. ${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) => guardBuild('AI Advisor', () => AppState.instance.refresh(), () {
        final theme = Theme.of(context);
        final state = AppState.instance;
        final data = state.snapshot();
        final period = state.currentPeriod;
        final atRisk = data.projectedSpend > data.periodBudget + 1;
        final allocationTotal = data.futureAllocation.values.fold<double>(0, (sum, v) => sum + v);

        return Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(
            title: const Text('AI Advisor'),
            actions: [IconButton(onPressed: _refreshSummary, tooltip: 'Refresh advice', icon: const Icon(Icons.refresh_rounded))],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await state.refresh();
                await _refreshSummary();
              },
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                children: [
                  Text('A clear view of what to do next', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text('${data.plan.periodLabel} cycle • ${period.daysRemaining} days remaining', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 18),

                  // 1. Short advice summary -- always first.
                  FadeSlideIn(
                    child: GradientSurface(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(11)),
                                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 17),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(child: Text('Your advice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15))),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (_summaryLoading && _summary.isEmpty)
                            const _SummarySkeleton()
                          else
                            Text(_summary, style: const TextStyle(color: Colors.white, height: 1.55, fontSize: 14.5, fontWeight: FontWeight.w500)),
                          if (_summaryError != null) ...[
                            const SizedBox(height: 10),
                            Text(_summaryError!, style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),
                  // 2. Pie chart -- how the remaining money should be split.
                  // Only categories the person actually spends in appear;
                  // see FinancialPlannerService for the ranking logic.
                  Text('Where your remaining money should go', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 5),
                  Text('Based on your own spending, not a slice for every category.', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    index: 1,
                    child: FlatSurface(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                      child: data.futureAllocation.isEmpty
                          ? const SizedBox(height: 180, child: Center(child: Text('No remaining budget to plan.')))
                          : SpendingDistributionChart(values: data.futureAllocation, centerLabel: 'Future plan', showLegend: true, sortByValue: false),
                    ),
                  ),

                  const SizedBox(height: 26),
                  // 3. Supporting metrics.
                  FadeSlideIn(
                    index: 2,
                    child: Row(
                      children: [
                        Expanded(child: _Metric(label: 'Available', value: _money(data.available))),
                        const SizedBox(width: 10),
                        Expanded(child: _Metric(label: 'Savings reserve', value: _money(data.savingsReserve))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeSlideIn(
                    index: 3,
                    child: Row(
                      children: [
                        Expanded(child: _Metric(label: 'Safe / day', value: _money(data.safeDailySpend))),
                        const SizedBox(width: 10),
                        Expanded(child: _Metric(label: atRisk ? 'At risk' : 'On track', value: _money(data.projectedSpend), danger: atRisk)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  FadeSlideIn(
                    index: 4,
                    child: FlatSurface(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Plan at a glance', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 12),
                          _PlanLine(label: 'Savings first', value: _money(data.savingsReserve)),
                          _PlanLine(label: 'Future spending', value: _money((allocationTotal - data.savingsReserve).clamp(0, double.infinity).toDouble())),
                          _PlanLine(label: 'Daily safe spend', value: _money(data.safeDailySpend)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.2, valueColor: AlwaysStoppedAnimation(Colors.white))),
        SizedBox(width: 10),
        Text('Preparing your advice…', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool danger;
  const _Metric({required this.label, required this.value, this.danger = false});
  @override
  Widget build(BuildContext context) => FlatSurface(
        padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 5),
            FittedBox(
              alignment: Alignment.centerLeft,
              child: Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: danger ? AppColors.danger : AppColors.ink)),
            ),
          ],
        ),
      );
}

class _PlanLine extends StatelessWidget {
  final String label;
  final String value;
  const _PlanLine({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      );
}
