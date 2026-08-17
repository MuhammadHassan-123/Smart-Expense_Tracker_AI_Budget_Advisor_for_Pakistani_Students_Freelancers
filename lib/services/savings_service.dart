import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/savings_contribution.dart';
import '../models/savings_goal.dart';

class SavingsService {
  static const String _goalsKey = 'savings_goals_v1';
  static const String _contributionsKey =
      'savings_contributions_v1';

  // ============================================================
  // GET SAVINGS GOALS
  // ============================================================

  Future<List<SavingsGoal>> getGoals() async {
    debugPrint('========================================');
    debugPrint('SAVINGS DEBUG: getGoals() started');
    debugPrint('SAVINGS DEBUG: key = $_goalsKey');

    try {
      final prefs =
          await SharedPreferences.getInstance();

      final raw = prefs.getString(_goalsKey);

      debugPrint(
        'SAVINGS DEBUG: raw stored value = $raw',
      );

      // No stored value at all.
      if (raw == null || raw.isEmpty) {
        debugPrint(
          'SAVINGS DEBUG: NO SAVINGS DATA FOUND',
        );
        debugPrint('SAVINGS DEBUG: goals count = 0');
        debugPrint('========================================');

        return [];
      }

      dynamic decoded;

      try {
        decoded = jsonDecode(raw);
      } catch (e) {
        debugPrint(
          'SAVINGS DEBUG: JSON DECODE ERROR = $e',
        );
        debugPrint('========================================');

        return [];
      }

      debugPrint(
        'SAVINGS DEBUG: decoded type = '
        '${decoded.runtimeType}',
      );

      debugPrint(
        'SAVINGS DEBUG: decoded value = $decoded',
      );

      if (decoded is! List) {
        debugPrint(
          'SAVINGS DEBUG: STORED DATA IS NOT A LIST',
        );
        debugPrint('========================================');

        return [];
      }

      final goals = <SavingsGoal>[];

      for (final item in decoded) {
        try {
          if (item is! Map) {
            debugPrint(
              'SAVINGS DEBUG: skipping non-map item: $item',
            );
            continue;
          }

          final map =
              Map<String, dynamic>.from(item);

          final goal =
              SavingsGoal.fromMap(map);

          goals.add(goal);

          debugPrint(
            'SAVINGS DEBUG: GOAL FOUND'
            ' | id=${goal.id}'
            ' | name=${goal.name}'
            ' | saved=${goal.savedAmount}'
            ' | target=${goal.targetAmount}'
            ' | remaining=${goal.remaining}'
            ' | targetDate=${goal.targetDate}',
          );
        } catch (e) {
          debugPrint(
            'SAVINGS DEBUG: INVALID GOAL SKIPPED = $e',
          );

          debugPrint(
            'SAVINGS DEBUG: invalid item = $item',
          );
        }
      }

      debugPrint(
        'SAVINGS DEBUG: TOTAL GOALS FOUND = '
        '${goals.length}',
      );

      debugPrint(
        'SAVINGS DEBUG: getGoals() finished',
      );

      debugPrint('========================================');

      return goals;
    } catch (e, stackTrace) {
      debugPrint(
        'SAVINGS DEBUG: COMPLETE getGoals ERROR = $e',
      );

      debugPrint(
        'SAVINGS DEBUG: stack trace = $stackTrace',
      );

      debugPrint('========================================');

      return [];
    }
  }

  // ============================================================
  // SAVE ALL GOALS
  // ============================================================

  Future<void> saveGoals(
    List<SavingsGoal> goals,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      goals
          .map(
            (goal) => goal.toMap(),
          )
          .toList(),
    );

    await prefs.setString(
      _goalsKey,
      encoded,
    );

    debugPrint(
      'SAVINGS DEBUG: saved ${goals.length} goals',
    );

