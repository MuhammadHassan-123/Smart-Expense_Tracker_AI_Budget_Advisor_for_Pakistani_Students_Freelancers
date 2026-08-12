import 'package:flutter/material.dart';

import '../services/ai_service.dart';
import '../services/budget_service.dart';
import '../services/firestore_service.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final AIService ai = AIService();
  final BudgetService budgetService = BudgetService();
  final FirestoreService expenseService = FirestoreService();

  String advice = "";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _getPersonalizedAdvice();
  }

  Future<void> _getPersonalizedAdvice() async {
    setState(() {
      loading = true;
      advice = "";
    });

    try {
      // Get the saved monthly budget
      final double budget = await budgetService.getBudget();

      // Get all saved expenses
      final expenses = await expenseService.getExpenses().first;

      // Send the real budget and expenses to Gemini
      double totalExpense = 0;

for (final expense in expenses) {
  totalExpense += expense.amount;
}

final result = await ai.getAdvice(
  budget: budget,
  totalExpense: totalExpense,
  expenses: expenses,
);

      if (!mounted) return;

      setState(() {
        advice = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        advice = "Unable to generate advice right now.\n\nError: $e";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Budget Advisor"),
        centerTitle: true,
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Personalized Budget Advice",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Based on your current budget and expenses",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 25),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        advice,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _getPersonalizedAdvice,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Refresh Advice"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}