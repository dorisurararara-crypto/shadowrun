import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadowrun/features/home/presentation/pages/home_screen.dart';
import 'package:shadowrun/features/prepare/presentation/pages/prepare_screen.dart';
import 'package:shadowrun/features/running/presentation/pages/running_screen.dart';
import 'package:shadowrun/features/result/presentation/pages/result_screen.dart';
import 'package:shadowrun/features/history/presentation/pages/history_screen.dart';
import 'package:shadowrun/features/settings/presentation/pages/settings_screen.dart';
import 'package:shadowrun/features/settings/presentation/pages/theme_picker_screen.dart';
import 'package:shadowrun/features/analysis/presentation/pages/analysis_screen.dart';
import 'package:shadowrun/features/onboarding/presentation/pages/language_select_screen.dart';
import 'package:shadowrun/features/splash/splash_screen.dart';

GoRouter createRouter(bool languageSelected) {
  // 테스트용 초기 라우트 override (dart-define=INITIAL_ROUTE=/history 등).
  // 비어 있으면 기존 동작 (언어 선택 → splash → home).
  const override = String.fromEnvironment('INITIAL_ROUTE', defaultValue: '');
  final initial = override.isNotEmpty
      ? override
      : (languageSelected ? '/splash' : '/language');
  return GoRouter(
    initialLocation: initial,
    routes: _routes,
  );
}

final _routes = <GoRoute>[
    GoRoute(
      path: '/language',
      builder: (context, state) => const LanguageSelectScreen(),
    ),
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/prepare',
      builder: (context, state) {
        final shadowRunId = state.extra as int?;
        return PrepareScreen(shadowRunId: shadowRunId);
      },
    ),
    GoRoute(
      path: '/running',
      builder: (context, state) {
        final args = state.extra;
        if (args == null || args is int) {
          // Legacy: just shadowRunId
          return RunningScreen(shadowRunId: args as int?);
        }
        final map = args as Map<String, dynamic>? ?? {};
        return RunningScreen(
          shadowRunId: map['shadowRunId'] as int?,
          runMode: map['mode'] as String? ?? 'freerun',
          sameLocation: map['sameLocation'] as bool? ?? true,
          shoeId: map['shoeId'] as int?,
          legendId: map['legendId'] as String?,
          pacemakerPaceSec: map['pacemakerPaceSec'] as int?,
        );
      },
    ),
    GoRoute(
      path: '/result',
      redirect: (context, state) {
        final args = state.extra as Map<String, dynamic>? ?? {};
        var runId = args['runId'] as int? ?? 0;
        // 테스트용: state.extra 없을 때만 dart-define 의 TEST_RUN_ID 로 대체.
        if (runId == 0) {
          const testRunId = int.fromEnvironment('TEST_RUN_ID', defaultValue: 0);
          if (testRunId > 0) runId = testRunId;
        }
        if (runId == 0) return '/';
        return null;
      },
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>? ?? {};
        var runId = args['runId'] as int? ?? 0;
        if (runId == 0) {
          const testRunId = int.fromEnvironment('TEST_RUN_ID', defaultValue: 0);
          if (testRunId > 0) runId = testRunId;
        }
        final result = args['result'] as String?;
        return ResultScreen(
          runId: runId,
          result: result,
        );
      },
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/theme',
      builder: (context, state) => const ThemePickerScreen(),
    ),
    GoRoute(
      path: '/analysis',
      builder: (context, state) => const AnalysisScreen(),
    ),
  ];

Future<bool> isLanguageSelected() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('language_selected') ?? false;
}
