import 'dart:math';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/core/database/database_helper.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

class CoachingAnalysis {
  final String title;
  final String body;
  final String emoji;
  final String category; // pace, distance, consistency, improvement, tip

  CoachingAnalysis({
    required this.title,
    required this.body,
    required this.emoji,
    required this.category,
  });
}

class CoachingService {
  static final _rng = Random();

  /// 러닝 결과 분석 → 코칭 피드백 리스트 생성
  static Future<List<CoachingAnalysis>> analyze(RunModel currentRun) async {
    final results = <CoachingAnalysis>[];
    final allRuns = await DatabaseHelper.getAllRuns();

    // 현재 런 제외한 이전 기록들
    final prevRuns = allRuns.where((r) => r.id != currentRun.id).toList();

    // 1. 첫 러닝 vs N번째
    results.add(_analyzeRunCount(prevRuns.length + 1));

    // 2. 페이스 비교
    if (prevRuns.isNotEmpty && currentRun.avgPace > 0) {
      final paceAnalysis = _analyzePace(currentRun, prevRuns);
      if (paceAnalysis != null) results.add(paceAnalysis);
    }

    // 3. 거리 비교
    if (prevRuns.isNotEmpty) {
      final distAnalysis = _analyzeDistance(currentRun, prevRuns);
      if (distAnalysis != null) results.add(distAnalysis);
    }

    // 4. 시간 비교
    if (prevRuns.isNotEmpty) {
      final durAnalysis = _analyzeDuration(currentRun, prevRuns);
      if (durAnalysis != null) results.add(durAnalysis);
    }

    // 5. 연속 러닝 체크
    final streakAnalysis = await _analyzeStreak(allRuns);
    if (streakAnalysis != null) results.add(streakAnalysis);

    // 6. 개인 최고 기록 체크
    final prAnalysis = _analyzePersonalRecord(currentRun, prevRuns);
    if (prAnalysis != null) results.add(prAnalysis);

    // 7. 러닝 팁 (매번 랜덤 1개)
    results.add(_getRandomTip());

    return results;
  }

  // === 1. 러닝 횟수 ===
  static CoachingAnalysis _analyzeRunCount(int count) {
    if (count == 1) {
      return CoachingAnalysis(
        title: S.isKo ? '첫 번째 러닝!' : 'First Run!',
        body: S.isKo
            ? '축하합니다! 첫 러닝을 완료했습니다. 모든 여정은 첫 걸음에서 시작됩니다. 다음 목표는 이번 주 안에 한 번 더 뛰는 것입니다.'
            : 'Congratulations! You completed your first run. Every journey starts with a single step. Your next goal: run once more this week.',
        emoji: '🎉',
        category: 'milestone',
      );
    } else if (count <= 5) {
      return CoachingAnalysis(
        title: S.isKo ? '$count번째 러닝' : 'Run #$count',
        body: S.isKo
            ? '습관이 만들어지고 있습니다. 연구에 따르면 21일간 반복하면 습관이 됩니다. 계속 이어가세요!'
            : 'A habit is forming. Studies show 21 days of repetition creates a habit. Keep it going!',
        emoji: '🔥',
        category: 'milestone',
      );
    } else if (count == 10) {
      return CoachingAnalysis(
        title: S.isKo ? '10회 달성!' : '10 Runs!',
        body: S.isKo
            ? '10번의 러닝을 완료했습니다. 이제 당신은 러너입니다. 자신감을 가지세요.'
            : 'You have completed 10 runs. You are a runner now. Own it.',
        emoji: '🏆',
        category: 'milestone',
      );
    } else if (count % 50 == 0) {
      return CoachingAnalysis(
        title: S.isKo ? '$count회 달성!' : '$count Runs!',
        body: S.isKo
            ? '대단한 꾸준함입니다. $count번의 러닝은 단순한 운동이 아니라 라이프스타일입니다.'
            : 'Incredible consistency. $count runs is not exercise — it is a lifestyle.',
        emoji: '👑',
        category: 'milestone',
      );
    }
    return CoachingAnalysis(
      title: S.isKo ? '$count번째 러닝' : 'Run #$count',
      body: S.isKo ? '꾸준히 달리고 있습니다. 좋은 습관입니다.' : 'Consistent running. Great habit.',
      emoji: '✅',
      category: 'milestone',
    );
  }

