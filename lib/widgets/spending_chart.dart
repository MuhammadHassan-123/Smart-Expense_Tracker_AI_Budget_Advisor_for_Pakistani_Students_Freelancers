import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SpendingChart extends StatelessWidget {
  const SpendingChart({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: 40,
              title: "Food",
              radius: 60,
            ),
            PieChartSectionData(
              value: 25,
              title: "Transport",
              radius: 60,
            ),
            PieChartSectionData(
              value: 20,
              title: "Shopping",
              radius: 60,
            ),
            PieChartSectionData(
              value: 15,
              title: "Other",
              radius: 60,
            ),
          ],
        ),
      ),
    );
  }
}