import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/expense.dart';

class SpendingChart extends StatelessWidget {
  final List<Expense> expenses;

  const SpendingChart({
    super.key,
    required this.expenses,
  });

  Map<String, double> _getCategoryTotals() {
    final Map<String, double> totals = {};

    for (final expense in expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }

    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final categoryTotals = _getCategoryTotals();

    if (categoryTotals.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text("No spending data available"),
        ),
      );
    }

    final entries = categoryTotals.entries.toList();

    return SizedBox(
      height: 260,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 35,
          sections: List.generate(
            entries.length,
            (index) {
              final entry = entries[index];

              return PieChartSectionData(
                value: entry.value,
                title: entry.key,
                radius: 70,
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}