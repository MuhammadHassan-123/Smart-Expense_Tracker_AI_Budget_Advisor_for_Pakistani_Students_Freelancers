import 'package:flutter/material.dart';

import '../models/expense.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            "Rs\n${expense.amount.toInt()}",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10),
          ),
        ),
        title: Text(
          expense.title,
          style: const TextStyle(
              fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${expense.category}\n${expense.date.day}/${expense.date.month}/${expense.date.year}",
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete,
            color: Colors.red,
          ),
          onPressed: onDelete,
        ),
      ),
    );
  }
}