import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'config/theme.dart';
import 'models/user.dart';
import 'providers/user_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/create_bill_screen.dart';
import 'screens/bill_detail_screen_new.dart';
import 'screens/create_session_screen.dart';
import 'screens/nearby_sessions_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/session_screen.dart';
import 'screens/contact_picker_screen.dart';
import 'screens/manual_participants_screen.dart';

void main() {
  runApp(const ProviderScope(child: DuTaksimApp()));
}

class DuTaksimApp extends ConsumerStatefulWidget {
  const DuTaksimApp({super.key});

  @override
  ConsumerState<DuTaksimApp> createState() => _DuTaksimAppState();
}

class _DuTaksimAppState extends ConsumerState<DuTaksimApp> {
  late GoRouter _router;

  @override
  void initState() {
    super.initState();

    _router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const MainNavigationScreen(),
        ),
        GoRoute(
          path: '/create-bill',
          builder: (context, state) => const CreateBillScreen(),
        ),
        GoRoute(
          path: '/bill/:id',
          builder: (context, state) {
            final billId = state.pathParameters['id']!;
            return BillDetailScreenNew(billId: billId);
          },
        ),
        GoRoute(
          path: '/create-session',
          builder: (context, state) => const CreateSessionScreen(),
        ),
        GoRoute(
          path: '/nearby-sessions',
          builder: (context, state) => const NearbySessionsScreen(),
        ),
        GoRoute(
          path: '/qr-scanner',
          builder: (context, state) => const QRScannerScreen(),
        ),
        GoRoute(
          path: '/session',
          builder: (context, state) => const SessionScreen(),
        ),
        GoRoute(
          path: '/contact-picker/:sessionId',
          builder: (context, state) {
            final sessionId = state.pathParameters['sessionId']!;
            return ContactPickerScreen(sessionId: sessionId);
          },
        ),
        GoRoute(
          path: '/manual-participants',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return ManualParticipantsScreen(
              sessionId: extra?['sessionId'] ?? '',
              sessionName: extra?['sessionName'] ?? 'Session',
            );
          },
        ),
      ],
      redirect: (context, state) {
        final user = ref.read(userNotifierProvider);
        final isOnboarding = state.matchedLocation == '/onboarding';

        if (user == null && !isOnboarding) {
          return '/onboarding';
        }

        if (user != null && isOnboarding) {
          return '/';
        }

        return null;
      },
    );

    // Load user on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userNotifierProvider.notifier).loadUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to user changes and navigate accordingly
    ref.listen<User?>(userNotifierProvider, (previous, next) {
      if (previous == null && next != null) {
        // User just logged in, navigate to home
        _router.go('/');
      } else if (previous != null && next == null) {
        // User just logged out, navigate to onboarding
        _router.go('/onboarding');
      }
    });

    return MaterialApp.router(
      title: 'DuTaksim',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
