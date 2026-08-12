import 'package:flutter/material.dart';

import '../services/budget_service.dart';
import '../services/firestore_service.dart';
import 'budget_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final BudgetService budgetService = BudgetService();
  final FirestoreService expenseService = FirestoreService();

  double budget = 0;
  double totalExpenses = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final savedBudget = await budgetService.getBudget();
    final expenses = await expenseService.getExpenses().first;

    double total = 0;

    for (final expense in expenses) {
      total += expense.amount;
    }

    if (!mounted) return;

    setState(() {
      budget = savedBudget;
      totalExpenses = total;
      loading = false;
    });
  }

  Future<void> _clearExpenses() async {
    final expenses = await expenseService.getExpenses().first;

    for (final expense in expenses) {
      if (expense.id != null) {
        await expenseService.deleteExpense(expense.id!);
      }
    }

    await _loadProfileData();
  }

  Future<void> _confirmClearExpenses() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Clear All Expenses?"),
          content: const Text(
            "This will permanently delete all saved expenses. "
            "Your monthly budget will not be deleted.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text("Clear"),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _clearExpenses();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All expenses have been cleared."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 55,
                    child: Icon(
                      Icons.person,
                      size: 60,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "User",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Smart Expense Tracker",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Budget
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.account_balance_wallet,
                      ),
                      title: const Text("Monthly Budget"),
                      subtitle: Text(
                        "Rs. ${budget.toStringAsFixed(0)}",
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const BudgetScreen(),
                          ),
                        );

                        await _loadProfileData();
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Total Expenses
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.receipt_long,
                      ),
                      title: const Text("Total Expenses"),
                      subtitle: Text(
                        "Rs. ${totalExpenses.toStringAsFixed(0)}",
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Currency
                  const Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.currency_exchange,
                      ),
                      title: Text("Currency"),
                      subtitle: Text("Pakistani Rupee (PKR)"),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Clear expenses
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: totalExpenses == 0
                          ? null
                          : _confirmClearExpenses,
                      icon: const Icon(
                        Icons.delete_outline,
                      ),
                      label: const Text(
                        "Clear All Expenses",
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // About
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showAboutDialog(
                          context: context,
                          applicationName:
                              "Smart Expense Tracker",
                          applicationVersion: "1.0.0",
                          applicationIcon: const Icon(
                            Icons.account_balance_wallet,
                            size: 40,
                          ),
                          children: const [
                            Text(
                              "An AI-powered expense tracking "
                              "and budgeting application designed "
                              "to help students and freelancers "
                              "manage their personal finances.",
                            ),
                          ],
                        );
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text("About the App"),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Smart Expense Tracker • v1.0.0",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}