import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/budget.dart';

class BudgetService {
  static const String _planKey = 'budget_plan_v3';
  static const String _legacyPlanKey = 'budget_plan_v2';
  static const String _legacyBudgetKey = 'monthly_budget';

  // --------------------------------------------------------------------------
  // SAVE BUDGET PLAN
  // --------------------------------------------------------------------------

  Future<void> savePlan(BudgetPlan plan) async {
    final prefs =
        await SharedPreferences.getInstance();

    final data = plan.toMap();
    final encoded = jsonEncode(data);

    debugPrint('========================================');
    debugPrint('BUDGET SAVE START');
    debugPrint('BUDGET SAVE DATA: $encoded');

    final success = await prefs.setString(
      _planKey,
      encoded,
    );

    debugPrint(
      'BUDGET SAVE SUCCESS: $success',
    );

    if (!success) {
      throw Exception(
        'Budget plan could not be saved.',
      );
    }

    // Read the exact value back immediately.
    final raw =
        prefs.getString(_planKey);

    debugPrint(
      'BUDGET STORED DATA: $raw',
    );

    if (raw == null ||
        raw.isEmpty) {
      throw Exception(
        'Budget plan was not found after saving.',
      );
    }

    try {
      final decoded =
          jsonDecode(raw);

      if (decoded is! Map) {
        throw Exception(
          'Stored budget data is invalid.',
        );
      }

      final restored =
          BudgetPlan.fromMap(
        Map<String, dynamic>.from(
          decoded,
        ),
      );

      debugPrint(
        'BUDGET RESTORED PERIOD: '
        '${restored.period.name}',
      );

      debugPrint(
        'BUDGET RESTORED AMOUNT: '
        '${restored.amount}',
      );

      debugPrint(
        'BUDGET RESTORED START DATE: '
        '${restored.startDate}',
      );

      debugPrint(
        'BUDGET RESTORED MONTHLY ALLOCATIONS: '
        '${restored.monthlyAllocations}',
      );

      debugPrint(
        'BUDGET RESTORED CARRY FORWARD: '
        '${restored.carryForward}',
      );

      // Verify the important fields.
      if (restored.period !=
          plan.period) {
        throw Exception(
          'Budget period was not saved correctly. '
          'Expected ${plan.period.name}, '
          'got ${restored.period.name}.',
        );
      }

      if ((restored.amount -
                  plan.amount)
              .abs() >
          0.01) {
        throw Exception(
          'Budget amount was not saved correctly.',
        );
      }

      if (plan.period ==
              BudgetPeriod.yearly &&
          restored.monthlyAllocations
                  .length !=
              12) {
        throw Exception(
          'Yearly plan must contain 12 monthly allocations.',
        );
      }

      if (plan.period ==
              BudgetPeriod.yearly &&
          restored.monthlyAllocations
                  .length ==
              12) {
        final savedTotal =
            restored.monthlyAllocations
                .fold<double>(
          0.0,
          (sum, value) =>
              sum + value,
        );

        if ((savedTotal -
                    plan.amount)
                .abs() >
            0.01) {
          throw Exception(
            'Saved monthly allocations do not equal '
            'the annual budget.',
          );
        }
      }

      debugPrint(
        'BUDGET SAVE VERIFIED SUCCESSFULLY',
      );
    } catch (e) {
      debugPrint(
        'BUDGET SAVE VERIFICATION ERROR: $e',
      );
      rethrow;
    }

    debugPrint('BUDGET SAVE COMPLETE');
    debugPrint('========================================');
  }

  // --------------------------------------------------------------------------
  // GET BUDGET PLAN
  // --------------------------------------------------------------------------

  Future<BudgetPlan> getPlan() async {
    final prefs =
        await SharedPreferences.getInstance();

    // Current format first.
    final currentRaw =
        prefs.getString(_planKey);

    if (currentRaw != null &&
        currentRaw.isNotEmpty) {
      try {
        final decoded =
            jsonDecode(currentRaw);

        if (decoded is Map) {
          final plan =
              BudgetPlan.fromMap(
            Map<String, dynamic>.from(
              decoded,
            ),
          );

          debugPrint(
            'BUDGET LOAD: '
            'period=${plan.period.name}, '
            'amount=${plan.amount}, '
            'allocations=${plan.monthlyAllocations}',
          );

          return plan;
        }
      } catch (e) {
        debugPrint(
          'BUDGET LOAD CURRENT FORMAT ERROR: $e',
        );
      }
    }

    // Legacy V2 migration.
    final legacyRaw =
        prefs.getString(
      _legacyPlanKey,
    );

    if (legacyRaw != null &&
        legacyRaw.isNotEmpty) {
      try {
        final decoded =
            jsonDecode(legacyRaw);

        if (decoded is Map) {
          final migrated =
              BudgetPlan.fromMap(
            Map<String, dynamic>.from(
              decoded,
            ),
          );

          await savePlan(
            migrated,
          );

          debugPrint(
            'BUDGET LOAD: migrated legacy plan.',
          );

          return migrated;
        }
      } catch (e) {
        debugPrint(
          'BUDGET LOAD LEGACY ERROR: $e',
        );
      }
    }

    // Very old monthly budget.
    final legacyAmount =
        prefs.getDouble(
              _legacyBudgetKey,
            ) ??
            0.0;

    final fallback =
        BudgetPlan(
      amount: legacyAmount,
      period:
          BudgetPeriod.monthly,
      startDate:
          DateTime.now(),
      monthlyAllocations:
          const <double>[],
      carryForward: false,
    );

    debugPrint(
      'BUDGET LOAD: using fallback monthly plan '
      'with amount=$legacyAmount',
    );

    return fallback;
  }

