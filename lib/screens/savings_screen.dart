import 'package:flutter/material.dart';

import '../models/budget.dart';
import '../models/expense.dart';
import '../models/savings_contribution.dart';
import '../models/savings_goal.dart';
import '../services/savings_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final SavingsService _savingsService = SavingsService();

  List<SavingsGoal> _goals = <SavingsGoal>[];
  List<SavingsContribution> _contributions =
      <SavingsContribution>[];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final goals =
          await _savingsService.getGoals();

      final contributions =
          await _savingsService.getContributions();

      if (!mounted) return;

      setState(() {
        _goals = List<SavingsGoal>.from(goals);
        _contributions =
            List<SavingsContribution>.from(
          contributions,
        );
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error =
            'Unable to load savings goals.';
      });
    }
  }

  Future<void> _createGoal() async {
    final nameController =
        TextEditingController();

    final amountController =
        TextEditingController();

    DateTime targetDate =
        DateTime.now().add(
      const Duration(days: 180),
    );

    try {
      final result =
          await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor:
            AppColors.canvas,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder:
                (sheetContext, setSheetState) {
              final width =
                  MediaQuery.sizeOf(
                sheetContext,
              ).width;

              return SafeArea(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(
                    maxWidth: width,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        16,
                        20,
                        MediaQuery.viewInsetsOf(
                              sheetContext,
                            ).bottom +
                            24,
                      ),
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'Create a savings goal',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          TextField(
                            controller:
                                nameController,
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Goal name',
                              hintText:
                                  'Laptop, emergency fund, fee',
                            ),
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          TextField(
                            controller:
                                amountController,
                            keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                              decimal: true,
                            ),
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Target amount',
                              prefixText:
                                  'Rs. ',
                            ),
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          ListTile(
                            contentPadding:
                                EdgeInsets.zero,
                            leading:
                                const Icon(
                              Icons
                                  .calendar_today_outlined,
                            ),
                            title:
                                const Text(
                              'Target date',
                            ),
                            subtitle:
                                Text(
                              _formatDate(
                                targetDate,
                              ),
                            ),
                            onTap: () async {
                              final picked =
                                  await showDatePicker(
                                context:
                                    sheetContext,
                                initialDate:
                                    targetDate,
                                firstDate:
                                    DateTime.now(),
                                lastDate:
                                    DateTime(2100),
                              );

                              if (picked !=
                                  null) {
                                setSheetState(
                                  () {
                                    targetDate =
                                        picked;
                                  },
                                );
                              }
                            },
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          SizedBox(
                            width: width - 40,
                            child:
                                FilledButton(
                              onPressed: () {
                                final name =
                                    nameController
                                        .text
                                        .trim();

                                final amount =
                                    double.tryParse(
                                  amountController
                                      .text
                                      .trim(),
                                );

                                if (name
                                        .isEmpty ||
                                    amount ==
                                        null ||
                                    !amount
                                        .isFinite ||
                                    amount <= 0) {
                                  ScaffoldMessenger
                                          .of(
                                    sheetContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text(
                                        'Enter a valid goal and amount.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                Navigator.of(
                                  sheetContext,
                                ).pop(true);
                              },
                              child:
                                  const Text(
                                'Create goal',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      if (!mounted ||
          result != true) {
        return;
      }

      final name =
          nameController.text.trim();

      final amount =
          double.tryParse(
        amountController.text.trim(),
      );

      if (name.isEmpty ||
          amount == null ||
          !amount.isFinite ||
          amount <= 0) {
        return;
      }

      final goal = SavingsGoal(
        id: DateTime.now()
            .microsecondsSinceEpoch
            .toString(),
        name: name,
        targetAmount: amount,
        savedAmount: 0,
        targetDate: targetDate,
      );

      await _savingsService.addGoal(
        goal,
      );

      await _loadGoals();

      await AppState.instance.refresh();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '$name created.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Could not create the goal.',
          ),
        ),
      );
    } finally {
      nameController.dispose();
      amountController.dispose();
    }
  }

  Future<void> _addSavings(
    SavingsGoal goal,
  ) async {
    try {
      final available =
          _calculateAvailable();

      if (!mounted) return;

      final amount =
          await showModalBottomSheet<double>(
        context: context,
        isScrollControlled: true,
        backgroundColor:
            AppColors.canvas,
        builder: (sheetContext) {
          return _SavingsAmountSheet(
            goal: goal,
            available: available,
          );
        },
      );

      if (!mounted ||
          amount == null) {
        return;
      }

      if (amount <= 0) return;

      if (amount > goal.remaining) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Only ${_money(goal.remaining)} '
              'is needed for this goal.',
            ),
          ),
        );
        return;
      }

      if (available <= 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'There is no available budget for savings this cycle.',
            ),
          ),
        );
        return;
      }

      if (amount > available) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Only ${_money(available)} '
              'is available this cycle.',
            ),
          ),
        );
        return;
      }

      await AppState.instance
          .addContribution(
        goal,
        amount,
      );

      await _loadGoals();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${_money(amount)} added to ${goal.name}.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Could not add the savings contribution.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteGoal(
    SavingsGoal goal,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete savings goal?',
          ),
          content: Text(
            'Delete ${goal.name} and its saved contributions?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted ||
        confirmed != true) {
      return;
    }

    try {
      await AppState.instance.deleteGoal(
        goal.id,
      );

      await _loadGoals();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${goal.name} deleted.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Could not delete the goal.',
          ),
        ),
      );
    }
  }

  double _calculateAvailable() {
    final state =
        AppState.instance;

    final plan =
        state.plan;

    final period =
        state.currentPeriod;

    double budget;

    if (plan.period ==
        BudgetPeriod.monthly) {
      budget = plan.amount;
    } else {
      final allocations =
          plan.normalizedAllocations;

      if (allocations.isEmpty) {
        budget =
            plan.amount / 12;
      } else {
        final anchor =
            DateTime(
          plan.startDate.year,
          plan.startDate.month,
          1,
        );

        final current =
            DateTime(
          period.start.year,
          period.start.month,
          1,
        );

        final index =
            ((current.year -
                        anchor.year) *
                    12 +
                current.month -
                anchor.month)
            .clamp(
              0,
              allocations.length - 1,
            );

        budget =
            allocations[index];
      }
    }

    final expenses =
        state.periodExpenses(
      period,
    );

    double paid = 0;
    double upcoming = 0;

    for (final expense in expenses) {
      if (expense.status ==
          ExpenseStatus.paid) {
        paid += expense.amount;
      }

      if (expense.status ==
          ExpenseStatus.upcoming) {
        upcoming += expense.amount;
      }
    }

    double saved = 0;

    for (final contribution
        in _contributions) {
      if (!contribution.date
              .isBefore(
            period.start,
          ) &&
          !contribution.date
              .isAfter(
            period.end,
          )) {
        saved +=
            contribution.amount;
      }
    }

    final available =
        budget -
        paid -
        upcoming -
        saved;

    return available > 0
        ? available
        : 0;
  }

  String _money(double value) {
    return 'Rs. ${value.toStringAsFixed(0)}';
  }

  String _formatDate(
    DateTime date,
  ) {
    const months = [
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

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_loading) {
      return Scaffold(
        backgroundColor:
            AppColors.canvas,
        appBar: AppBar(
          title:
              const Text('Savings'),
        ),
        body:
            const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor:
            AppColors.canvas,
        appBar: AppBar(
          title:
              const Text('Savings'),
        ),
        body: Center(
          child: Text(
            _error!,
          ),
        ),
      );
    }

    double totalSaved = 0;
    double totalRemaining = 0;

    for (final goal in _goals) {
      totalSaved +=
          goal.savedAmount;

      totalRemaining +=
          goal.remaining;
    }

    return Scaffold(
      backgroundColor:
          AppColors.canvas,
      appBar: AppBar(
        title:
            const Text('Savings'),
        actions: [
          IconButton(
            tooltip:
                'Create goal',
            onPressed:
                _createGoal,
            icon:
                const Icon(
              Icons.add_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child:
            RefreshIndicator(
          onRefresh:
              _loadGoals,
          color:
              AppColors.primary,
          child:
              LayoutBuilder(
            builder:
                (context, constraints) {
              return ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  18,
                  18,
                  40,
                ),
                children: [
                  const Text(
                    'Savings goals',
                    style:
                        TextStyle(
                      fontSize: 26,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          AppColors.ink,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  const Text(
                    'Keep track of what you are saving for.',
                    style:
                        TextStyle(
                      color:
                          AppColors.inkMuted,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  _InfoCard(
                    label: 'Total saved',
                    value:
                        _money(
                      totalSaved,
                    ),
                    icon:
                        Icons
                            .savings_outlined,
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  _InfoCard(
                    label: 'Still needed',
                    value:
                        _money(
                      totalRemaining,
                    ),
                    icon:
                        Icons
                            .flag_outlined,
                  ),

                  const SizedBox(
                    height: 26,
                  ),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Your goals',
                          style:
                              TextStyle(
                            fontSize: 19,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${_goals.length}',
                        style:
                            const TextStyle(
                          color:
                              AppColors
                                  .inkMuted,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  if (_goals.isEmpty)
                    _EmptyGoals(
                      onCreate:
                          _createGoal,
                    )
                  else
                    for (final goal
                        in _goals)
                      _GoalCard(
                        goal: goal,
                        onAdd: () =>
                            _addSavings(
                          goal,
                        ),
                        onDelete:
                            () =>
                                _deleteGoal(
                          goal,
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// INFO CARD
// -----------------------------------------------------------------------------

class _InfoCard
    extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      width:
          double.infinity,
      child: Card(
        child: Padding(
          padding:
              const EdgeInsets.all(
            18,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    AppColors
                        .primary,
                size: 28,
              ),
              const SizedBox(
                width: 14,
              ),
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    label,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          AppColors
                              .inkMuted,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    value,
                    style:
                        const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// EMPTY STATE
// -----------------------------------------------------------------------------

class _EmptyGoals
    extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyGoals({
    required this.onCreate,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      width:
          double.infinity,
      child: Card(
        child: Padding(
          padding:
              const EdgeInsets.all(
            28,
          ),
          child: Column(
            children: [
              const Icon(
                Icons
                    .flag_outlined,
                size: 44,
                color:
                    AppColors.primary,
              ),
              const SizedBox(
                height: 12,
              ),
              const Text(
                'No savings goals',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              const Text(
                'Create a goal to start tracking your savings.',
                textAlign:
                    TextAlign.center,
              ),
              const SizedBox(
                height: 18,
              ),
              SizedBox(
                width:
                    double.infinity,
                child:
                    FilledButton(
                  onPressed:
                      onCreate,
                  child:
                      const Text(
                    'Create goal',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// GOAL CARD
// -----------------------------------------------------------------------------

class _GoalCard
    extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback onAdd;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final progress =
        goal.progress
            .clamp(
              0.0,
              1.0,
            )
            .toDouble();

    return SizedBox(
      width:
          double.infinity,
      child: Card(
        margin:
            const EdgeInsets.only(
          bottom: 14,
        ),
        child: Padding(
          padding:
              const EdgeInsets.all(
            18,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Row(
                children: [
                  Icon(
                    progress >= 1
                        ? Icons
                            .check_circle_outline
                        : Icons
                            .flag_outlined,
                    color:
                        progress >= 1
                            ? AppColors
                                .primary
                            : AppColors
                                .clay,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Text(
                      goal.name,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        onDelete,
                    icon:
                        const Icon(
                      Icons
                          .more_horiz_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                '${_moneyStatic(goal.savedAmount)} '
                'saved of '
                '${_moneyStatic(goal.targetAmount)}',
                style:
                    const TextStyle(
                  color:
                      AppColors
                          .inkMuted,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    LinearProgressIndicator(
                  value:
                      progress,
                  minHeight: 8,
                  backgroundColor:
                      AppColors
                          .line,
                  valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                    progress >= 1
                        ? AppColors
                            .primary
                        : AppColors
                            .clay,
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                '${(progress * 100).round()}% complete',
                style:
                    const TextStyle(
                  fontSize: 12,
                  color:
                      AppColors
                          .inkMuted,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                '${_moneyStatic(goal.remaining)} remaining',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                '${goal.daysRemaining} days left • '
                'Target ${_formatDateStatic(goal.targetDate)}',
                style:
                    const TextStyle(
                  fontSize: 12,
                  color:
                      AppColors
                          .inkMuted,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    FilledButton.tonal(
                  onPressed:
                      goal.remaining >
                              0
                          ? onAdd
                          : null,
                  child:
                      const Text(
                    'Add savings',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _moneyStatic(
    double value,
  ) {
    return 'Rs. ${value.toStringAsFixed(0)}';
  }

  static String _formatDateStatic(
    DateTime date,
  ) {
    const months = [
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

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }
}

// -----------------------------------------------------------------------------
// ADD SAVINGS SHEET
// -----------------------------------------------------------------------------

class _SavingsAmountSheet
    extends StatefulWidget {
  final SavingsGoal goal;
  final double available;

  const _SavingsAmountSheet({
    required this.goal,
    required this.available,
  });

  @override
  State<_SavingsAmountSheet>
      createState() =>
          _SavingsAmountSheetState();
}

class _SavingsAmountSheetState
    extends State<_SavingsAmountSheet> {
  final TextEditingController
      controller =
      TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final width =
        MediaQuery.sizeOf(
      context,
    ).width;

    return SafeArea(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(
          maxWidth: width,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.viewInsetsOf(
                  context,
                ).bottom +
                24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  'Add savings',
                  style:
                      TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  '${widget.goal.name} • '
                  '${widget.available.toStringAsFixed(0)} '
                  'available this cycle',
                  style:
                      const TextStyle(
                    color:
                        AppColors
                            .inkMuted,
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                TextField(
                  controller:
                      controller,
                  autofocus:
                      true,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Amount to save',
                    prefixText:
                        'Rs. ',
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                SizedBox(
                  width:
                      width - 40,
                  child:
                      FilledButton(
                    onPressed:
                        _submit,
                    child:
                        const Text(
                      'Add to goal',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    final amount =
        double.tryParse(
      controller.text.trim(),
    );

    if (amount == null ||
        !amount.isFinite ||
        amount <= 0) {
      _show(
        'Enter a valid amount.',
      );
      return;
    }

    if (amount >
        widget.goal.remaining) {
      _show(
        'Only Rs. '
        '${widget.goal.remaining.toStringAsFixed(0)} '
        'is needed for this goal.',
      );
      return;
    }

    if (widget.available <= 0) {
      _show(
        'No money is currently available for savings.',
      );
      return;
    }

    if (amount >
        widget.available) {
      _show(
        'Only Rs. '
        '${widget.available.toStringAsFixed(0)} '
        'is available this cycle.',
      );
      return;
    }

    Navigator.of(
      context,
    ).pop(amount);
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(message),
      ),
    );
  }
}