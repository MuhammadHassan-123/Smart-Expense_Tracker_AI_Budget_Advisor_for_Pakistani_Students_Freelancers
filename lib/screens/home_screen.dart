import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../widgets/expense_card.dart';
import '../widgets/expense_form.dart';
import '../widgets/empty_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Expense> _expenses = [];

  void _addExpense(Expense expense) {
    setState(() {
      _expenses.add(expense);
    });
  }

  void _deleteExpense(int index) {
    setState(() {
      _expenses.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Expense deleted'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Expense Tracker"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// Expense Form
            ExpenseForm(
              onAddExpense: _addExpense,
            ),

            const SizedBox(height: 20),

            /// Expense List Heading
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recent Expenses",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),

            const SizedBox(height: 10),

            /// Expense List
            Expanded(
              child: _expenses.isEmpty
                  ? const EmptyState()
                  : ListView.builder(
                      itemCount: _expenses.length,
                      itemBuilder: (context, index) {
                        return ExpenseCard(
                          expense: _expenses[index],
                          onDelete: () => _deleteExpense(index),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}