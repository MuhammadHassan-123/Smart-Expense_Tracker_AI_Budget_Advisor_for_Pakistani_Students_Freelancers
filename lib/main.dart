import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'screens/main_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // If any single widget anywhere fails to build, show a small, clearly
  // visible message in its place instead of Flutter's default (which can
  // be a nearly invisible box, especially outside debug mode). This turns
  // "a screen went silently blank" into "here's exactly what broke and
  // where" -- both for testing now and for anyone using the app later.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      color: AppColors.canvas,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Text(
        'This part of the screen hit a problem.\n${details.exceptionAsString()}',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  };

  runApp(const SmartExpenseTracker());
}

class SmartExpenseTracker extends StatelessWidget {
  const SmartExpenseTracker({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.primaryDeep,
      secondary: AppColors.clay,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFF3E1D5),
      onSecondaryContainer: const Color(0xFF7A3F22),
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkMuted,
      outline: AppColors.line,
      surfaceContainerHighest: AppColors.surfaceAlt,
      error: AppColors.danger,
    );

    final baseText = Typography.material2021(colorScheme: scheme).black;
    final textTheme = baseText.copyWith(
      headlineMedium: baseText.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: AppColors.ink,
        height: 1.15,
      ),
      headlineSmall: baseText.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: AppColors.ink,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        letterSpacing: -0.2,
      ),
      titleMedium: baseText.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(color: AppColors.ink, height: 1.4),
      bodyMedium: baseText.bodyMedium?.copyWith(color: AppColors.inkMuted, height: 1.4),
      bodySmall: baseText.bodySmall?.copyWith(color: AppColors.inkMuted),
      labelLarge: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      labelMedium: baseText.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.inkMuted),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Expense Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: AppColors.canvas,
        splashFactory: InkRipple.splashFactory,
        textTheme: textTheme,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.canvas,
          foregroundColor: AppColors.ink,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: AppColors.ink),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: AppColors.canvas,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shadowColor: AppColors.ink.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            side: BorderSide(color: AppColors.line),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: AppColors.ink,
          textColor: AppColors.ink,
        ),
        dividerTheme: DividerThemeData(color: AppColors.line, space: 1, thickness: 1),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceAlt,
          labelStyle: const TextStyle(color: AppColors.inkMuted, fontWeight: FontWeight.w600),
          hintStyle: const TextStyle(color: AppColors.inkFaint),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: AppColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: AppColors.line),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: AppColors.primary, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 70,
          elevation: 0,
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shadowColor: AppColors.ink.withValues(alpha: 0.06),
          indicatorColor: AppColors.primaryContainer,
          indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          labelTextStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? AppColors.primaryDeep : AppColors.inkMuted,
              size: 23,
            );
          }),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          extendedTextStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.1),
          shape: StadiumBorder(),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, letterSpacing: 0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            minimumSize: const Size.fromHeight(50),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            side: const BorderSide(color: AppColors.line, width: 1.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryDeep,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceAlt,
            foregroundColor: AppColors.ink,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          ),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: AppColors.primary,
            selectedForegroundColor: Colors.white,
            backgroundColor: AppColors.surfaceAlt,
            foregroundColor: AppColors.inkMuted,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            side: const BorderSide(color: AppColors.line),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: const WidgetStatePropertyAll(Colors.white),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? AppColors.primary : AppColors.line,
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
          linearTrackColor: AppColors.line,
          circularTrackColor: AppColors.line,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.ink,
          contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          showDragHandle: true,
          dragHandleColor: AppColors.line,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
        ),
      ),
      home: const AppBootstrap(),
    );
  }
}

/// Loads [AppState] exactly once before showing the app, so no screen ever
/// has to run its own startup fetch again. Guaranteed to move past this
/// screen -- [AppState.init] always completes within its own timeout.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await AppState.instance.init();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!AppState.instance.initialized) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconBadge(icon: Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 56, iconSize: 26),
              SizedBox(height: 18),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ],
          ),
        ),
      );
    }
    return const MainScreen();
  }
}
