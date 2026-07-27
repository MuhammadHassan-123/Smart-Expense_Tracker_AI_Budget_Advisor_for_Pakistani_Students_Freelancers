import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.wallet,
            size: 90,
            color: Colors.grey,
          ),
          SizedBox(height: 15),
          Text(
            "No Expenses Yet",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Tap Add Expense to start tracking.",
          )
        ],
      ),
    );
  }
}