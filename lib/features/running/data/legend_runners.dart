import 'package:shadowrun/core/l10n/app_strings.dart';

/// 전설의 마라토너 한 명의 데이터.
///
/// 러닝 시작 시각 t=0, 경과 초 × 페이스로 가상 러너의 현재 거리를 계산.
/// 사용자 거리와 비교해 "N km 뒤/앞" 음성·햅틱 안내.
class LegendRunner {
  final String id;
  final String nameKo;
  final String nameEn;
  final String flag; // 국기 이모지
  final Duration marathonTime; // 42.195km 완주 시간
  final double paceSecPerKm; // 초/km
  final String bioKo;
  final String bioEn;
  final bool isProOnly;

  const LegendRunner({
    required this.id,
    required this.nameKo,
    required this.nameEn,
    required this.flag,
    required this.marathonTime,
    required this.paceSecPerKm,
    required this.bioKo,
    required this.bioEn,
    this.isProOnly = false,
  });

  String get displayName => S.isKo ? nameKo : nameEn;
  String get bio => S.isKo ? bioKo : bioEn;

  /// "2:52/km" 형식
  String get paceLabel {
    final m = paceSecPerKm ~/ 60;
    final s = (paceSecPerKm % 60).round();
    return "$m'${s.toString().padLeft(2, '0')}\"/km";
  }

  /// "2:01:09" 형식
  String get recordLabel {
    final h = marathonTime.inHours;
    final m = marathonTime.inMinutes.remainder(60);
    final s = marathonTime.inSeconds.remainder(60);
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// 경과 초 기준 가상 러너의 현재 거리(km)
  double virtualDistanceKmAt(int elapsedSeconds) {
    if (elapsedSeconds <= 0) return 0.0;
    return elapsedSeconds / paceSecPerKm;
  }
}

class LegendRunners {
  LegendRunners._();

  /// 전체 전설 목록. 사용자 레벨(페이스 4'/km ~ 7'/km)에 따라 다양하게.
  static const List<LegendRunner> all = [
    // 세계 기록 보유자 (킵초게)
    LegendRunner(
      id: 'kipchoge',
      nameKo: '엘리우드 킵초게',
      nameEn: 'Eliud Kipchoge',
      flag: '🇰🇪',
      marathonTime: Duration(hours: 2, minutes: 1, seconds: 9),
      paceSecPerKm: 172, // 2:52/km
      bioKo: '세계 기록 · 베를린 2022 · "No human is limited"',
      bioEn: 'World record · Berlin 2022 · "No human is limited"',
    ),

    // 한국 남성 전설
    LegendRunner(
      id: 'lee_bongju',
      nameKo: '이봉주',
      nameEn: 'Lee Bong-ju',
      flag: '🇰🇷',
      marathonTime: Duration(hours: 2, minutes: 7, seconds: 20),
      paceSecPerKm: 181, // 3:01/km
      bioKo: '2001 보스턴 우승 · 한국 기록 보유자',
      bioEn: 'Boston 2001 winner · Korean record holder',
    ),
    LegendRunner(
      id: 'hwang_youngjo',
      nameKo: '황영조',
      nameEn: 'Hwang Young-jo',
      flag: '🇰🇷',
      marathonTime: Duration(hours: 2, minutes: 13, seconds: 23),
      paceSecPerKm: 190, // 3:10/km
      bioKo: '1992 바르셀로나 올림픽 금메달',
      bioEn: 'Barcelona 1992 Olympic gold',
    ),

    // 세계 여성 기록 (코스게이)
    LegendRunner(
      id: 'kosgei',
      nameKo: '브리짓 코스게이',
      nameEn: 'Brigid Kosgei',
      flag: '🇰🇪',
      marathonTime: Duration(hours: 2, minutes: 14, seconds: 4),
      paceSecPerKm: 191, // 3:10/km
      bioKo: '여성 세계 기록 · 시카고 2019',
      bioEn: "Women's world record · Chicago 2019",
    ),

    // 한국 여성 전설
    LegendRunner(
      id: 'jin_sunhee',
      nameKo: '진선희',
      nameEn: 'Jin Sun-hee',
      flag: '🇰🇷',
      marathonTime: Duration(hours: 2, minutes: 29, seconds: 15),
      paceSecPerKm: 212, // 3:32/km
      bioKo: '한국 여성 기록 2010',
      bioEn: 'Korean women record 2010',
    ),

    // 서브3 아마추어 (일반 엘리트 목표)
    LegendRunner(
      id: 'sub3',
      nameKo: '서브3 마스터',
      nameEn: 'Sub-3 Master',
      flag: '🏃',
      marathonTime: Duration(hours: 3),
      paceSecPerKm: 256, // 4:16/km
      bioKo: '아마추어 러너의 정상 · 3시간 이내 완주',
      bioEn: "Amateur's summit · finish under 3 hours",
    ),

    // 서브4 (보통 엘리트 목표)
    LegendRunner(
      id: 'sub4',
      nameKo: '서브4 러너',
      nameEn: 'Sub-4 Runner',
      flag: '🏃',
      marathonTime: Duration(hours: 4),
      paceSecPerKm: 341, // 5:41/km
      bioKo: '풀코스 완주러의 표준 · 4시간 이내',
      bioEn: 'Marathon finisher standard · under 4 hours',
    ),

    // 초심자 페이서 (6분대)
    LegendRunner(
      id: 'starter',
      nameKo: '러닝 입문자',
      nameEn: 'First-timer',
      flag: '🌱',
      marathonTime: Duration(hours: 4, minutes: 30),
      paceSecPerKm: 384, // 6:24/km
      bioKo: '처음 달리는 당신의 속도 · 완주가 목표',
      bioEn: 'Your first run · finishing is the goal',
    ),
  ];

  static LegendRunner? byId(String id) {
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }
}
