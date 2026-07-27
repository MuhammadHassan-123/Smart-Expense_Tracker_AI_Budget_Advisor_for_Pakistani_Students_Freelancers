import 'package:flutter/material.dart';
import '../models/expense.dart';

class ExpenseForm extends StatefulWidget {
  final Function(Expense) onSave;

  const ExpenseForm({
    super.key,
    required this.onSave,
  });

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {

  final _title = TextEditingController();
  final _amount = TextEditingController();

  String category = "Food";

  final categories = [
    "Food",
    "Transport",
    "Shopping",
    "Bills",
    "Entertainment",
    "Education",
    "Health",
    "Other"
  ];

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  void saveExpense() {

    if(_title.text.isEmpty || _amount.text.isEmpty){
      return;
    }

    widget.onSave(
      Expense(
        title: _title.text.trim(),
        amount: double.parse(_amount.text),
        category: category,
        date: DateTime.now(),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom+20,
      ),

      child: SingleChildScrollView(

        child: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            const Text(
              "Add Expense",
              style: TextStyle(
                  fontSize:24,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height:20),

            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height:15),

            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height:15),

            DropdownButtonFormField(

              value: category,

              items: categories.map((e){

                return DropdownMenuItem(
                  value:e,
                  child: Text(e),
                );

              }).toList(),

              onChanged:(value){

                setState(() {

                  category=value!;

                });

              },

            ),

            const SizedBox(height:20),

            SizedBox(

              width:double.infinity,

              child: ElevatedButton(

                onPressed: saveExpense,

                child: const Text("Save"),

              ),

            )

          ],

        ),

      ),

    );

  }

}