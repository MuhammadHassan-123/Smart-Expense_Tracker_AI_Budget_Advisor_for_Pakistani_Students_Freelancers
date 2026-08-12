import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/speech_service.dart';

class ExpenseForm extends StatefulWidget {
  final Future<void> Function(Expense) onSave;

  const ExpenseForm({
    super.key,
    required this.onSave,
  });

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _title = TextEditingController();
  final TextEditingController _amount = TextEditingController();

  final SpeechService speechService = SpeechService();

  bool _isListening = false;
  bool _isSaving = false;

  String category = "Food";

  final List<String> categories = [
    "Food",
    "Transport",
    "Shopping",
    "Bills",
    "Entertainment",
    "Education",
    "Health",
    "Hostel",
    "Internet",
    "Medicine",
    "Other",
  ];

  Future<void> _voiceInput() async {
    if (_isSaving) return;

    setState(() {
      _isListening = true;
    });

    try {
      final text = await speechService.listen();

      if (text.isNotEmpty && mounted) {
        _title.text = text;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Voice input failed: $e"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  Future<void> saveExpense() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amount.text.trim());

    if (amount == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final expense = Expense(
      title: _title.text.trim(),
      amount: amount,
      category: category,
      date: DateTime.now(),
    );

    try {
      await widget.onSave(expense);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not save expense: $e"),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance_wallet,
                size: 60,
                color: Colors.teal,
              ),

              const SizedBox(height: 10),

              const Text(
                "Add New Expense",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              TextFormField(
                controller: _title,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  labelText: "Expense Title",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.edit),
                  suffixIcon: _isListening
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.mic),
                          onPressed: _voiceInput,
                        ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter expense title";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: _amount,
                enabled: !_isSaving,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "Amount (PKR)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Enter amount";
                  }

                  if (double.tryParse(value.trim()) == null) {
                    return "Enter a valid amount";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: categories.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            category = value;
                          });
                        }
                      },
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : saveExpense,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSaving ? "Saving..." : "Save Expense",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}