import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_session/audio_session.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_manager.dart';
import 'core/router/app_router.dart';
import 'core/services/ad_service.dart';
import 'core/services/purchase_service.dart';
import 'core/services/bgm_preferences.dart';
import 'core/l10n/app_strings.dart';
import 'core/database/database_helper.dart';
import 'shared/models/run_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: SRColors.background,
  ));

  // BGM 사용자 설정 먼저 로드 — AudioSession 설정이 externalMusicMode 를 참조.
  try {
    await BgmPreferences.I.loadSaved();
  } catch (e) {
    debugPrint('BgmPreferences 로드 실패: $e');
  }

  // iOS 오디오 세션 설정.
  // externalMusicMode 가 꺼져 있으면 mixWithOthers 를 빼서 앱을 "primary audio app" 으로
  // 선언 → iOS 가 백그라운드 장시간 러닝 중에도 오디오 재생을 이유로 앱을 유지.
  // 외부 음악(Spotify 등)과 섞고 싶을 때만 mix 로 전환.
  try {
    final session = await AudioSession.instance;
    Future<void> applyConfig() async {
      try {
        final external = BgmPreferences.I.externalMusicMode.value;
        await session.configure(AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          avAudioSessionCategoryOptions: external
              ? AVAudioSessionCategoryOptions.mixWithOthers
              : AVAudioSessionCategoryOptions.none,
          androidAudioAttributes: const AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            usage: AndroidAudioUsage.game,
          ),
          androidAudioFocusGainType: external
              ? AndroidAudioFocusGainType.gainTransientMayDuck
              : AndroidAudioFocusGainType.gain,
        ));
        await session.setActive(true);
      } catch (e) {
        debugPrint('AudioSession applyConfig 실패: $e');
      }
    }

    await applyConfig();

    // 사용자가 설정에서 외부 음악 모드를 토글하면 즉시 세션 재설정.
    BgmPreferences.I.externalMusicMode.addListener(() {
      applyConfig();
    });

    // 전화/알람 등 인터럽션이 끝나면 세션 재활성화.
    // just_audio 는 handleInterruptions=true 가 기본이라 일시정지·재개는 자체 처리하지만,
    // 세션이 비활성화된 채로 남으면 재생이 묵음이 되는 케이스가 있어 setActive 로 보강.
    session.interruptionEventStream.listen((event) {
      if (!event.begin) {
        session.setActive(true).catchError((e) {
          debugPrint('AudioSession 재활성화 실패: $e');
          return false;
        });
      }
    });
  } catch (e) {
    debugPrint('AudioSession 설정 실패: $e');
  }

  try {
    await FlutterNaverMap().init(
      clientId: 'eilr4xtzsr',
      onAuthFailed: (ex) => debugPrint('네이버맵 인증 실패: $ex'),
    );
  } catch (e) {
    debugPrint('네이버맵 초기화 실패: $e');
  }

  try {
    await AdService().initialize();
  } catch (e) {
    debugPrint('AdService 초기화 실패: $e');
  }

  try {
    await PurchaseService().initialize();
  } catch (e) {
    debugPrint('PurchaseService 초기화 실패: $e');
  }

  try {
    await ThemeManager.I.loadSaved();
  } catch (e) {
    debugPrint('ThemeManager 로드 실패: $e');
  }

  final langSelected = await isLanguageSelected();

  if (langSelected) {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language') ?? 'en';
    await S.init(langCode);
  }

  try {
    final unit = await DatabaseHelper.getSetting('unit') ?? 'km';
    RunModel.setUnit(unit);
  } catch (e) {
    debugPrint('Unit 설정 로드 실패: $e');
  }

  runApp(ShadowRunApp(languageSelected: langSelected));
}

class ShadowRunApp extends StatelessWidget {
  final bool languageSelected;
  const ShadowRunApp({super.key, required this.languageSelected});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: S.languageNotifier,
      builder: (context, lang, _) {
        // 테마 변경 시에도 Router state 유지해야 (codex P1: key가 바뀌면 GoRouter 재생성 → /splash로 재부팅).
        // 각 화면이 자체적으로 ThemeManager.themeIdNotifier를 ValueListenableBuilder로 구독해 rebuild.
        return MaterialApp.router(
          key: ValueKey(lang),
          title: 'SHADOW RUN',
          debugShowCheckedModeBanner: false,
          theme: SRTheme.dark,
          routerConfig: createRouter(languageSelected),
        );
      },
    );
  }
}
