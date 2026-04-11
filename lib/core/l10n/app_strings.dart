import 'package:shared_preferences/shared_preferences.dart';

class S {
  static String _lang = 'en';

  static bool get isKo => _lang == 'ko';

  /// Call once at app startup after SharedPreferences is ready.
  static Future<void> init([String? langCode]) async {
    if (langCode != null) {
      _lang = langCode;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString('language') ?? 'en';
  }

  // Home screen
  static String get totalDistance => isKo ? '총 거리' : 'TOTAL DISTANCE';
  static String get totalRuns => isKo ? '총 러닝' : 'TOTAL RUNS';
  static String get record => isKo ? '전적' : 'RECORD';
  static String get streak => isKo ? '연승' : 'STREAK';
  static String get todaysChallenge => isKo ? '오늘의 도전' : "TODAY'S CHALLENGE";
  static String get remaining => isKo ? '남은 횟수' : 'Remaining';
  static String get recentRuns => isKo ? '최근 러닝' : 'RECENT RUNS';
  static String get noRunsYet => isKo ? '아직 러닝 기록이 없어요' : 'No runs yet.';
  static String get wakeUpShadow => isKo ? '그림자를 깨워보세요' : 'Wake up your shadow.';
  static String get newRun => isKo ? '새 러닝' : 'NEW RUN';
  static String get challenge => isKo ? '도전하기' : 'CHALLENGE';
  static String get adPlus1 => isKo ? '광고 +1' : 'AD +1';
  static String get dailyObjective => isKo ? '일일 목표' : 'Daily Objective';

  // Settings screen
  static String get settings => isKo ? '설정' : 'SETTINGS';
  static String get records => isKo ? '기록' : 'RECORDS';
  static String get all => isKo ? '전체' : 'ALL';
  static String get challenges => isKo ? '도전 기록' : 'CHALLENGES';
  static String get runningSettings => isKo ? '러닝 설정' : 'RUNNING SETTINGS';
  static String get horrorSettings => isKo ? '공포 설정' : 'HORROR SETTINGS';
  static String get runMode => isKo ? '러닝 모드' : 'Run Mode';
  static String get fullMap => isKo ? '전체 지도' : 'Full Map';
  static String get mapFocus => isKo ? '지도 중심' : 'Map Focus';
  static String get dataFocus => isKo ? '데이터 중심' : 'Data Focus';
  static String get distanceUnits => isKo ? '거리 단위' : 'Distance Units';
  static String get anxietyLevel => isKo ? '공포 레벨' : 'Anxiety Level';
  static String get entityAudio => isKo ? '그림자 음성 (TTS)' : 'Entity Audio (TTS)';
  static String get entityAudioDesc => isKo ? '러닝 중 뒤에서 속삭임' : 'Whispers behind you during run';
  static String get hapticDread => isKo ? '촉각 공포' : 'Haptic Dread';
  static String get hapticDreadDesc => isKo ? '손목에서 심장 박동 진동' : 'Heartbeat pulses on wrist';
  static String get upgradeToPro => isKo ? 'PRO 업그레이드' : 'UPGRADE TO PRO';
  static String get unlockUltimateTerror => isKo ? '궁극의 공포를 해제하세요' : 'UNLOCK ULTIMATE TERROR';
  static String get restorePurchases => isKo ? '구매 복원' : 'RESTORE PURCHASES';
  static String get proActivated => isKo ? 'PRO 활성화됨' : 'PRO ACTIVATED';

  // Prepare / Running
  static String get prepare => isKo ? '준비' : 'PREPARE';
  static String get start => isKo ? '시작' : 'START';
  static String get gpsSignalGood => isKo ? 'GPS 신호 양호' : 'GPS SIGNAL GOOD';
  static String get searching => isKo ? '검색 중...' : 'SEARCHING...';
  static String get shadowChallenge => isKo ? '그림자 도전' : 'SHADOW CHALLENGE';

  // Result screen
  static String get debrief => isKo ? '결과 보고' : 'DEBRIEF';
  static String get runStatus => isKo ? '러닝 상태' : 'RUN STATUS';
  static String get survived => isKo ? '생존' : 'SURVIVED';
  static String get caught => isKo ? '잡힘' : 'CAUGHT';
  static String get complete => isKo ? '완료' : 'COMPLETE';
  static String get distance => isKo ? '거리' : 'Distance';
  static String get duration => isKo ? '시간' : 'Duration';
  static String get avgPace => isKo ? '평균 페이스' : 'Avg Pace';
  static String get calories => isKo ? '칼로리' : 'Calories';
  static String get share => isKo ? '공유' : 'SHARE';
  static String get home => isKo ? '홈' : 'HOME';
  static String get threatLevel => isKo ? '위협 레벨' : 'THREAT LEVEL';
  static String get proximity => isKo ? '근접도' : 'PROXIMITY';

  // Stop dialog
  static String get stopRunTitle => isKo ? '러닝 종료' : 'Stop Run';
  static String get stopRunMessage => isKo ? '정말 러닝을 종료하시겠습니까?' : 'Are you sure you want to stop?';
  static String get keepRunning => isKo ? '계속 뛰기' : 'Keep Running';
  static String get stop => isKo ? '종료' : 'Stop';
}
