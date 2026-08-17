import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'budget_screen.dart';
import 'savings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reads straight from the already-loaded, in-memory AppState -- this
    // screen never runs its own fetch, so it can never get stuck loading.
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) => guardBuild('Profile', () => AppState.instance.refresh(), () {
        final state = AppState.instance;
        final theme = Theme.of(context);
        final budget = state.plan.amount;
        final planLabel = budget > 0 ? state.plan.periodLabel : 'Not set';
        final goals = state.goals.length;
        final totalExpenses = state.expenses.fold<double>(0, (sum, item) => sum + item.amount);

        return Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(title: const Text('Profile')),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: state.refresh,
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 40),
                children: [
                  FadeSlideIn(
                    child: GradientSurface(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                            ),
                            child: const Icon(Icons.person_rounded, size: 28, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Smart Expense Tracker', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16.5)),
                                const SizedBox(height: 5),
                                Text(
                                  '$planLabel plan • ${goals == 0 ? 'No savings goals' : '$goals savings goal${goals == 1 ? '' : 's'}'}',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text('Manage', style: theme.textTheme.titleMedium?.copyWith(color: AppColors.inkMuted)),
                  const SizedBox(height: 10),
                  FadeSlideIn(
                    index: 1,
                    child: _SettingTile(
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppColors.primary,
                      title: 'Budget plan',
                      subtitle: budget > 0 ? 'Rs. ${budget.toStringAsFixed(0)} • $planLabel' : 'Set a monthly or yearly plan',
                      onTap: () => Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const BudgetScreen())),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeSlideIn(
                    index: 2,
                    child: _SettingTile(
                      icon: Icons.flag_rounded,
                      color: AppColors.clay,
                      title: 'Savings goals',
                      subtitle: goals == 0 ? 'Create your first goal' : '$goals active goal${goals == 1 ? '' : 's'}',
                      onTap: () => Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const SavingsScreen())),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text('Overview', style: theme.textTheme.titleMedium?.copyWith(color: AppColors.inkMuted)),
                  const SizedBox(height: 10),
                  FadeSlideIn(
                    index: 3,
                    child: _SettingTile(
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.gold,
                      title: 'Tracked expenses',
                      subtitle: 'Rs. ${totalExpenses.toStringAsFixed(0)} total recorded',
                      onTap: null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeSlideIn(
                    index: 4,
                    child: _SettingTile(
                      icon: Icons.currency_exchange_rounded,
                      color: AppColors.slateBlue,
                      title: 'Currency',
                      subtitle: 'Pakistani Rupee (PKR)',
                      onTap: null,
                    ),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => showAboutDialog(
                        context: context,
                        applicationName: 'Smart Expense Tracker',
                        applicationVersion: '4.0.0',
                        applicationIcon: const IconBadge(icon: Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 46, iconSize: 22),
                        children: const [Text('A smart expense, budgeting, analytics and savings application for students and freelancers.')],
                      ),
                      icon: const Icon(Icons.info_outline_rounded),
                      label: const Text('About the app'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return PressableScale(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: FlatSurface(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            IconBadge(icon: icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.inkMuted, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (enabled) const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}
