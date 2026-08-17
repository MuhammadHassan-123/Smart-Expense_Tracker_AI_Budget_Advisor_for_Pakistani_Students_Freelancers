import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../theme/app_theme.dart';

class SpendingChart extends StatelessWidget {
  final List<Expense> expenses;

  const SpendingChart({super.key, required this.expenses});

  Map<String, double> _totals() {
    final totals = <String, double>{};
    for (final expense in expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    return SpendingDistributionChart(
      values: _totals(),
      centerLabel: 'Spent',
      showLegend: true,
    );
  }
}

class SpendingDistributionChart extends StatelessWidget {
  final Map<String, double> values;
  final String emptyText;
  final String? centerLabel;
  final bool showLegend;
  final bool sortByValue;

  const SpendingDistributionChart({
    super.key,
    required this.values,
    this.emptyText = 'No data available.',
    this.centerLabel,
    this.showLegend = true,
    this.sortByValue = true,
  });

  static const chartColors = <Color>[
    Color(0xFF4C5CF2),
    Color(0xFF17B071),
    Color(0xFFF2A93B),
    Color(0xFF7C5CFC),
    Color(0xFF3AA9E0),
    Color(0xFFE85C9C),
    Color(0xFFF2564B),
    Color(0xFF8B5CF6),
    Color(0xFF0E8F5B),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = values.entries
        .where((entry) => entry.value > 0)
        .toList();
    if (sortByValue) {
      entries.sort((a, b) => b.value.compareTo(a.value));
    }

    if (entries.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(child: Text(emptyText)),
      );
    }

    final total = entries.fold<double>(0, (sum, entry) => sum + entry.value);
    Color colorFor(int index) => AppColors.categoryColors[entries[index].key] ?? chartColors[index % chartColors.length];

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 56,
                  sections: List.generate(
                    entries.length,
                    (index) {
                      final percentage = entries[index].value / total * 100;
                      return PieChartSectionData(
                        value: entries[index].value,
                        color: colorFor(index),
                        title: percentage >= 8
                            ? '${percentage.toStringAsFixed(0)}%'
                            : '',
                        radius: 80,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (centerLabel != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      centerLabel!,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rs. ${total.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (showLegend) ...[
          const SizedBox(height: 36),
          Container(
            height: 1,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: .35),
          ),
          const SizedBox(height: 20),
          Column(
            children: List.generate(
              entries.length,
              (index) {
                final entry = entries[index];
                final percentage = entry.value / total * 100;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colorFor(index),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Rs. ${entry.value.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
