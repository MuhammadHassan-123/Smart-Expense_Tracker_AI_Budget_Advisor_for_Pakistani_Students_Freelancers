import 'package:flutter/material.dart';

/// Central design tokens for Smart Expense Tracker.
///
/// A minimal, warm, editorial palette rather than a loud SaaS-gradient
/// look: ivory canvas, a single restrained forest-green accent, and a
/// small curated set of muted category colors. Gradients are used in
/// exactly one place (the balance hero) and stay within one hue family.
class AppColors {
  AppColors._();

  static const Color canvas = Color(0xFFFAF8F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF3F1E9);

  static const Color ink = Color(0xFF23261F);
  static const Color inkMuted = Color(0xFF767C71);
  static const Color inkFaint = Color(0xFFAEB3A5);

  static const Color line = Color(0xFFE9E4D7);

  static const Color primary = Color(0xFF1F6F52);
  static const Color primaryDeep = Color(0xFF184F3B);
  static const Color primaryContainer = Color(0xFFDCEBE1);

  static const Color clay = Color(0xFFBD6B44);
  static const Color gold = Color(0xFFC0973F);
  static const Color danger = Color(0xFFB2483C);
  static const Color slateBlue = Color(0xFF4C7186);

  static const List<Color> heroGradient = [Color(0xFF276B4F), primaryDeep];

  /// Curated, desaturated per-category palette -- reads like a mood board,
  /// not a rainbow. Same category always maps to the same color.
  static const Map<String, Color> categoryColors = {
    'Food': Color(0xFFC98A4B),
    'Transport': Color(0xFF4C7A8C),
    'Housing': Color(0xFF8D6E97),
    'Education': Color(0xFF5C7A5E),
    'Bills': Color(0xFF938C74),
    'Bills & Internet': Color(0xFF938C74),
    'Internet': Color(0xFF4C7A8C),
    'Health': Color(0xFFB2564B),
    'Medicine': Color(0xFFB2564B),
    'Shopping': Color(0xFFC77B93),
    'Entertainment': Color(0xFF6E8B8B),
    'Personal': Color(0xFFA97D3E),
    'Emergency': Color(0xFF9C4A3E),
    'Emergency buffer': Color(0xFF9C4A3E),
    'Savings': Color(0xFF1F6F52),
    'Everyday spending': Color(0xFFC0973F),
    'Other': Color(0xFF938C74),
  };

  static Color forCategory(String category) =>
      categoryColors[category] ?? primary;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.045),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> lifted = [
    BoxShadow(
      color: AppColors.primaryDeep.withValues(alpha: 0.18),
      blurRadius: 26,
      offset: const Offset(0, 14),
    ),
  ];
}

/// The single gradient surface in the app, reserved for the balance hero
/// and similar "headline" cards.
class GradientSurface extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final EdgeInsetsGeometry padding;
  final double radius;
  final List<BoxShadow>? shadows;

  const GradientSurface({
    super.key,
    required this.child,
    this.colors = AppColors.heroGradient,
    this.padding = const EdgeInsets.all(22),
    this.radius = 24,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadows ?? AppShadows.lifted,
      ),
      child: child,
    );
  }
}

/// A flat, bordered surface -- the default card style used everywhere
/// instead of Material elevation shadows, for a calmer, minimal look.
class FlatSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? color;

  const FlatSurface({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }
}

/// Small rounded icon badge with a tinted background.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 42,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

/// A soft pill-shaped status/label chip.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const StatusPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Animation primitives -- small, dependency-free, used throughout so the
// app feels alive instead of static.
// ---------------------------------------------------------------------

/// Fades and gently slides a child in on first build. Give list items an
/// increasing [index] for a staggered entrance.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;
  final Axis direction;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.direction = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final delayMs = (index * 45).clamp(0, 420);
    return TweenAnimationBuilder<double>(
      key: ValueKey('fade_slide_$index'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final offset = direction == Axis.vertical
            ? Offset(0, (1 - value) * 14)
            : Offset((1 - value) * 14, 0);
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(offset: offset, child: child),
        );
      },
      child: child,
    );
  }
}

/// Animates a numeric value counting up/down smoothly whenever it changes.
class AnimatedMoney extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final String prefix;
  const AnimatedMoney({super.key, required this.value, this.style, this.prefix = 'Rs. '});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('$prefix${v.toStringAsFixed(0)}', style: style),
    );
  }
}

/// A progress bar that animates smoothly to its new [value] instead of
/// jumping, using the shared curve/timing used across the app.
class AnimatedBar extends StatelessWidget {
  final double value;
  final double minHeight;
  final Color? background;
  final Color? color;
  final double radius;

  const AnimatedBar({
    super.key,
    required this.value,
    this.minHeight = 8,
    this.background,
    this.color,
    this.radius = 30,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: LinearProgressIndicator(
          value: v,
          minHeight: minHeight,
          backgroundColor: background ?? AppColors.line,
          valueColor: AlwaysStoppedAnimation(color ?? AppColors.primary),
        ),
      ),
    );
  }
}

/// Wraps a tappable surface with a subtle press-down scale for tactile
/// feedback, on top of the normal ink ripple.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  const PressableScale({super.key, required this.child, this.onTap, this.borderRadius});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A page transition that fades and slides up gently, used in place of
/// the default platform transition for a more considered feel.
Route<T> softRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Runs [builder] and, if it throws during build, shows a clear "this
/// needs your attention" screen with a retry action instead of letting
/// the exception blank the screen or crash it. A safety net for any
/// unexpected data-shape issue -- the person always sees something
/// actionable, never nothing.
Widget guardBuild(String screenTitle, VoidCallback onRetry, Widget Function() builder) {
  try {
    return builder();
  } catch (_) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: Text(screenTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IconBadge(icon: Icons.error_outline_rounded, color: AppColors.danger, size: 52, iconSize: 25),
              const SizedBox(height: 16),
              const Text('This screen ran into a problem', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 6),
              const Text(
                'Your data is safe. Tap below to reload this screen.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkMuted),
              ),
              const SizedBox(height: 18),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a confirm/cancel dialog for a destructive action.
///
/// Deliberately built as a plain [Dialog] with a hand-laid-out [Row] for
/// its buttons, instead of [AlertDialog]'s `actions` parameter. AlertDialog
/// routes multi-button `actions` through an internal OverflowBar, which has
/// a confirmed Flutter framework bug (reproducible on stable 3.29-3.33,
/// flutter/flutter#169214) where its "dry baseline" layout pass can throw
/// and corrupt that frame's whole render pipeline -- which can leave an
/// unrelated screen behind the dialog stuck rendering blank until the app
/// restarts. A manual Row of buttons never touches that code path.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 10),
            Text(message, style: const TextStyle(color: AppColors.inkMuted, height: 1.4)),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(cancelLabel)),
                const SizedBox(width: 6),
                FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(confirmLabel)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result == true;
}
