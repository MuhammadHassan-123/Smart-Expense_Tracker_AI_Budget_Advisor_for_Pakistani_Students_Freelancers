import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/firestore_service.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_card.dart';
import '../widgets/expense_form.dart';
import '../widgets/spending_chart.dart';
import '../widgets/summary_card.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final FirestoreService firestore = FirestoreService();

  void _showAddExpense(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ExpenseForm(
        onSave: (expense) async {
          await firestore.addExpense(expense);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpense(context),
        icon: const Icon(Icons.add),
        label: const Text("Add Expense"),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Expense>>(
          stream: firestore.getExpenses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final expenses = snapshot.data ?? [];

            double total = 0;

            for (var e in expenses) {
              total += e.amount;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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

                  SummaryCard(totalExpense: total),

                  const SizedBox(height: 20),

                  Row(
                    children: [

                      DashboardCard(
                        title: "Expenses",
                        value: expenses.length.toString(),
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                      ),

                      const SizedBox(width: 12),

                      DashboardCard(
                        title: "Categories",
                        value: expenses
                            .map((e) => e.category)
                            .toSet()
                            .length
                            .toString(),
                        icon: Icons.category,
                        color: Colors.orange,
                      ),
                    ],
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

                  const SpendingChart(),

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
                          itemBuilder: (context, index) {
                            final expense = expenses[index];

                            return ExpenseCard(
                              expense: expense,
                              onDelete: () async {
                                await firestore.deleteExpense(
                                  expense.id!,
                                );
                              },
                            );
                          },
                        ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}