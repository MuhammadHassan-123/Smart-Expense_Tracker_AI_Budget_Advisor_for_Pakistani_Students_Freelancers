import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final double totalExpense;

  const SummaryCard({
    super.key,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.teal,
            Colors.green,
          ],
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Expenses",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Rs. ${totalExpense.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
          ),
        ],
      ),
    );
  }
}