  // === 2. 페이스 분석 ===
  static CoachingAnalysis? _analyzePace(RunModel current, List<RunModel> prev) {
    final prevWithPace = prev.where((r) => r.avgPace > 0 && r.avgPace < 30).toList();
    if (prevWithPace.isEmpty) return null;

    final lastPace = prevWithPace.first.avgPace;
    final diff = current.avgPace - lastPace;
    final diffPercent = (diff / lastPace * 100).abs();

    if (diff < -0.3) {
      // 빨라짐
      final secs = (diff.abs() * 60).round();
      return CoachingAnalysis(
        title: S.isKo ? '페이스 향상! 🚀' : 'Pace Improved! 🚀',
        body: S.isKo
            ? '이전보다 km당 $secs초 빨라졌습니다 (${diffPercent.toStringAsFixed(1)}% 향상). ${_getPaceImproveReason()}'
            : 'You are ${secs}s/km faster than last time (${diffPercent.toStringAsFixed(1)}% improvement). ${_getPaceImproveReasonEn()}',
        emoji: '⬆️',
        category: 'pace',
      );
    } else if (diff > 0.3) {
      // 느려짐
      final secs = (diff * 60).round();
      return CoachingAnalysis(
        title: S.isKo ? '페이스 변화 📊' : 'Pace Change 📊',
        body: S.isKo
            ? '이전보다 km당 $secs초 느려졌습니다. ${_getPaceSlowReason()}'
            : 'You are ${secs}s/km slower than last time. ${_getPaceSlowReasonEn()}',
        emoji: '📉',
        category: 'pace',
      );
    } else {
      return CoachingAnalysis(
        title: S.isKo ? '안정적인 페이스 ⚡' : 'Steady Pace ⚡',
        body: S.isKo
            ? '이전과 비슷한 페이스를 유지하고 있습니다. 일관성은 성장의 기반입니다.'
            : 'You are maintaining a consistent pace. Consistency is the foundation of growth.',
        emoji: '⚡',
        category: 'pace',
      );
    }
  }

  static String _getPaceImproveReason() {
    final reasons = [
      '몸이 러닝에 적응하고 있는 증거입니다. 하지만 급격한 페이스업은 부상 위험이 있으니 주당 10% 이내로 늘려가세요.',
      '근지구력이 향상되고 있습니다. 이 페이스를 3회 연속 유지할 수 있다면 다음 단계로 올라갈 준비가 된 겁니다.',
      '좋은 신호입니다. 페이스가 빨라진 만큼 회복 시간도 충분히 가져주세요. 48시간 이상의 휴식을 권장합니다.',
    ];
    return reasons[_rng.nextInt(reasons.length)];
  }

  static String _getPaceImproveReasonEn() {
    final reasons = [
      'Your body is adapting to running. But avoid increasing pace by more than 10% per week to prevent injury.',
      'Your endurance is improving. If you can maintain this pace 3 times in a row, you are ready for the next level.',
      'Good sign. Make sure to rest enough — at least 48 hours between intense runs.',
    ];
    return reasons[_rng.nextInt(reasons.length)];
  }

  static String _getPaceSlowReason() {
    final reasons = [
      '괜찮습니다. 느린 날도 있습니다. 수면 부족, 스트레스, 날씨 등 다양한 요인이 영향을 줍니다. 중요한 건 뛰었다는 것입니다.',
      '페이스가 느려졌다면 몸이 회복을 요구하는 것일 수 있습니다. 무리하지 말고 이 페이스를 유지하는 것도 좋은 전략입니다.',
      '장거리 러닝에서는 페이스보다 꾸준함이 중요합니다. 천천히 달려도 완주하는 사람이 이깁니다.',
      '컨디션이 안 좋은 날에도 뛰러 나왔다는 것 자체가 대단합니다. 이런 날이 진짜 실력을 만듭니다.',
    ];
    return reasons[_rng.nextInt(reasons.length)];
  }

  static String _getPaceSlowReasonEn() {
    final reasons = [
      'That is okay. Slow days happen. Sleep, stress, weather — many factors affect pace. What matters is that you ran.',
      'Your body might be asking for recovery. Maintaining this pace without pushing too hard is a smart strategy.',
      'In distance running, consistency matters more than speed. The one who finishes wins.',
      'Showing up on a bad day is what builds real fitness. These are the runs that count the most.',
    ];
    return reasons[_rng.nextInt(reasons.length)];
  }

  // === 3. 거리 분석 ===
  static CoachingAnalysis? _analyzeDistance(RunModel current, List<RunModel> prev) {
    final lastDist = prev.first.distanceM;
    final diff = current.distanceM - lastDist;

    if (diff > 500) {
      return CoachingAnalysis(
        title: S.isKo ? '거리 증가! 📏' : 'Distance Up! 📏',
        body: S.isKo
            ? '이전보다 ${(diff / 1000).toStringAsFixed(1)}km 더 달렸습니다. 거리를 늘릴 때는 주당 총 거리의 10%를 넘지 않도록 주의하세요.'
            : 'You ran ${(diff / 1000).toStringAsFixed(1)}km more than last time. When increasing distance, don\'t exceed 10% of weekly total.',
        emoji: '📏',
        category: 'distance',
      );
    } else if (diff < -500) {
      return CoachingAnalysis(
        title: S.isKo ? '짧은 러닝 🏃' : 'Short Run 🏃',
        body: S.isKo
            ? '이전보다 짧게 뛰었습니다. 짧은 러닝도 가치가 있습니다. 회복 러닝이나 인터벌 훈련에 적합한 거리입니다.'
            : 'Shorter than last time. Short runs have value too — great for recovery or interval training.',
        emoji: '🏃',
        category: 'distance',
      );
    }
    return null;
  }

