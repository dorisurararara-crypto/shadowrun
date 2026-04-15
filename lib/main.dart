import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_session/audio_session.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/ad_service.dart';
import 'core/services/purchase_service.dart';
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

  // iOS 오디오 세션 설정 (무음 모드에서도 재생, 백그라운드 재생 지원)
  try {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.game,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
    ));
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
