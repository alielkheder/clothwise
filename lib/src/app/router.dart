import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:clothwise/src/features/splash/presentation/splash_screen.dart';
import 'package:clothwise/src/features/splash/presentation/onboarding_screen.dart';
import 'package:clothwise/src/features/onboarding/presentation/style_questionnaire_screen.dart';
import 'package:clothwise/src/features/auth/presentation/login_screen.dart';
import 'package:clothwise/src/features/auth/presentation/register_screen.dart';
import 'package:clothwise/src/features/auth/presentation/email_verification_screen.dart';
import 'package:clothwise/src/features/home/presentation/home_screen.dart';
import 'package:clothwise/src/features/outfit/presentation/outfit_details_screen.dart';
import 'package:clothwise/src/features/wardrobe/presentation/wardrobe_screen.dart';
import 'package:clothwise/src/features/shop/presentation/shop_screen.dart';
import 'package:clothwise/src/features/profile/presentation/profile_screen.dart';
import 'package:clothwise/src/features/profile/presentation/settings_screen.dart';
import 'package:clothwise/src/features/recommendations/presentation/recommendations_screen.dart';
import 'package:clothwise/src/widgets/app_scaffold.dart';

/// Route paths
abstract class RoutePaths {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String styleQuestionnaire = '/style-questionnaire';
  static const String login = '/login';
  static const String register = '/register';
  static const String emailVerification = '/email-verification';
  static const String home = '/home';
  static const String outfitDetails = '/outfit/:id';
  static const String wardrobe = '/wardrobe';
  static const String shop = '/shop';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String recommendations = '/recommendations';
}

/// Route names
abstract class RouteNames {
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String styleQuestionnaire = 'style-questionnaire';
  static const String login = 'login';
  static const String register = 'register';
  static const String emailVerification = 'email-verification';
  static const String home = 'home';
  static const String outfitDetails = 'outfit-details';
  static const String wardrobe = 'wardrobe';
  static const String shop = 'shop';
  static const String profile = 'profile';
  static const String settings = 'settings';
  static const String recommendations = 'recommendations';
}

/// Global navigation key for accessing router from anywhere
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey =
    GlobalKey<NavigatorState>();

/// GoRouter configuration
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: RoutePaths.splash,
  debugLogDiagnostics: true,
  routes: [
    // Splash & Onboarding (no bottom nav)
    GoRoute(
      path: RoutePaths.splash,
      name: RouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: RoutePaths.onboarding,
      name: RouteNames.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: RoutePaths.styleQuestionnaire,
      name: RouteNames.styleQuestionnaire,
      builder: (context, state) => const StyleQuestionnaireScreen(),
    ),
    GoRoute(
      path: RoutePaths.login,
      name: RouteNames.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: RoutePaths.register,
      name: RouteNames.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: RoutePaths.emailVerification,
      name: RouteNames.emailVerification,
      builder: (context, state) => const EmailVerificationScreen(),
    ),

    // Main app with bottom navigation
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) {
        return AppScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: RoutePaths.home,
          name: RouteNames.home,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: RoutePaths.wardrobe,
          name: RouteNames.wardrobe,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const WardrobeScreen(),
          ),
        ),
        GoRoute(
          path: RoutePaths.shop,
          name: RouteNames.shop,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const ShopScreen(),
          ),
        ),
        GoRoute(
          path: RoutePaths.profile,
          name: RouteNames.profile,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const ProfileScreen(),
          ),
        ),
      ],
    ),

    // Settings (full screen, outside shell)
    GoRoute(
      path: RoutePaths.settings,
      name: RouteNames.settings,
      builder: (context, state) => const SettingsScreen(),
    ),

    // Outfit Details (full screen, outside shell)
    GoRoute(
      path: RoutePaths.outfitDetails,
      name: RouteNames.outfitDetails,
      builder: (context, state) {
        final outfitId = state.pathParameters['id'] ?? '1';
        return OutfitDetailsScreen(outfitId: outfitId);
      },
    ),

    // Recommendations (full screen, outside shell)
    GoRoute(
      path: RoutePaths.recommendations,
      name: RouteNames.recommendations,
      builder: (context, state) {
        final imagePath = state.extra as String;
        return RecommendationsScreen(imagePath: imagePath);
      },
    ),
  ],
);