  // --------------------------------------------------------------------------
  // LEGACY HELPERS
  // --------------------------------------------------------------------------

  Future<void> saveBudget(
    double amount,
  ) async {
    await savePlan(
      BudgetPlan(
        amount: amount,
        period:
            BudgetPeriod.monthly,
        startDate:
            DateTime.now(),
        monthlyAllocations:
            List<double>.filled(
          12,
          amount / 12.0,
        ),
        carryForward: false,
      ),
    );
  }

  Future<double> getBudget() async {
    final plan =
        await getPlan();

    return plan.amount;
  }

  // --------------------------------------------------------------------------
  // CURRENT PERIOD
  // --------------------------------------------------------------------------

  BudgetPeriodInfo currentPeriod(
    BudgetPlan plan, {
    DateTime? now,
  }) {
    final date =
        now ?? DateTime.now();

    final anchor =
        DateTime(
      plan.startDate.year,
      plan.startDate.month,
      plan.startDate.day,
    );

    // MONTHLY
    if (plan.period ==
        BudgetPeriod.monthly) {
      DateTime start =
          DateTime(
        date.year,
        date.month,
        _safeDay(
          date.year,
          date.month,
          anchor.day,
        ),
      );

      if (date.isBefore(start)) {
        final previousMonth =
            DateTime(
          date.year,
          date.month - 1,
          1,
        );

        start =
            DateTime(
          previousMonth.year,
          previousMonth.month,
          _safeDay(
            previousMonth.year,
            previousMonth.month,
            anchor.day,
          ),
        );
      }

      final nextMonth =
          DateTime(
        start.year,
        start.month + 1,
        1,
      );

      final next =
          DateTime(
        nextMonth.year,
        nextMonth.month,
        _safeDay(
          nextMonth.year,
          nextMonth.month,
          anchor.day,
        ),
      );

      return BudgetPeriodInfo(
        start: start,
        end: next.subtract(
          const Duration(days: 1),
        ),
      );
    }

    // YEARLY
    DateTime start =
        DateTime(
      date.year,
      anchor.month,
      _safeDay(
        date.year,
        anchor.month,
        anchor.day,
      ),
    );

    if (date.isBefore(start)) {
      start =
          DateTime(
        date.year - 1,
        anchor.month,
        _safeDay(
          date.year - 1,
          anchor.month,
          anchor.day,
        ),
      );
    }

    final next =
        DateTime(
      start.year + 1,
      anchor.month,
      _safeDay(
        start.year + 1,
        anchor.month,
        anchor.day,
      ),
    );

    return BudgetPeriodInfo(
      start: start,
      end: next.subtract(
        const Duration(days: 1),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // YEARLY MONTHLY PERIODS
  // --------------------------------------------------------------------------

  List<BudgetPeriodInfo> yearlyPeriods(
    BudgetPlan plan, {
    DateTime? cycleStart,
  }) {
    final first =
        cycleStart ??
            currentPeriod(plan).start;

    return List.generate(
      12,
      (index) {
        final rawStart =
            DateTime(
          first.year,
          first.month + index,
          _safeDay(
            first.year,
            first.month + index,
            first.day,
          ),
        );

        final next =
            DateTime(
          rawStart.year,
          rawStart.month + 1,
          _safeDay(
            rawStart.year,
            rawStart.month + 1,
            first.day,
          ),
        );

        return BudgetPeriodInfo(
          start: rawStart,
          end: next.subtract(
            const Duration(days: 1),
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // CURRENT MONTH INDEX WITHIN YEARLY PLAN
  // --------------------------------------------------------------------------

  int currentYearMonthIndex(
    BudgetPlan plan, {
    DateTime? now,
  }) {
    if (plan.period !=
        BudgetPeriod.yearly) {
      return 0;
    }

    final current =
        currentPeriod(
      plan,
      now: now,
    ).start;

    final anchor =
        DateTime(
      current.year,
      plan.startDate.month,
      _safeDay(
        current.year,
        plan.startDate.month,
        plan.startDate.day,
      ),
    );

    final effectiveAnchor =
        current.isBefore(anchor)
            ? DateTime(
                current.year - 1,
                plan.startDate.month,
                _safeDay(
                  current.year - 1,
                  plan.startDate.month,
                  plan.startDate.day,
                ),
              )
            : anchor;

    final diff =
        (current.year -
                effectiveAnchor.year) *
            12 +
        current.month -
        effectiveAnchor.month;

    return diff.clamp(
      0,
      11,
    );
  }

  // --------------------------------------------------------------------------
  // SAFE DAY FOR DIFFERENT MONTH LENGTHS
  // --------------------------------------------------------------------------

  int _safeDay(
    int year,
    int month,
    int requestedDay,
  ) {
    final lastDay =
        DateTime(
      year,
      month + 1,
      0,
    ).day;

    return requestedDay
        .clamp(
          1,
          lastDay,
        )
        .toInt();
  }
}