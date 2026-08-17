import 'package:flutter/material.dart';

import '../models/budget.dart';
import '../services/budget_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final BudgetService _periodMath = BudgetService();

  final TextEditingController amountController =
      TextEditingController();

  final List<TextEditingController> monthControllers =
      List<TextEditingController>.generate(
    12,
    (_) => TextEditingController(),
  );

  late BudgetPeriod period;
  late DateTime startDate;
  late bool carryForward;

  bool saving = false;

  @override
  void initState() {
    super.initState();

    final currentPlan = AppState.instance.plan;

    period = currentPlan.period;
    startDate = currentPlan.startDate;
    carryForward = currentPlan.carryForward;

    amountController.text = currentPlan.amount > 0.0
        ? currentPlan.amount.toStringAsFixed(0)
        : '';

    final allocations = _initialAllocations(currentPlan);

    for (int i = 0; i < 12; i++) {
      monthControllers[i].text =
          allocations[i].toStringAsFixed(0);
    }
  }

  List<double> _initialAllocations(BudgetPlan plan) {
    if (plan.period == BudgetPeriod.yearly) {
      if (plan.monthlyAllocations.length == 12) {
        final double total =
            plan.monthlyAllocations.fold<double>(
          0.0,
          (double sum, double value) => sum + value,
        );

        if (total > 0.0) {
          return List<double>.from(
            plan.monthlyAllocations,
          );
        }
      }
    }

    final double total = plan.amount;

    final double each =
        total > 0.0 ? total / 12.0 : 0.0;

    return List<double>.filled(
      12,
      each,
    );
  }

  void _switchPeriod(BudgetPeriod value) {
    setState(() {
      period = value;

      // Whenever Yearly is selected, start with an
      // equal distribution across all 12 months.
      if (value == BudgetPeriod.yearly) {
        final double amount =
            double.tryParse(
                  amountController.text.trim(),
                ) ??
                0.0;

        final double each =
            amount > 0.0 ? amount / 12.0 : 0.0;

        for (int i = 0; i < 12; i++) {
          monthControllers[i].text =
              each.toStringAsFixed(2);
        }
      }
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText:
          'Choose your financial cycle start date',
    );

    if (!mounted || selected == null) return;

    setState(() {
      startDate = selected;
    });
  }

  List<double> _readAllocations() {
    return monthControllers
        .map<double>(
          (controller) =>
              double.tryParse(
                controller.text.trim(),
              ) ??
              0.0,
        )
        .toList();
  }

  double _allocationTotal(
    List<double> allocations,
  ) {
    return allocations.fold<double>(
      0.0,
      (double sum, double value) => sum + value,
    );
  }

  Future<void> _save() async {
    final double? parsedAmount =
        double.tryParse(
      amountController.text.trim(),
    );

    if (parsedAmount == null ||
        !parsedAmount.isFinite ||
        parsedAmount <= 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid budget amount.',
          ),
        ),
      );
      return;
    }

    final double amount = parsedAmount;

    final List<double> allocations;

    if (period == BudgetPeriod.yearly) {
      allocations = _readAllocations();

      final double total =
          _allocationTotal(allocations);

      if ((total - amount).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Monthly allocations total '
              'Rs. ${total.toStringAsFixed(0)}. '
              'They must equal '
              'Rs. ${amount.toStringAsFixed(0)}.',
            ),
          ),
        );
        return;
      }
    } else {
      allocations = List<double>.filled(
        12,
        amount / 12.0,
      );
    }

    setState(() {
      saving = true;
    });

    try {
      final newPlan = BudgetPlan(
        amount: amount,
        period: period,
        startDate: startDate,
        monthlyAllocations: allocations,
        carryForward: carryForward,
      );

      await AppState.instance.saveBudgetPlan(
        newPlan,
      );

      if (!mounted) return;

      setState(() {
        saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            period == BudgetPeriod.yearly
                ? 'Yearly budget plan saved successfully.'
                : 'Monthly budget plan saved successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save the budget plan: $e',
          ),
        ),
      );
    }
  }

  String _date(DateTime value) {
    return '${value.day} '
        '${_month(value.month)} '
        '${value.year}';
  }

  String _month(int month) {
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }

  @override
  void dispose() {
    amountController.dispose();

    for (final controller in monthControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final double amount =
        double.tryParse(
          amountController.text.trim(),
        ) ??
        0.0;

    final List<double> previewAllocations =
        period == BudgetPeriod.yearly
            ? _readAllocations()
            : List<double>.filled(
                12,
                amount / 12.0,
              );

    final previewPlan = BudgetPlan(
      amount: amount,
      period: period,
      startDate: startDate,
      monthlyAllocations: previewAllocations,
      carryForward: carryForward,
    );

    final current = _periodMath.currentPeriod(
      previewPlan,
    );

    final yearlyPeriods =
        _periodMath.yearlyPeriods(
      previewPlan,
      cycleStart: current.start,
    );

    final double allocationTotal =
        period == BudgetPeriod.yearly
            ? _allocationTotal(
                previewAllocations,
              )
            : amount;

    final bool allocationsValid =
        period == BudgetPeriod.monthly ||
        (allocationTotal - amount).abs() <= 0.01;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Budget plan'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            6,
            20,
            34,
          ),
          children: [
            Text(
              'Plan your money',
              style: theme.textTheme.headlineMedium,
            ),

            const SizedBox(height: 6),

            Text(
              'Choose your own financial cycle. '
              'It does not have to start on the 1st.',
              style:
                  theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            SegmentedButton<BudgetPeriod>(
              segments: const [
                ButtonSegment<BudgetPeriod>(
                  value: BudgetPeriod.monthly,
                  label: Text('Monthly'),
                ),
                ButtonSegment<BudgetPeriod>(
                  value: BudgetPeriod.yearly,
                  label: Text('Yearly'),
                ),
              ],
              selected: <BudgetPeriod>{period},
              onSelectionChanged: saving
                  ? null
                  : (Set<BudgetPeriod> values) {
                      _switchPeriod(
                        values.first,
                      );
                    },
            ),

            const SizedBox(height: 22),

            TextField(
              controller: amountController,
              enabled: !saving,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                setState(() {});

                if (period == BudgetPeriod.yearly) {
                  final double value =
                      double.tryParse(
                            amountController.text.trim(),
                          ) ??
                          0.0;

                  final double each =
                      value > 0.0
                          ? value / 12.0
                          : 0.0;

                  final List<double> currentValues =
                      _readAllocations();

                  final bool allEqual =
                      currentValues.isEmpty ||
                          currentValues.every(
                            (double item) =>
                                (item -
                                            currentValues
                                                .first)
                                        .abs() <
                                    0.01,
                          );

                  if (allEqual) {
                    for (int i = 0; i < 12; i++) {
                      monthControllers[i].text =
                          each.toStringAsFixed(2);
                    }
                  }
                }
              },
              decoration: const InputDecoration(
                labelText: 'Budget amount',
                prefixText: 'Rs. ',
                prefixIcon: Icon(
                  Icons
                      .account_balance_wallet_outlined,
                ),
              ),
            ),

            const SizedBox(height: 14),

            FlatSurface(
              padding: EdgeInsets.zero,
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: const IconBadge(
                  icon: Icons.event_rounded,
                  color: AppColors.clay,
                ),
                title: const Text(
                  'Cycle starts',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  _date(startDate),
                ),
                trailing: TextButton(
                  onPressed:
                      saving ? null : _pickDate,
                  child: const Text(
                    'Change',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            FlatSurface(
              padding: const EdgeInsets.all(16),
              color: AppColors.primaryContainer,
              child: Row(
                children: [
                  const IconBadge(
                    icon: Icons.schedule_rounded,
                    color: AppColors.primaryDeep,
                    size: 40,
                    iconSize: 19,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '${_date(current.start)} – '
                      '${_date(current.end)}\n'
                      '${current.daysRemaining} days remaining',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        color:
                            AppColors.primaryDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (period == BudgetPeriod.yearly) ...[
              const SizedBox(height: 26),

              Text(
                '12-month plan',
                style:
                    theme.textTheme.titleLarge,
              ),

              const SizedBox(height: 6),

              const Text(
                'Your annual amount starts equally divided '
                'across all 12 months. You can adjust '
                'individual months later.',
                style: TextStyle(
                  color: AppColors.inkMuted,
                ),
              ),

              const SizedBox(height: 14),

              ...List.generate(
                12,
                (int index) {
                  final p =
                      yearlyPeriods[index];

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 92,
                          child: Text(
                            '${_month(p.start.month)} '
                            '${p.start.year}',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller:
                                monthControllers[
                                    index],
                            enabled: !saving,
                            keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) {
                              setState(() {});
                            },
                            decoration:
                                const InputDecoration(
                              prefixText:
                                  'Rs. ',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              FlatSurface(
                padding:
                    const EdgeInsets.all(14),
                color: allocationsValid
                    ? AppColors
                        .primaryContainer
                    : const Color(
                        0xFFF7E9E3,
                      ),
                child: Row(
                  children: [
                    Icon(
                      allocationsValid
                          ? Icons
                              .check_circle_outline
                          : Icons
                              .warning_amber_rounded,
                      color: allocationsValid
                          ? AppColors
                              .primary
                          : AppColors
                              .danger,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '12-month total: '
                        'Rs. ${allocationTotal.toStringAsFixed(0)} '
                        'of Rs. ${amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w700,
                          color: allocationsValid
                              ? AppColors
                                  .primaryDeep
                              : AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              SwitchListTile.adaptive(
                contentPadding:
                    EdgeInsets.zero,
                value: carryForward,
                onChanged: saving
                    ? null
                    : (bool value) {
                        setState(() {
                          carryForward = value;
                        });
                      },
                title: const Text(
                  'Carry unused balance forward',
                ),
                subtitle: const Text(
                  'Move an unused month balance '
                  'into the next month.',
                ),
              ),
            ],

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    saving || !allocationsValid
                        ? null
                        : _save,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 4,
                  ),
                  child: Text(
                    saving
                        ? 'Saving...'
                        : 'Save plan',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}