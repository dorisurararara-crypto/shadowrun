import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class S {
  static String _lang = 'en';
  static final ValueNotifier<String> languageNotifier = ValueNotifier('en');

  static bool get isKo => _lang == 'ko';

  /// Call once at app startup after SharedPreferences is ready.
  static Future<void> init([String? langCode]) async {
    if (langCode != null) {
      _lang = langCode;
      languageNotifier.value = langCode;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString('language') ?? 'en';
    languageNotifier.value = _lang;
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
  static String get shadowChallenge => isKo ? '도플갱어 추격' : 'SHADOW CHASE';
  static String get vehiclePaused => isKo ? '차량 이동이 감지되어 일시정지합니다' : 'Vehicle detected. Run paused.';

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

  // Running screen HUD
  static String get pace => isKo ? '페이스' : 'PACE';
  static String get dist => isKo ? '거리' : 'DIST';
  static String get shadow => isKo ? '그림자' : 'SHADOW';

  // Result screen
  static String get visualReconstruction => isKo ? '경로 재구성' : 'VISUAL RECONSTRUCTION';
  static String get incidentReport => isKo ? '인시던트 리포트' : 'INCIDENT REPORT';
  static String get threatDetected => isKo ? '위협 감지' : 'Threat Detected';

  // Prepare screen
  static String get shadowRunStats => isKo ? '그림자 기록' : 'SHADOW RUN STATS';
  static String get date => isKo ? '날짜' : 'DATE';

  // History screen
  static String get noRunsEmpty => isKo ? '아직 러닝 기록이 없어요' : 'No runs yet.';
  static String get noChallengesEmpty => isKo ? '아직 도전 기록이 없어요' : 'No challenge records yet.';
  static String get noChallengesSubtitle => isKo ? '도전을 시작해 결과를 확인하세요' : 'Take on a challenge to see results here.';
  static String get deleteRecord => isKo ? '기록 삭제' : 'Delete Record';
  static String get deleteRecordMessage => isKo ? '이 러닝 기록이 영구적으로 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.' : 'This run record will be permanently deleted.\nThis action cannot be undone.';
  static String get cancel => isKo ? '취소' : 'CANCEL';
  static String get delete => isKo ? '삭제' : 'DELETE';
  static String get viewAll => isKo ? '전체 보기' : 'VIEW ALL';
  static String get dailyLimitReached => isKo ? '일일 도전 횟수를 초과했습니다' : 'Daily challenge limit reached';
  static String get win => isKo ? '승리' : 'WIN';
  static String get lose => isKo ? '패배' : 'LOSE';

  // Speed validation
  static String get tooSlow => isKo ? '너무 느려요! 뛰세요!' : 'Too slow! Start running!';
  static String get tooFast => isKo ? '너무 빨라요! 차량 감지' : 'Too fast! Vehicle detected';

  // PRO features
  static String get proBanner => isKo ? '평생 광고 없이 + 공포 풀해금' : 'No ads forever + Full horror unlock';
  static String get proNoAds => isKo ? 'PRO 유저는 광고가 표시되지 않습니다' : 'PRO users see no ads';
  static String get proModeLockedTitle => isKo ? 'PRO 전용 모드' : 'PRO MODE';
  static String get proModeLockedMsg => isKo
      ? '지도 중심, 데이터 중심 모드는 PRO 전용입니다.\n업그레이드하여 모든 모드를 잠금 해제하세요.'
      : 'Map Focus and Data Focus modes require PRO.\nUpgrade to unlock all modes.';
  static String get proBenefitNoAds => isKo ? '영구 광고 제거' : 'Remove ads forever';
  static String get proBenefitHorror => isKo ? '공포 레벨 3~5 해금' : 'Unlock horror levels 3-5';
  static String get proBenefitModes => isKo ? '모든 러닝 모드 해금' : 'Unlock all running modes';
  static String get proBenefitVoice => isKo ? '공포 음성 선택 (3종)' : 'Horror voice selection (3 voices)';
  static String get voiceSelection => isKo ? '음성 선택' : 'Voice Selection';
  static String get voiceHarry => 'Harry — Fierce Warrior';
  static String get voiceCallum => 'Callum — Calm Operator';
  static String get voiceDrill => 'Drill Sergeant — Commander';
  static String get comingSoon => isKo ? '출시 예정' : 'COMING SOON';
  static String get upgrade => isKo ? '업그레이드' : 'UPGRADE';
  static String get shadowSpeed => isKo ? '그림자 속도' : 'Shadow Speed';
  static String get shadowSpeedDesc => isKo ? '도플갱어의 추격 속도를 조절합니다' : 'Adjust the doppelganger chase speed';
  static String get slow => isKo ? '느림' : 'Slow';
  static String get normal => isKo ? '보통' : 'Normal';
  static String get fast => isKo ? '빠름' : 'Fast';
  static String get proBenefitSpeed => isKo ? '그림자 속도 조절' : 'Shadow speed control';
  static String get freeTrialBanner => isKo ? '7일 무료체험 중' : '7-DAY FREE TRIAL';
  static String get freeTrialExpired => isKo ? '무료체험이 종료되었습니다' : 'Free trial expired';
  static String get startFreeTrial => isKo ? '7일 무료체험 시작' : 'START 7-DAY FREE TRIAL';
  static String get trialDaysLeft => isKo ? '무료체험 남은 일수' : 'Trial days left';

  // Hardcoded strings (previously Korean-only)
  static String get storeUnavailable => isKo ? '스토어에 연결할 수 없습니다' : 'Store unavailable';
  static String get restoreTrying => isKo ? '구매 복원을 시도합니다...' : 'Restoring purchases...';
  static String get enterAdminKey => isKo ? '관리자 키를 입력하세요' : 'Enter admin key';
  static String get proActivatedMsg => isKo ? 'PRO 활성화 완료!' : 'PRO activated!';
  static String get wrongKey => isKo ? '잘못된 키입니다' : 'Wrong key';
  static String get adLoading => isKo ? '광고를 불러오는 중입니다. 잠시 후 다시 시도해주세요.' : 'Loading ad. Please try again.';
  static String get runTooShort => isKo ? '기록이 너무 짧아 저장되지 않았습니다' : 'Run too short to save';
  static String get gpsRequired => isKo ? 'GPS 권한이 필요합니다' : 'GPS permission required';
  static String get unlimited => isKo ? '무제한' : 'Unlimited';

  // Running mode selection
  static String get selectRunMode => isKo ? '러닝 모드 선택' : 'SELECT MODE';
  static String get modeDoppelganger => isKo ? '도플갱어' : 'DOPPELGANGER';
  static String get modeMarathoner => isKo ? '전설의 마라토너' : 'LEGENDARY MARATHONER';
  static String get modeFreeRun => isKo ? '자유 러닝' : 'FREE RUN';
  static String get modeDoppelgangerDesc => isKo ? '과거의 나와 대결' : 'Race your past self';
  static String get modeMarathonerDesc => isKo ? '코치와 함께 달리기' : 'Run with a coach';
  static String get modeFreeRunDesc => isKo ? '자유롭게 기록만' : 'Just run and record';
  static String get stadiumFinale => isKo ? '스타디움 피날레' : 'Stadium Finale';
  static String get stadiumFinaleDesc => isKo ? '종료 직전 관중 함성' : 'Crowd cheering near finish';
  static String get tooFarFromStart => isKo ? '기록한 장소 근처에서 시작해주세요 (200m 이내)' : 'Please start near the recorded location (within 200m)';
  static String get defeated => isKo ? '패배했습니다' : 'You lost';
  static String get voiceOnlyMode => isKo ? '음성 모드' : 'VOICE MODE';
  static String get voiceOnlyDesc => isKo ? '다른 장소 — 음성으로만 제어됩니다' : 'Different location — voice only';
  static String get runLocation => isKo ? '도전 장소' : 'CHALLENGE LOCATION';
  static String get sameLocation => isKo ? '같은 위치에서 뛰기' : 'Run at same location';
  static String get sameLocationDesc => isKo ? '지도에서 도플갱어를 확인할 수 있습니다' : 'See the doppelganger on the map';
  static String get differentLocation => isKo ? '다른 위치에서 뛰기' : 'Run at different location';
  static String get differentLocationDesc => isKo ? '음성으로만 도플갱어와 대결합니다' : 'Voice-only doppelganger challenge';
}
