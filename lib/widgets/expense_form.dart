import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';

class ExpenseForm extends StatefulWidget {
  final Future<void> Function(Expense) onSave;
  final String initialCategory;

  const ExpenseForm({
    super.key,
    required this.onSave,
    this.initialCategory = 'Food',
  });

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final speechService = SpeechService();

  final categories = const [
    'Food',
    'Transport',
    'Housing',
    'Bills',
    'Education',
    'Health',
    'Shopping',
    'Entertainment',
    'Internet',
    'Medicine',
    'Personal',
    'Other',
  ];

  String category = 'Food';
  ExpenseType type = ExpenseType.variable;
  ExpenseStatus status = ExpenseStatus.paid;
  ExpenseRecurrence recurrence = ExpenseRecurrence.none;
  bool listening = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    category = widget.initialCategory;
  }

  Future<void> voiceInput() async {
    if (saving) return;
    setState(() => listening = true);
    try {
      final text = await speechService.listen();
      if (mounted && text.isNotEmpty) titleController.text = text;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Voice input failed: $e')));
      }
    } finally {
      if (mounted) setState(() => listening = false);
    }
  }

  Future<void> save() async {
    if (saving || !formKey.currentState!.validate()) return;
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() => saving = true);
    try {
      await widget.onSave(Expense(
        title: titleController.text.trim(),
        amount: amount,
        category: category,
        date: DateTime.now(),
        type: type,
        // A recurring fixed expense is an upcoming commitment until
        // the user explicitly marks that occurrence as paid.
        status: type == ExpenseType.fixed && recurrence != ExpenseRecurrence.none
            ? ExpenseStatus.upcoming
            : status,
        recurrence: type == ExpenseType.fixed ? recurrence : ExpenseRecurrence.none,
      ));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save expense: $e')));
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    speechService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 18, bottom: MediaQuery.viewInsetsOf(context).bottom + 22),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const IconBadge(icon: Icons.add_card_rounded, color: AppColors.primary, size: 40, iconSize: 19),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Add expense', style: theme.textTheme.headlineSmall)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ]),
                const SizedBox(height: 20),
                TextFormField(
                  controller: amountController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Amount', prefixText: 'Rs. ', prefixIcon: Icon(Icons.payments_outlined)),
                  validator: (value) => value == null || double.tryParse(value.trim()) == null || double.parse(value.trim()) <= 0 ? 'Enter a valid amount' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: titleController,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'What was it for?',
                    prefixIcon: const Icon(Icons.notes_outlined),
                    suffixIcon: listening
                        ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                        : IconButton(onPressed: voiceInput, icon: const Icon(Icons.mic_none_rounded)),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Enter a title' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
                  items: categories.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                  onChanged: saving ? null : (value) => setState(() => category = value ?? category),
                ),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: _ChoiceSegment<ExpenseType>(label: 'Variable', value: ExpenseType.variable, groupValue: type, onChanged: saving ? null : (v) => setState(() { type = v; if (v != ExpenseType.fixed) recurrence = ExpenseRecurrence.none; }))),
                  const SizedBox(width: 10),
                  Expanded(child: _ChoiceSegment<ExpenseType>(label: 'Fixed', value: ExpenseType.fixed, groupValue: type, onChanged: saving ? null : (v) => setState(() => type = v))),
                ]),
                if (type == ExpenseType.fixed) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<ExpenseRecurrence>(
                    initialValue: recurrence,
                    decoration: const InputDecoration(
                      labelText: 'Recurrence',
                      prefixIcon: Icon(Icons.repeat_rounded),
                    ),
                    items: ExpenseRecurrence.values
                        .map((item) => DropdownMenuItem<ExpenseRecurrence>(
                              value: item,
                              child: Text(item.label),
                            ))
                        .toList(),
                    onChanged: saving
                        ? null
                        : (value) => setState(() {
                              recurrence = value ?? ExpenseRecurrence.none;
                            }),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'For recurring fixed expenses, the app creates only the instance for the period that has arrived.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.inkMuted),
                  ),
                ],
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _ChoiceSegment<ExpenseStatus>(label: 'Paid', value: ExpenseStatus.paid, groupValue: status, onChanged: saving ? null : (v) => setState(() => status = v))),
                  const SizedBox(width: 10),
                  Expanded(child: _ChoiceSegment<ExpenseStatus>(label: 'Upcoming', value: ExpenseStatus.upcoming, groupValue: status, onChanged: saving ? null : (v) => setState(() => status = v))),
                ]),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving ? null : save,
                    child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(saving ? 'Saving...' : 'Save expense')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceSegment<T> extends StatelessWidget {
  final String label;
  final T value;
  final T groupValue;
  final ValueChanged<T>? onChanged;

  const _ChoiceSegment({required this.label, required this.value, required this.groupValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onChanged == null ? null : () => onChanged!(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primaryContainer : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : AppColors.line),
        ),
        child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? Theme.of(context).colorScheme.onPrimaryContainer : null))),
      ),
    );
  }
}
