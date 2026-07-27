import 'package:flutter/material.dart';

class AIAdvisorScreen extends StatelessWidget {
  const AIAdvisorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "AI Budget Advisor\nComing Soon",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}