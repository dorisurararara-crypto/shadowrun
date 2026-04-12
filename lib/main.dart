import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/ad_service.dart';
import 'core/services/purchase_service.dart';
import 'core/l10n/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: SRColors.background,
  ));

  try {
    await FlutterNaverMap().init(
      clientId: 'eilr4xtzsr',
      onAuthFailed: (ex) => debugPrint('네이버맵 인증 실패: $ex'),
    );
  } catch (e) {
    debugPrint('네이버맵 초기화 실패: $e');
  }

  await AdService().initialize();
  await PurchaseService().initialize();

  final langSelected = await isLanguageSelected();

  if (langSelected) {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language') ?? 'en';
    await S.init(langCode);
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