  // === 4. 시간 분석 ===
  static CoachingAnalysis? _analyzeDuration(RunModel current, List<RunModel> prev) {
    final lastDur = prev.first.durationS;
    final diff = current.durationS - lastDur;

    if (diff > 300 && current.durationS > 1800) {
      return CoachingAnalysis(
        title: S.isKo ? '장시간 러닝 ⏱️' : 'Long Run ⏱️',
        body: S.isKo
            ? '${(current.durationS / 60).round()}분간 달렸습니다. 30분 이상의 러닝은 심폐 지구력 향상에 효과적입니다. 러닝 후 스트레칭을 잊지 마세요.'
            : '${(current.durationS / 60).round()} minutes of running. Runs over 30 minutes effectively improve cardiovascular endurance. Don\'t forget to stretch.',
        emoji: '⏱️',
        category: 'duration',
      );
    }
    return null;
  }

  // === 5. 연속 러닝 ===
  static Future<CoachingAnalysis?> _analyzeStreak(List<RunModel> allRuns) async {
    if (allRuns.length < 2) return null;

    int streak = 1;
    for (int i = 1; i < allRuns.length; i++) {
      final curr = DateTime.tryParse(allRuns[i - 1].date);
      final prev = DateTime.tryParse(allRuns[i].date);
      if (curr == null || prev == null) break;
      final diff = curr.difference(prev).inDays;
      if (diff <= 2) {
        streak++;
      } else {
        break;
      }
    }

    if (streak >= 7) {
      return CoachingAnalysis(
        title: S.isKo ? '$streak일 연속 러닝! 🔥' : '$streak Day Streak! 🔥',
        body: S.isKo
            ? '놀랍습니다. $streak일 연속으로 달리고 있습니다. 하지만 휴식도 훈련의 일부입니다. 주 1~2일은 쉬어주세요.'
            : 'Amazing. $streak consecutive days of running. But rest is part of training too. Take 1-2 days off per week.',
        emoji: '🔥',
        category: 'consistency',
      );
    } else if (streak >= 3) {
      return CoachingAnalysis(
        title: S.isKo ? '$streak일 연속!' : '$streak Day Streak!',
        body: S.isKo
            ? '$streak일 연속 러닝 중입니다. 좋은 흐름을 타고 있습니다. 이 모멘텀을 유지하세요.'
            : '$streak days in a row. You are on a roll. Keep this momentum going.',
        emoji: '💪',
        category: 'consistency',
      );
    }
    return null;
  }

  // === 6. 개인 최고 기록 ===
  static CoachingAnalysis? _analyzePersonalRecord(RunModel current, List<RunModel> prev) {
    if (prev.isEmpty) return null;

    // 최장 거리
    final maxDist = prev.map((r) => r.distanceM).reduce((a, b) => a > b ? a : b);
    if (current.distanceM > maxDist && current.distanceM > 500) {
      return CoachingAnalysis(
        title: S.isKo ? '🏅 최장 거리 신기록!' : '🏅 Distance PR!',
        body: S.isKo
            ? '역대 최장 거리를 달성했습니다! ${(current.distanceM / 1000).toStringAsFixed(2)}km. 이전 기록 ${(maxDist / 1000).toStringAsFixed(2)}km를 넘었습니다.'
            : 'New distance personal record! ${(current.distanceM / 1000).toStringAsFixed(2)}km, beating your previous ${(maxDist / 1000).toStringAsFixed(2)}km.',
        emoji: '🏅',
        category: 'improvement',
      );
    }

    // 최고 페이스 (낮을수록 빠름)
    final bestPace = prev.where((r) => r.avgPace > 0 && r.avgPace < 30).map((r) => r.avgPace).fold(double.infinity, (a, b) => a < b ? a : b);
    if (current.avgPace > 0 && current.avgPace < bestPace && current.distanceM > 500) {
      return CoachingAnalysis(
        title: S.isKo ? '🏅 최고 페이스 신기록!' : '🏅 Pace PR!',
        body: S.isKo
            ? '역대 가장 빠른 페이스입니다! ${_formatPace(current.avgPace)}. 이전 최고 ${_formatPace(bestPace)}를 경신했습니다.'
            : 'Fastest pace ever! ${_formatPace(current.avgPace)}, beating your previous best of ${_formatPace(bestPace)}.',
        emoji: '🏅',
        category: 'improvement',
      );
    }

    return null;
  }

