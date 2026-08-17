import 'package:flutter/material.dart';

import '../models/budget.dart';
import '../models/expense.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/expense_card.dart';
import '../widgets/expense_form.dart';
import 'budget_screen.dart';
import 'receipt_scanner_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _addExpense(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ExpenseForm(
        onSave: (expense) => AppState.instance.addExpense(expense),
      ),
    );
  }

  Future<void> _scanReceipt(BuildContext context) async {
    final scanned = await Navigator.push<Expense>(context, softRoute(const ReceiptScannerScreen()));
    if (scanned != null) {
      await AppState.instance.addExpense(scanned);
    }
  }

  String _money(double value) => 'Rs. ${value.toStringAsFixed(0)}';

  String _date(DateTime value) =>
      '${value.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][value.month - 1]}';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) => guardBuild('Home', () => AppState.instance.refresh(), () {
        final state = AppState.instance;
        final theme = Theme.of(context);
        final period = state.currentPeriod;
        final expenses = state.periodExpenses(period);
        final snapshot = state.snapshot();

        final totalUsed = snapshot.spent + snapshot.committed + snapshot.savedThisPeriod;
        final progress = snapshot.periodBudget <= 0
            ? 0.0
            : (totalUsed / snapshot.periodBudget).clamp(0.0, 1.0).toDouble();

        return Scaffold(
          backgroundColor: AppColors.canvas,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addExpense(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add expense'),
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: state.refresh,
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                children: [
                  if (state.initError != null) ...[
                    FlatSurface(
                      color: const Color(0xFFF7E9E3),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.clay, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(state.initError!, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.clay))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Good to see you', style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 3),
                            Text('Your money at a glance', style: theme.textTheme.headlineSmall),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Budget plan',
                        onPressed: () => Navigator.push(context, softRoute(const BudgetScreen())),
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  FadeSlideIn(
                    child: GradientSurface(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${state.plan.periodLabel} plan',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  '${period.daysRemaining} days left',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_date(period.start)} – ${_date(period.end)}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.76), fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 22),
                          AnimatedMoney(
                            value: snapshot.available,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 34, letterSpacing: -0.8),
                          ),
                          Text('available to spend', style: TextStyle(color: Colors.white.withValues(alpha: 0.76), fontSize: 12.5, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 20),
                          AnimatedBar(
                            value: progress,
                            minHeight: 8,
                            background: Colors.white.withValues(alpha: 0.22),
                            color: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _HeroStat(label: 'Budget', value: _money(snapshot.periodBudget))),
                              Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
                              Expanded(child: _HeroStat(label: 'Spent', value: _money(snapshot.spent), alignEnd: true)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  FadeSlideIn(
                    index: 1,
                    child: Row(
                      children: [
                        Expanded(child: _SmallMetric(icon: Icons.speed_rounded, color: AppColors.slateBlue, label: 'Safe daily spend', value: _money(snapshot.safeDailySpend))),
                        const SizedBox(width: 12),
                        Expanded(child: _SmallMetric(icon: Icons.savings_rounded, color: AppColors.primary, label: 'Savings reserve', value: _money(snapshot.savingsReserve))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  FadeSlideIn(index: 2, child: _ActionRow(onScan: () => _scanReceipt(context))),

                  if (state.plan.period == BudgetPeriod.yearly) ...[
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      index: 3,
                      child: PressableScale(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.push(context, softRoute(const BudgetScreen())),
                        child: FlatSurface(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          child: Row(
                            children: [
                              const IconBadge(icon: Icons.calendar_view_month_rounded, color: AppColors.clay),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Yearly plan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                    const SizedBox(height: 2),
                                    Text('Target ${_money(snapshot.periodBudget)} • ${period.daysRemaining} days left', style: theme.textTheme.bodySmall),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(child: Text('Recent transactions', style: theme.textTheme.titleLarge)),
                      if (expenses.isNotEmpty) Text('${expenses.length}', style: theme.textTheme.labelLarge?.copyWith(color: AppColors.inkMuted)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (expenses.isEmpty)
                    FlatSurface(
                      padding: const EdgeInsets.all(28),
                      radius: 22,
                      child: Column(
                        children: [
                          const IconBadge(icon: Icons.receipt_long_rounded, color: AppColors.primary, size: 54, iconSize: 25),
                          const SizedBox(height: 14),
                          const Text('No transactions yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('Tap "Add expense" to log your first one.', style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  else
                    ...expenses.take(6).toList().asMap().entries.map(
                          (entry) => FadeSlideIn(
                            index: entry.key,
                            child: ExpenseCard(
                              expense: entry.value,
                              onDelete: entry.value.id == null
                                  ? () async {}
                                  : () async {
                                      await AppState.instance.deleteExpense(
                                        entry.value.id!,
                                      );
                                    },
                              onMarkAsPaid:
                                  entry.value.id == null ||
                                          entry.value.status !=
                                              ExpenseStatus.upcoming
                                      ? null
                                      : () async {
                                          await AppState.instance.markExpenseAsPaid(
                                            entry.value.id!,
                                          );
                                        },
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

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;
  const _HeroStat({required this.label, required this.value, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: alignEnd ? 16 : 0, right: alignEnd ? 0 : 16, top: 10),
      child: Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.76), fontSize: 11.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SmallMetric extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _SmallMetric({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return FlatSurface(
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 17),
      radius: 18,
      child: Row(
        children: [
          IconBadge(icon: icon, color: color, size: 36, iconSize: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkMuted)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onScan;
  const _ActionRow({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      borderRadius: BorderRadius.circular(18),
      onTap: onScan,
      child: FlatSurface(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            const IconBadge(icon: Icons.document_scanner_rounded, color: AppColors.gold, size: 38, iconSize: 18),
            const SizedBox(width: 12),
            const Expanded(child: Text('Scan a receipt', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5))),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}