    debugPrint(
      'SAVINGS DEBUG: storage value = $encoded',
    );
  }

  // ============================================================
  // ADD GOAL
  // ============================================================

  Future<void> addGoal(
    SavingsGoal goal,
  ) async {
    debugPrint(
      'SAVINGS DEBUG: adding goal ${goal.name}',
    );

    final goals =
        await getGoals();

    goals.insert(
      0,
      goal,
    );

    await saveGoals(
      goals,
    );

    debugPrint(
      'SAVINGS DEBUG: goal added successfully',
    );
  }

  // ============================================================
  // UPDATE GOAL
  // ============================================================

  Future<void> updateGoal(
    SavingsGoal goal,
  ) async {
    final goals =
        await getGoals();

    final index =
        goals.indexWhere(
      (item) => item.id == goal.id,
    );

    if (index >= 0) {
      goals[index] = goal;

      await saveGoals(
        goals,
      );

      debugPrint(
        'SAVINGS DEBUG: updated goal ${goal.name}',
      );
    } else {
      debugPrint(
        'SAVINGS DEBUG: goal not found for update: '
        '${goal.id}',
      );
    }
  }

  // ============================================================
  // DELETE GOAL
  // ============================================================

  Future<void> deleteGoal(
    String id,
  ) async {
    final goals =
        await getGoals();

    goals.removeWhere(
      (goal) => goal.id == id,
    );

    await saveGoals(
      goals,
    );

    final contributions =
        await getContributions();

    contributions.removeWhere(
      (item) => item.goalId == id,
    );

    await saveContributions(
      contributions,
    );

    debugPrint(
      'SAVINGS DEBUG: deleted goal $id',
    );
  }

  // ============================================================
  // GET CONTRIBUTIONS
  // ============================================================

  Future<List<SavingsContribution>>
      getContributions() async {
    debugPrint(
      'SAVINGS DEBUG: reading contributions',
    );

    try {
      final prefs =
          await SharedPreferences.getInstance();

      final raw =
          prefs.getString(
        _contributionsKey,
      );

      if (raw == null || raw.isEmpty) {
        debugPrint(
          'SAVINGS DEBUG: no contribution data',
        );

        return [];
      }

      dynamic decoded;

      try {
        decoded =
            jsonDecode(raw);
      } catch (e) {
        debugPrint(
          'SAVINGS DEBUG: contribution JSON error = $e',
        );

        return [];
      }

      if (decoded is! List) {
        return [];
      }

      final contributions =
          <SavingsContribution>[];

      for (final item in decoded) {
        try {
          if (item is! Map) continue;

          final map =
              Map<String, dynamic>.from(item);

          contributions.add(
            SavingsContribution.fromMap(
              map,
            ),
          );
        } catch (e) {
          debugPrint(
            'SAVINGS DEBUG: invalid contribution skipped = $e',
          );
        }
      }

      debugPrint(
        'SAVINGS DEBUG: contributions count = '
        '${contributions.length}',
      );

      return contributions;
    } catch (e) {
      debugPrint(
        'SAVINGS DEBUG: getContributions error = $e',
      );

      return [];
    }
  }

  // ============================================================
  // SAVE CONTRIBUTIONS
  // ============================================================

  Future<void> saveContributions(
    List<SavingsContribution>
        contributions,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _contributionsKey,
      jsonEncode(
        contributions
            .map(
              (item) => item.toMap(),
            )
            .toList(),
      ),
    );
  }

  // ============================================================
  // ADD CONTRIBUTION
  // ============================================================

  Future<void> addContribution(
    SavingsContribution contribution,
  ) async {
    final contributions =
        await getContributions();

    contributions.insert(
      0,
      contribution,
    );

    await saveContributions(
      contributions,
    );

    debugPrint(
      'SAVINGS DEBUG: added contribution '
      '${contribution.amount}',
    );
  }

  // ============================================================
  // GOAL CONTRIBUTIONS BETWEEN DATES
  // ============================================================

  double goalContributedBetween(
    String goalId,
    DateTime start,
    DateTime end,
    List<SavingsContribution>
        contributions,
  ) {
    return contributions
        .where(
          (item) =>
              item.goalId == goalId &&
              !item.date.isBefore(start) &&
              !item.date.isAfter(end),
        )
        .fold<double>(
          0,
          (sum, item) =>
              sum + item.amount,
        );
  }

  // ============================================================
  // ALL CONTRIBUTIONS BETWEEN DATES
  // ============================================================

  double contributedBetween(
    DateTime start,
    DateTime end,
    List<SavingsContribution>
        contributions,
  ) {
    return contributions
        .where(
          (item) =>
              !item.date.isBefore(start) &&
              !item.date.isAfter(end),
        )
        .fold<double>(
          0,
          (sum, item) =>
              sum + item.amount,
        );
  }
}