import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../theme/app_theme.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final Future<void> Function() onDelete;
  final Future<void> Function()? onMarkAsPaid;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.onDelete,
    this.onMarkAsPaid,
  });

  Future<void> _deleteExpense(
    BuildContext context,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delete expense?',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Remove "${expense.title}" · '
                  'Rs. ${expense.amount.toStringAsFixed(0)}?',
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext)
                              .pop(false);
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              AppColors.danger,
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext)
                              .pop(true);
                        },
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted || confirmed != true) {
      return;
    }

    try {
      await onDelete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Expense deleted.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete expense: $e',
          ),
        ),
      );
    }
  }

  Future<void> _markAsPaid(
    BuildContext context,
  ) async {
    if (onMarkAsPaid == null) return;

    try {
      await onMarkAsPaid!();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Expense marked as paid.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update expense: $e',
          ),
        ),
      );
    }
  }

  Future<void> _showActions(
    BuildContext context,
  ) async {
    if (expense.status == ExpenseStatus.upcoming) {
      final action = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: AppColors.canvas,
        showDragHandle: true,
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Mark as paid',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(sheetContext)
                          .pop('paid');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.danger,
                    ),
                    title: const Text(
                      'Delete expense',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(sheetContext)
                          .pop('delete');
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (!context.mounted || action == null) {
        return;
      }

      if (action == 'paid') {
        await _markAsPaid(context);
      } else if (action == 'delete') {
        await _deleteExpense(context);
      }

      return;
    }

    // Paid expense: directly show delete confirmation.
    await _deleteExpense(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isUpcoming =
        expense.status == ExpenseStatus.upcoming;

    final color =
        AppColors.forCategory(expense.category);

    final icon = switch (expense.category) {
      'Food' => Icons.restaurant_rounded,
      'Transport' => Icons.directions_car_rounded,
      'Housing' => Icons.home_rounded,
      'Education' => Icons.school_rounded,
      'Health' || 'Medicine' =>
        Icons.health_and_safety_rounded,
      'Shopping' =>
        Icons.shopping_bag_rounded,
      'Entertainment' =>
        Icons.movie_rounded,
      'Internet' || 'Bills' =>
        Icons.wifi_rounded,
      _ => Icons.receipt_long_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.line,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          14,
          12,
          10,
          12,
        ),
        child: Row(
          children: [
            IconBadge(
              icon: icon,
              color: color,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${expense.category} • '
                          '${expense.type == ExpenseType.fixed ? 'Fixed' : 'Variable'}',
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              theme.textTheme.bodySmall,
                        ),
                      ),
                      if (isUpcoming) ...[
                        const SizedBox(width: 6),
                        const StatusPill(
                          label: 'Upcoming',
                          color: AppColors.gold,
                        ),
                      ],
                      if (expense.recurrence != ExpenseRecurrence.none) ...[
                        const SizedBox(width: 6),
                        StatusPill(
                          label: expense.recurrence.label,
                          color: AppColors.slateBlue,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs. ${expense.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      _showActions(context),
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    size: 20,
                  ),
                  tooltip:
                      'Expense actions',
                  visualDensity:
                      VisualDensity.compact,
                  style:
                      IconButton.styleFrom(
                    padding:
                        EdgeInsets.zero,
                    minimumSize:
                        const Size(30, 30),
                    foregroundColor:
                        AppColors.inkFaint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}