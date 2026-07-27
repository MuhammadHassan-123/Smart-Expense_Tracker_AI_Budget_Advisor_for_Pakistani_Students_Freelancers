import 'package:flutter/material.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Budget Advisor"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: const [
                    Icon(
                      Icons.auto_awesome,
                      size: 80,
                      color: Colors.teal,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "AI Budget Suggestions",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      "• Reduce unnecessary food expenses.\n\n"
                      "• Track transport spending.\n\n"
                      "• Save at least 20% of your monthly income.",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}