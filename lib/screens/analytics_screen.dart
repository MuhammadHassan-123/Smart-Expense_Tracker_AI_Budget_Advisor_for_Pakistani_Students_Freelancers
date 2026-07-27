import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text("Monthly Spending"),
                subtitle: const Text("Rs. 0.00"),
              ),
            ),
            const SizedBox(height: 15),
            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.pie_chart),
                title: const Text("Top Category"),
                subtitle: const Text("No Data"),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Icon(
                  Icons.bar_chart,
                  size: 150,
                  color: Colors.teal.shade300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}