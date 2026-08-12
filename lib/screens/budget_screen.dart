import 'package:flutter/material.dart';
import '../services/budget_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final BudgetService budgetService = BudgetService();
  final TextEditingController budgetController =
      TextEditingController();

  bool loading = false;

  Future<void> saveBudget() async {
    if (budgetController.text.isEmpty) return;

    setState(() {
      loading = true;
    });

    await budgetService.saveBudget(
      double.parse(budgetController.text),
    );

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Budget saved successfully."),
      ),
    );
  }

  Future<void> loadBudget() async {
    final budget = await budgetService.getBudget();

    if (!mounted) return;

    if (budget != 0) {
      budgetController.text = budget.toStringAsFixed(0);
    }
  }

  @override
  void initState() {
    super.initState();
    loadBudget();
  }

  @override
  void dispose() {
    budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monthly Budget"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Monthly Budget (Rs.)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : saveBudget,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Save Budget"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}