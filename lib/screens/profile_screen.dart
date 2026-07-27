import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: 10),
            Text(
              "Smart Expense Tracker",
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}