import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/budget_service.dart';
import '../services/firestore_service.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_card.dart';
import '../widgets/expense_form.dart';
import '../widgets/spending_chart.dart';
import '../widgets/summary_card.dart';
import 'receipt_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService firestore = FirestoreService();
  final BudgetService budgetService = BudgetService();

  List<Expense> expenses = [];
  double budget = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final savedExpenses =
        await firestore.getExpenses().first;

    final savedBudget =
        await budgetService.getBudget();

    if (!mounted) return;

    setState(() {
      expenses = savedExpenses;
      budget = savedBudget;
      loading = false;
    });
  }

  void _showAddExpense(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ExpenseForm(
        onSave: (expense) async {
          await firestore.addExpense(expense);
          await _loadData();
        },
      ),
    );
  }

  Future<void> _deleteExpense(String id) async {
    await firestore.deleteExpense(id);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    double total = 0;

    for (final expense in expenses) {
      total += expense.amount;
    }

    final double remaining = budget - total;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpense(context),
        icon: const Icon(Icons.add),
        label: const Text("Add Expense"),
      ),
      body: SafeArea(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Welcome",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      "Track your daily expenses intelligently",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 25),

                    // -------------------------
                    // Budget Summary
                    // -------------------------

                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Monthly Budget",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 15),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                _BudgetItem(
                                  title: "Budget",
                                  amount: budget,
                                ),
                                _BudgetItem(
                                  title: "Spent",
                                  amount: total,
                                ),
                                _BudgetItem(
                                  title: "Remaining",
                                  amount: remaining,
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            if (budget > 0)
                              LinearProgressIndicator(
                                value: (total / budget)
                                    .clamp(0.0, 1.0),
                                minHeight: 8,
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),

                            const SizedBox(height: 8),

                            if (budget <= 0)
                              const Text(
                                "Set a monthly budget to track your remaining amount.",
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              )
                            else if (remaining < 0)
                              Text(
                                "You have exceeded your budget by Rs. ${remaining.abs().toStringAsFixed(0)}.",
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            else
                              Text(
                                "Rs. ${remaining.toStringAsFixed(0)} remaining this month.",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // -------------------------
                    // Existing Summary
                    // -------------------------

                    SummaryCard(
                      totalExpense: total,
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            title: "Expenses",
                            value: expenses.length.toString(),
                            icon: Icons.receipt_long,
                            color: Colors.blue,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: DashboardCard(
                            title: "Categories",
                            value: expenses
                                .map((e) => e.category)
                                .toSet()
                                .length
                                .toString(),
                            icon: Icons.category,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // -------------------------
                    // Receipt Scanner
                    // -------------------------

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.document_scanner,
                        ),
                        label: const Text(
                          "Scan Receipt",
                        ),
                        onPressed: () async {
                          final Expense? scannedExpense =
                              await Navigator.push<Expense>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ReceiptScannerScreen(),
                            ),
                          );

                          if (scannedExpense != null) {
                            await firestore.addExpense(
                              scannedExpense,
                            );

                            await _loadData();
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      "Expense Distribution",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),

                    const SizedBox(height: 15),

                    SpendingChart(
                      expenses: expenses,
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      "Recent Expenses",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),

                    const SizedBox(height: 10),

                    expenses.isEmpty
                        ? const EmptyState()
                        : ListView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            itemCount: expenses.length,
                            itemBuilder:
                                (context, index) {
                              final expense =
                                  expenses[index];

                              return ExpenseCard(
                                expense: expense,
                                onDelete: () async {
                                  if (expense.id != null) {
                                    await _deleteExpense(
                                      expense.id!,
                                    );
                                  }
                                },
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

// --------------------------------------------------
// Budget Item Widget
// --------------------------------------------------

class _BudgetItem extends StatelessWidget {
  final String title;
  final double amount;

  const _BudgetItem({
    required this.title,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "Rs. ${amount.toStringAsFixed(0)}",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}