import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/firestore_service.dart';
import '../widgets/spending_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final FirestoreService expenseService = FirestoreService();

  List<Expense> expenses = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final savedExpenses = await expenseService.getExpenses().first;

    if (!mounted) return;

    setState(() {
      expenses = savedExpenses;
      loading = false;
    });
  }

  double get totalSpending {
    double total = 0;

    for (final expense in expenses) {
      total += expense.amount;
    }

    return total;
  }

  Map<String, double> get categoryTotals {
    final Map<String, double> totals = {};

    for (final expense in expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }

    return totals;
  }

  String get topCategory {
    if (categoryTotals.isEmpty) {
      return "No Data";
    }

    String category = categoryTotals.keys.first;
    double highestAmount = categoryTotals[category]!;

    categoryTotals.forEach((key, value) {
      if (value > highestAmount) {
        category = key;
        highestAmount = value;
      }
    });

    return category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Spending Overview",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Total Spending",
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Rs. ${totalSpending.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Card(
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.receipt_long,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Expenses",
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    expenses.length.toString(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    Card(
                      elevation: 3,
                      child: ListTile(
                        leading: const Icon(Icons.pie_chart),
                        title: const Text("Top Spending Category"),
                        subtitle: Text(
                          topCategory == "No Data"
                              ? "No expenses recorded"
                              : "$topCategory - Rs. ${categoryTotals[topCategory]!.toStringAsFixed(0)}",
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      "Category Distribution",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: expenses.isEmpty
                            ? const SizedBox(
                                height: 220,
                                child: Center(
                                  child: Text(
                                    "No expenses available for analysis.",
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            : SpendingChart(
                                expenses: expenses,
                              ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      "Category Details",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (categoryTotals.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            "Add expenses to see category details.",
                          ),
                        ),
                      )
                    else
                      ...categoryTotals.entries.map(
                        (entry) {
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.category),
                              title: Text(entry.key),
                              trailing: Text(
                                "Rs. ${entry.value.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}