  static String _formatPace(double pace) {
    final min = pace.floor();
    final sec = ((pace - min) * 60).round();
    return "$min'${sec.toString().padLeft(2, '0')}\"/km";
  }

  // === 7. 랜덤 팁 ===
  static CoachingAnalysis _getRandomTip() {
    final tips = S.isKo ? _tipsKo : _tipsEn;
    final tip = tips[_rng.nextInt(tips.length)];
    return CoachingAnalysis(
      title: S.isKo ? '코치의 한마디 💡' : 'Coach\'s Tip 💡',
      body: tip,
      emoji: '💡',
      category: 'tip',
    );
  }

  static const _tipsKo = [
    '러닝 전 동적 스트레칭 5분이 부상 위험을 40%까지 줄여줍니다. 런지, 레그스윙, 하이니가 효과적입니다.',
    '러닝 후 30분 이내에 탄수화물과 단백질을 섭취하면 근육 회복이 빨라집니다. 바나나+프로틴이 가장 간편합니다.',
    '같은 신발을 600~800km 이상 신으면 쿠셔닝이 70% 이상 소실됩니다. 신발 교체 시기를 확인하세요.',
    '러닝 중 옆구리 통증이 나타나면 숨을 깊게 내쉬면서 통증 쪽 팔을 올려 스트레칭하세요.',
    '아침 공복 러닝은 지방 연소에 효과적이지만, 30분 이상은 저혈당 위험이 있습니다. 물 한 잔은 꼭 마시세요.',
    '심박수 기반 훈련에서 최대 심박수의 60~70%가 지방 연소 구간, 70~80%가 유산소 능력 향상 구간입니다.',
    '비 오는 날 러닝은 체온 조절에 유리하고 관절에 충격이 적습니다. 미끄러운 바닥만 조심하세요.',
    '주 3회 러닝 + 주 1회 근력 운동이 가장 효율적인 조합입니다. 스쿼트와 런지가 러닝 근력에 직결됩니다.',
    '러닝 후 얼음찜질보다 가벼운 조깅(쿨다운)이 회복에 더 효과적입니다. 5분간 걷기로 마무리하세요.',
    '숙면이 러닝 성능에 미치는 영향은 7~15%입니다. 7시간 이상 자는 것이 최고의 보충제입니다.',
    '역풍이 불 때는 몸을 앞으로 살짝 기울이고 보폭을 줄이세요. 바람과 싸우지 말고 같이 가세요.',
    '러닝 중 음악 템포 160~180 BPM이 자연스러운 케이던스와 일치합니다. 빠른 음악이 페이스를 올려줍니다.',
    '인터벌 트레이닝은 같은 시간 대비 2배의 칼로리를 소모합니다. 주 1회 400m x 8회를 추천합니다.',
    '러닝 전 카페인 섭취는 지구력을 3~5% 향상시킵니다. 30~60분 전에 커피 한 잔이 적정량입니다.',
    '러닝 중 어깨가 올라가면 에너지 낭비입니다. 10분마다 어깨를 의식적으로 내려주세요.',
  ];

  static const _tipsEn = [
    'Five minutes of dynamic stretching before running reduces injury risk by 40%. Try lunges, leg swings, and high knees.',
    'Eating carbs and protein within 30 minutes after running speeds up muscle recovery. A banana plus protein shake is the easiest option.',
    'Running shoes lose 70% of cushioning after 600-800km. Check if it is time to replace yours.',
    'If you get a side stitch while running, exhale deeply and stretch the arm on the painful side overhead.',
    'Morning fasted runs are great for fat burning, but over 30 minutes risks low blood sugar. At least drink a glass of water.',
    'In heart rate training, 60-70% of max HR is fat burning zone, 70-80% is aerobic improvement zone.',
    'Running in rain is actually easier on your body — better temperature regulation and less joint impact. Just watch for slippery surfaces.',
    'Three runs per week plus one strength session is the most efficient combo. Squats and lunges directly improve running power.',
    'After running, a light cool-down jog beats ice therapy for recovery. End with 5 minutes of walking.',
    'Sleep affects running performance by 7-15%. Getting 7+ hours is the best supplement available.',
    'Running into headwind? Lean slightly forward and shorten your stride. Work with it, not against it.',
    'Music at 160-180 BPM matches natural running cadence. Faster music naturally increases your pace.',
    'Interval training burns twice the calories in the same time. Try 8 x 400m sprints once a week.',
    'Caffeine before running improves endurance by 3-5%. One coffee 30-60 minutes before is the right amount.',
    'If your shoulders creep up during running, you are wasting energy. Consciously drop them every 10 minutes.',
  ];
}
