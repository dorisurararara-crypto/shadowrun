import 'dart:math';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/core/database/database_helper.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

class CoachingAnalysis {
  final String title;
  final String body;
  final String emoji;
  final String category;

  CoachingAnalysis({
    required this.title,
    required this.body,
    required this.emoji,
    required this.category,
  });
}

class CoachingService {
  static final _rng = Random();

  static String _pick(List<String> list) => list[_rng.nextInt(list.length)];

  /// 러닝 결과 분석 → 코칭 피드백 리스트 생성
  static Future<List<CoachingAnalysis>> analyze(RunModel currentRun, {List<RunPoint>? points}) async {
    final results = <CoachingAnalysis>[];
    final allRuns = await DatabaseHelper.getAllRuns();
    final prevRuns = allRuns.where((r) => r.id != currentRun.id).toList();

    // 이번 주/지난 주 기록 분리
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final thisWeekRuns = allRuns.where((r) {
      final d = DateTime.tryParse(r.date);
      return d != null && d.isAfter(weekStart);
    }).toList();
    final lastWeekRuns = allRuns.where((r) {
      final d = DateTime.tryParse(r.date);
      return d != null && d.isAfter(lastWeekStart) && d.isBefore(weekStart);
    }).toList();

    // 1. 러닝 횟수 마일스톤
    results.add(_analyzeRunCount(prevRuns.length + 1));

    // 2. 페이스 분석 (이전 기록 대비)
    if (prevRuns.isNotEmpty && currentRun.avgPace > 0) {
      final r = _analyzePace(currentRun, prevRuns);
      if (r != null) results.add(r);
    }

    // 3. 거리 분석
    if (prevRuns.isNotEmpty) {
      final r = _analyzeDistance(currentRun, prevRuns);
      if (r != null) results.add(r);
    }

    // 4. 거리 마일스톤 (첫 1km, 3km, 5km, 10km 등)
    final r4 = _analyzeDistanceMilestone(currentRun, prevRuns);
    if (r4 != null) results.add(r4);

    // 5. 시간 분석
    if (prevRuns.isNotEmpty) {
      final r = _analyzeDuration(currentRun, prevRuns);
      if (r != null) results.add(r);
    }

    // 6. 주간 비교
    if (lastWeekRuns.isNotEmpty) {
      final r = _analyzeWeekComparison(thisWeekRuns, lastWeekRuns);
      if (r != null) results.add(r);
    }

    // 7. 연속 러닝
    final r7 = _analyzeStreak(allRuns);
    if (r7 != null) results.add(r7);

    // 8. 오랜만에 복귀
    if (prevRuns.isNotEmpty) {
      final r = _analyzeComeback(currentRun, prevRuns);
      if (r != null) results.add(r);
    }

    // 9. 개인 최고 기록
    if (prevRuns.isNotEmpty) {
      final r = _analyzePersonalRecord(currentRun, prevRuns);
      if (r != null) results.add(r);
    }

    // 10. 도플갱어 전적 분석
    if (currentRun.isChallenge) {
      final r = _analyzeDoppelganger(currentRun, prevRuns);
      if (r != null) results.add(r);
    }

    // 11. 칼로리 분석
    if (currentRun.calories > 0) {
      results.add(_analyzeCalories(currentRun));
    }

    // 12. 시간대 분석
    final r12 = _analyzeTimeOfDay(currentRun);
    if (r12 != null) results.add(r12);

    // 13. 스플릿 분석 (어느 구간에서 느려졌는지)
    if (points != null && points.length >= 10 && currentRun.distanceM >= 1000) {
      final r13 = _analyzeSplits(points);
      if (r13 != null) results.add(r13);
    }

    // 14. 랜덤 팁 (매번 다른 것)
    results.add(_getRandomTip());

    return results;
  }

  // ========== 1. 러닝 횟수 ==========
  static CoachingAnalysis _analyzeRunCount(int count) {
    if (count == 1) {
      return CoachingAnalysis(
        title: S.isKo ? '첫 번째 러닝!' : 'First Run!',
        body: _pick(S.isKo ? [
          '축하합니다! 첫 러닝을 완료했습니다. 모든 여정은 첫 걸음에서 시작됩니다. 다음 목표는 이번 주 안에 한 번 더 뛰는 것입니다.',
          '첫 발걸음을 내디뎠습니다! 러닝은 가장 효율적인 운동입니다. 처음이 가장 어렵습니다. 이미 그걸 해냈어요.',
          '당신의 첫 기록이 저장되었습니다. 이 기록이 앞으로 모든 성장의 기준점이 됩니다. 기대되지 않나요?',
        ] : [
          'Congratulations on your first run! Every journey starts with a single step. Next goal: one more this week.',
          'You took the first step! Running is the most efficient exercise. The hardest part is starting. You did it.',
          'Your first record is saved. This will be the baseline for all your growth. Exciting, right?',
        ]),
        emoji: '🎉',
        category: 'milestone',
      );
    } else if (count <= 5) {
      return CoachingAnalysis(
        title: S.isKo ? '$count번째 러닝' : 'Run #$count',
        body: _pick(S.isKo ? [
          '습관이 만들어지고 있습니다. 연구에 따르면 21일간 반복하면 습관이 됩니다.',
          '$count번 달렸습니다. 아직 초반이지만 이미 대부분의 사람들보다 앞서 있습니다.',
          '처음 5번이 가장 중요합니다. 여기서 포기하면 안 됩니다. 계속 가세요.',
        ] : [
          'A habit is forming. Research shows 21 days of repetition creates a habit.',
          '$count runs done. Still early, but you are already ahead of most people.',
          'The first 5 runs matter most. Don\'t quit now. Keep going.',
        ]),
        emoji: '🔥',
        category: 'milestone',
      );
    } else if (count == 10 || count == 20 || count == 30 || count % 50 == 0 || count == 100) {
      return CoachingAnalysis(
        title: S.isKo ? '$count회 달성!' : '$count Runs!',
        body: _pick(S.isKo ? [
          '$count번의 러닝. 이건 단순한 운동이 아니라 라이프스타일입니다.',
          '대단합니다. $count번째 러닝을 완료했습니다. 이 꾸준함이 진짜 실력입니다.',
          '$count회. 숫자가 증명합니다. 당신은 러너입니다.',
        ] : [
          '$count runs. This is not exercise — it is a lifestyle.',
          'Amazing. $count runs completed. This consistency is real strength.',
          '$count runs. The numbers prove it. You are a runner.',
        ]),
        emoji: count >= 50 ? '👑' : '🏆',
        category: 'milestone',
      );
    }
    return CoachingAnalysis(
      title: S.isKo ? '$count번째 러닝' : 'Run #$count',
      body: S.isKo ? '꾸준히 달리고 있습니다.' : 'Consistent running.',
      emoji: '✅',
      category: 'milestone',
    );
  }

  // ========== 2. 페이스 분석 ==========
  static CoachingAnalysis? _analyzePace(RunModel current, List<RunModel> prev) {
    final prevWithPace = prev.where((r) => r.avgPace > 0 && r.avgPace < 30).toList();
    if (prevWithPace.isEmpty) return null;

    final lastPace = prevWithPace.first.avgPace;
    final diff = current.avgPace - lastPace;
    final secs = (diff.abs() * 60).round();
    final pct = (diff / lastPace * 100).abs().toStringAsFixed(1);


    if (diff < -0.3) {
      return CoachingAnalysis(
        title: S.isKo ? '페이스 향상!' : 'Pace Improved!',
        body: _pick(S.isKo ? [
          '이전보다 km당 $secs초 빨라졌습니다 ($pct% 향상). 몸이 러닝에 적응하고 있습니다. 하지만 급격한 페이스업은 부상 위험이 있으니 주당 10% 이내로 늘려가세요.',
          'km당 $secs초 단축! 근지구력이 향상되고 있습니다. 이 페이스를 3회 연속 유지할 수 있다면 다음 단계로 올라갈 준비가 된 겁니다.',
          '$secs초/km 빨라졌습니다. 좋은 신호입니다. 페이스가 빨라진 만큼 회복 시간도 충분히 가져주세요.',
          '이전 기록 대비 $pct% 향상. 체력이 올라가고 있다는 확실한 증거입니다. 이 추세를 유지하세요.',
          '놀라운 발전입니다! $secs초/km 개선. 수면과 영양도 잘 관리하면 이 성장세를 더 오래 유지할 수 있습니다.',
          'km당 $secs초 빨라졌어요. 혹시 오늘 컨디션이 좋았나요? 컨디션이 좋을 때의 습관을 기억해두세요.',
        ] : [
          '$secs seconds per km faster ($pct% improvement). Your body is adapting. But avoid increasing pace by more than 10% per week.',
          '$secs s/km faster! Endurance improving. If you can maintain this pace 3 times in a row, you are ready for the next level.',
          '$secs s/km faster. Good sign. Make sure to rest enough after pace improvements.',
          '$pct% improvement over last run. Clear evidence your fitness is growing.',
          'Impressive! $secs s/km improvement. Good sleep and nutrition will sustain this growth.',
          '$secs s/km faster. Was today a good day? Remember what you did differently.',
        ]),
        emoji: '🚀',
        category: 'pace',
      );
    } else if (diff > 0.3) {
      return CoachingAnalysis(
        title: S.isKo ? '페이스 변화' : 'Pace Change',
        body: _pick(S.isKo ? [
          '이전보다 km당 $secs초 느려졌습니다. 괜찮습니다. 수면 부족, 스트레스, 날씨 등 다양한 요인이 영향을 줍니다. 중요한 건 뛰었다는 것입니다.',
          '페이스가 느려졌지만 걱정 마세요. 장거리 러닝에서는 페이스보다 꾸준함이 중요합니다.',
          '$secs초/km 느려졌습니다. 몸이 회복을 요구하는 것일 수 있습니다. 무리하지 말고 이 페이스를 유지하는 것도 전략입니다.',
          '컨디션이 안 좋은 날에도 뛰러 나왔다는 것 자체가 대단합니다. 이런 날이 진짜 실력을 만듭니다.',
          '오늘은 좀 느렸지만, 모든 프로 선수도 느린 날이 있습니다. 회복 러닝이라고 생각하세요.',
          '느린 러닝도 가치가 있습니다. 천천히 달리면 지방 연소 비율이 높아지고 기초 체력이 쌓입니다.',
          '$secs초 차이는 크지 않습니다. 일주일 평균으로 보면 여전히 좋은 흐름입니다.',
        ] : [
          '$secs s/km slower. That is okay. Sleep, stress, weather — many factors affect pace. What matters is you ran.',
          'Pace dropped but don\'t worry. Consistency matters more than speed in distance running.',
          '$secs s/km slower. Your body might need recovery. Maintaining this pace is a smart strategy.',
          'Showing up on a bad day builds real fitness. These runs count the most.',
          'Slower today, but every pro athlete has slow days too. Think of it as a recovery run.',
          'Slow runs have value. Lower pace means higher fat burn ratio and base fitness building.',
          '$secs second difference is not big. Your weekly average is still on track.',
        ]),
        emoji: '📊',
        category: 'pace',
      );
    } else {
      return CoachingAnalysis(
        title: S.isKo ? '안정적인 페이스' : 'Steady Pace',
        body: _pick(S.isKo ? [
          '이전과 비슷한 페이스를 유지하고 있습니다. 일관성은 성장의 기반입니다.',
          '페이스가 안정적입니다. 이제 이 페이스를 더 긴 거리에서도 유지할 수 있는지 도전해보세요.',
          '흔들리지 않는 페이스. 이게 실력입니다. 편안한 페이스에서 거리를 늘려보세요.',
        ] : [
          'Consistent pace. This stability is the foundation of growth.',
          'Stable pace. Try maintaining it over a longer distance.',
          'Unwavering pace. This is real skill. Try extending your distance at this comfortable pace.',
        ]),
        emoji: '⚡',
        category: 'pace',
      );
    }
  }

  // ========== 3. 거리 분석 ==========
  static CoachingAnalysis? _analyzeDistance(RunModel current, List<RunModel> prev) {
    final lastDist = prev.first.distanceM;
    final diff = current.distanceM - lastDist;

    if (diff > 500) {
      final km = (diff / 1000).toStringAsFixed(1);
      return CoachingAnalysis(
        title: S.isKo ? '거리 증가!' : 'Distance Up!',
        body: _pick(S.isKo ? [
          '이전보다 ${km}km 더 달렸습니다. 거리를 늘릴 때는 주당 총 거리의 10%를 넘지 않도록 주의하세요.',
          '${km}km 더 뛰었네요! 점진적으로 거리를 늘리는 건 체력 성장의 핵심입니다.',
          '거리가 늘었습니다. 더 먼 거리를 뛸수록 심폐 능력과 정신력이 함께 성장합니다.',
        ] : [
          '${km}km more than last time. Don\'t exceed 10% weekly distance increase.',
          '${km}km further! Gradually increasing distance is key to fitness growth.',
          'Distance increased. Longer runs build both cardiovascular and mental strength.',
        ]),
        emoji: '📏',
        category: 'distance',
      );
    } else if (diff < -500) {
      return CoachingAnalysis(
        title: S.isKo ? '짧은 러닝' : 'Short Run',
        body: _pick(S.isKo ? [
          '짧은 러닝도 가치가 있습니다. 회복 러닝이나 인터벌 훈련에 적합한 거리입니다.',
          '오늘은 짧게 뛰었지만, 짧은 러닝은 속도 훈련에 최적입니다.',
          '거리보다 뛰었다는 사실이 중요합니다. 10분짜리 러닝도 안 뛴 사람보다 100% 낫습니다.',
        ] : [
          'Short runs have value. Great for recovery or interval training.',
          'Shorter today, but short runs are optimal for speed training.',
          'The act of running matters more than distance. A 10-minute run beats skipping entirely.',
        ]),
        emoji: '🏃',
        category: 'distance',
      );
    }
    return null;
  }

  // ========== 4. 거리 마일스톤 ==========
  static CoachingAnalysis? _analyzeDistanceMilestone(RunModel current, List<RunModel> prev) {
    final currentKm = (current.distanceM / 1000).floor();
    if (currentKm < 1) return null;
    final prevMaxKm = prev.isEmpty ? 0 : prev.map((r) => (r.distanceM / 1000).floor()).reduce((a, b) => a > b ? a : b);

    final milestones = [1, 2, 3, 5, 7, 10, 15, 20, 30, 42];
    for (final m in milestones) {
      if (currentKm >= m && prevMaxKm < m) {
        return CoachingAnalysis(
          title: S.isKo ? '${m}km 돌파!' : '${m}km Achieved!',
          body: _pick(S.isKo ? [
            '처음으로 ${m}km를 달성했습니다! 새로운 영역에 도달했어요.',
            '${m}km 완주! 이 거리를 뛸 수 있다는 건 당신의 체력이 성장했다는 증거입니다.',
            '축하합니다! ${m}km는 중요한 마일스톤입니다. 다음 목표를 세워보세요.',
          ] : [
            'First time reaching ${m}km! You have entered new territory.',
            '${m}km completed! This distance proves your fitness has grown.',
            'Congratulations! ${m}km is a major milestone. Set your next goal.',
          ]),
          emoji: '🎯',
          category: 'milestone',
        );
      }
    }
    return null;
  }

  // ========== 5. 시간 분석 ==========
  static CoachingAnalysis? _analyzeDuration(RunModel current, List<RunModel> prev) {
    final min = current.durationS ~/ 60;
    final lastMin = prev.first.durationS ~/ 60;

    if (min >= 30 && lastMin < 30) {
      return CoachingAnalysis(
        title: S.isKo ? '30분 돌파!' : '30 Min Achieved!',
        body: _pick(S.isKo ? [
          '30분 이상 달렸습니다. 이 시간대부터 유산소 운동의 효과가 극대화됩니다.',
          '30분 연속 러닝! 체지방 연소가 본격적으로 시작되는 구간입니다.',
        ] : [
          'Over 30 minutes! This is where aerobic benefits are maximized.',
          '30 minutes continuous running! This is the zone where serious fat burning begins.',
        ]),
        emoji: '⏱️',
        category: 'duration',
      );
    } else if (min >= 60 && lastMin < 60) {
      return CoachingAnalysis(
        title: S.isKo ? '1시간 러닝!' : '1 Hour Run!',
        body: S.isKo
            ? '1시간 동안 달렸습니다. 장거리 러너의 영역에 진입했습니다. 러닝 후 충분한 영양 보충과 스트레칭을 잊지 마세요.'
            : 'One hour of running. You have entered long-distance territory. Don\'t forget proper nutrition and stretching after.',
        emoji: '🕐',
        category: 'duration',
      );
    }
    return null;
  }

  // ========== 6. 주간 비교 ==========
  static CoachingAnalysis? _analyzeWeekComparison(List<RunModel> thisWeek, List<RunModel> lastWeek) {
    final thisTotal = thisWeek.fold<double>(0, (s, r) => s + r.distanceM);
    final lastTotal = lastWeek.fold<double>(0, (s, r) => s + r.distanceM);
    final diff = thisTotal - lastTotal;

    if (diff > 1000) {
      return CoachingAnalysis(
        title: S.isKo ? '이번 주 성장 중!' : 'Weekly Growth!',
        body: _pick(S.isKo ? [
          '이번 주 총 ${(thisTotal / 1000).toStringAsFixed(1)}km, 지난주 대비 ${(diff / 1000).toStringAsFixed(1)}km 증가. 좋은 흐름입니다!',
          '지난주보다 더 많이 달리고 있습니다. 이 추세를 유지하되, 과훈련은 조심하세요.',
          '주간 거리가 늘고 있습니다. 성장하고 있다는 확실한 신호입니다.',
        ] : [
          'This week: ${(thisTotal / 1000).toStringAsFixed(1)}km, ${(diff / 1000).toStringAsFixed(1)}km more than last week. Good trend!',
          'Running more than last week. Keep this trend but watch for overtraining.',
          'Weekly distance is increasing. Clear sign of growth.',
        ]),
        emoji: '📈',
        category: 'weekly',
      );
    } else if (diff < -1000) {
      return CoachingAnalysis(
        title: S.isKo ? '이번 주 회복 중' : 'Recovery Week',
        body: _pick(S.isKo ? [
          '지난주보다 적게 뛰고 있지만, 회복 주간도 훈련의 일부입니다. 4주 중 1주는 가볍게 가는 게 좋습니다.',
          '운동량이 줄었습니다. 의도적인 휴식이라면 좋은 판단입니다. 아니라면 다시 시작할 때입니다.',
        ] : [
          'Running less than last week, but recovery weeks are part of training. Going lighter 1 week out of 4 is smart.',
          'Volume is down. If intentional, good call. If not, it is time to get back on track.',
        ]),
        emoji: '🔄',
        category: 'weekly',
      );
    }
    return null;
  }

  // ========== 7. 연속 러닝 ==========
  static CoachingAnalysis? _analyzeStreak(List<RunModel> allRuns) {
    if (allRuns.length < 2) return null;
    int streak = 1;
    for (int i = 1; i < allRuns.length; i++) {
      final curr = DateTime.tryParse(allRuns[i - 1].date);
      final prev = DateTime.tryParse(allRuns[i].date);
      if (curr == null || prev == null) break;
      if (curr.difference(prev).inDays <= 2) {
        streak++;
      } else {
        break;
      }
    }

    if (streak >= 7) {
      return CoachingAnalysis(
        title: S.isKo ? '$streak일 연속!' : '$streak Day Streak!',
        body: _pick(S.isKo ? [
          '$streak일 연속 러닝! 대단합니다. 하지만 휴식도 훈련입니다. 주 1~2일은 쉬어주세요.',
          '$streak일째 달리고 있습니다. 이 정도면 러닝이 습관이 된 겁니다. 부상 예방을 위해 스트레칭에 신경 쓰세요.',
        ] : [
          '$streak consecutive days! Amazing. But rest is training too. Take 1-2 days off per week.',
          'Day $streak of your streak. Running is a habit now. Focus on stretching to prevent injury.',
        ]),
        emoji: '🔥',
        category: 'consistency',
      );
    } else if (streak >= 3) {
      return CoachingAnalysis(
        title: S.isKo ? '$streak일 연속!' : '$streak Day Streak!',
        body: S.isKo ? '좋은 흐름입니다. 이 모멘텀을 유지하세요.' : 'Good momentum. Keep it going.',
        emoji: '💪',
        category: 'consistency',
      );
    }
    return null;
  }

  // ========== 8. 복귀 분석 ==========
  static CoachingAnalysis? _analyzeComeback(RunModel current, List<RunModel> prev) {
    final lastDate = DateTime.tryParse(prev.first.date);
    final currentDate = DateTime.tryParse(current.date);
    if (lastDate == null || currentDate == null) return null;
    final gap = currentDate.difference(lastDate).inDays;

    if (gap >= 14) {
      return CoachingAnalysis(
        title: S.isKo ? '돌아왔군요!' : 'Welcome Back!',
        body: _pick(S.isKo ? [
          '$gap일 만에 다시 뛰셨네요! 오래 쉬었더라도 괜찮습니다. 중요한 건 다시 시작했다는 것입니다.',
          '$gap일 만의 복귀. 처음 며칠은 체력이 떨어진 느낌이 들겠지만, 1~2주면 원래 체력으로 돌아옵니다.',
          '오랜만이네요! 쉰 기간이 길수록 처음엔 힘들지만, 근육 기억은 사라지지 않습니다. 곧 적응합니다.',
        ] : [
          '$gap days since your last run. No worries — what matters is you started again.',
          'Back after $gap days. First few days might feel tough, but you will recover in 1-2 weeks.',
          'Long time no see! Muscle memory never disappears. You will adapt quickly.',
        ]),
        emoji: '🔙',
        category: 'comeback',
      );
    } else if (gap >= 7) {
      return CoachingAnalysis(
        title: S.isKo ? '일주일 만에!' : 'Back After a Week!',
        body: S.isKo
            ? '$gap일 만에 돌아왔습니다. 이번에는 주 2~3회를 목표로 해보세요.'
            : 'Back after $gap days. Aim for 2-3 runs per week this time.',
        emoji: '👋',
        category: 'comeback',
      );
    }
    return null;
  }

  // ========== 9. 개인 최고 기록 ==========
  static CoachingAnalysis? _analyzePersonalRecord(RunModel current, List<RunModel> prev) {
    final maxDist = prev.map((r) => r.distanceM).reduce((a, b) => a > b ? a : b);
    if (current.distanceM > maxDist && current.distanceM > 500) {
      return CoachingAnalysis(
        title: S.isKo ? '최장 거리 신기록!' : 'Distance PR!',
        body: _pick(S.isKo ? [
          '역대 최장 거리! ${(current.distanceM / 1000).toStringAsFixed(2)}km. 이전 기록 ${(maxDist / 1000).toStringAsFixed(2)}km를 넘었습니다.',
          '새로운 기록! ${(current.distanceM / 1000).toStringAsFixed(2)}km. 이 거리를 한 번 뛸 수 있으면, 다시 뛸 수 있습니다.',
        ] : [
          'New distance PR! ${(current.distanceM / 1000).toStringAsFixed(2)}km, beating ${(maxDist / 1000).toStringAsFixed(2)}km.',
          'Personal record! ${(current.distanceM / 1000).toStringAsFixed(2)}km. If you can run it once, you can run it again.',
        ]),
        emoji: '🏅',
        category: 'improvement',
      );
    }

    final bestPace = prev.where((r) => r.avgPace > 0 && r.avgPace < 30).map((r) => r.avgPace).fold(double.infinity, (a, b) => a < b ? a : b);
    if (current.avgPace > 0 && current.avgPace < bestPace && current.distanceM > 500) {
      return CoachingAnalysis(
        title: S.isKo ? '최고 페이스 신기록!' : 'Pace PR!',
        body: _pick(S.isKo ? [
          '역대 가장 빠른 페이스! ${_formatPace(current.avgPace)}. 이전 ${_formatPace(bestPace)} 경신.',
          '새로운 최고 속도! ${_formatPace(current.avgPace)}로 달렸습니다. 축하합니다!',
        ] : [
          'Fastest pace ever! ${_formatPace(current.avgPace)}, beating ${_formatPace(bestPace)}.',
          'New speed record! ${_formatPace(current.avgPace)}. Congratulations!',
        ]),
        emoji: '🏅',
        category: 'improvement',
      );
    }
    return null;
  }

  // ========== 10. 도플갱어 분석 ==========
  static CoachingAnalysis? _analyzeDoppelganger(RunModel current, List<RunModel> prev) {
    final isWin = current.challengeResult == 'win';
    final challenges = prev.where((r) => r.isChallenge).toList();

    if (isWin) {
      // 연승 계산
      int winStreak = 1;
      for (final r in challenges) {
        if (r.challengeResult == 'win') {
          winStreak++;
        } else {
          break;
        }
      }

      if (winStreak >= 5) {
        return CoachingAnalysis(
          title: S.isKo ? '$winStreak연승!' : '$winStreak Wins in a Row!',
          body: _pick(S.isKo ? [
            '$winStreak연승 중입니다! 도플갱어가 더 이상 위협이 안 되나요? 속도를 올려보세요.',
            '대단한 연승입니다. 하지만 도플갱어는 매번 당신의 최고 기록을 학습합니다. 방심하지 마세요.',
          ] : [
            '$winStreak wins in a row! Is the shadow no longer a threat? Try increasing the speed.',
            'Impressive streak. But the shadow learns from your best records. Stay alert.',
          ]),
          emoji: '👑',
          category: 'doppelganger',
        );
      } else {
        return CoachingAnalysis(
          title: S.isKo ? '도플갱어 승리!' : 'Shadow Defeated!',
          body: _pick(S.isKo ? [
            '그림자를 이겼습니다! 과거의 나보다 강해졌다는 증거입니다.',
            '승리! 하지만 다음번 도플갱어는 오늘의 당신을 기반으로 합니다. 더 빨라질 겁니다.',
            '과거의 나를 넘어섰습니다. 이 기록이 다음 도전의 기준이 됩니다.',
            '도플갱어를 따돌렸습니다! 성장하고 있다는 가장 확실한 증거입니다.',
          ] : [
            'Shadow defeated! Proof that you are stronger than your past self.',
            'Victory! But next time, the shadow will be based on today\'s you. It will be faster.',
            'You surpassed your past self. This record becomes the next challenge.',
            'Escaped the shadow! The clearest evidence of growth.',
          ]),
          emoji: '⚔️',
          category: 'doppelganger',
        );
      }
    } else {
      return CoachingAnalysis(
        title: S.isKo ? '도플갱어에게 패배' : 'Shadow Won',
        body: _pick(S.isKo ? [
          '이번엔 도플갱어가 이겼습니다. 하지만 패배도 데이터입니다. 어디서 속도가 떨어졌는지 분석해보세요.',
          '아쉽지만, 다음에는 이길 수 있습니다. 같은 기록에 다시 도전해보세요.',
          '과거의 나에게 졌습니다. 하지만 여기서 포기하면 진짜 지는 겁니다. 내일 다시 도전하세요.',
          '패배했지만, 이 경험이 다음 승리의 기반이 됩니다. 어느 구간에서 힘들었는지 기억하세요.',
        ] : [
          'The shadow won this time. But defeat is data. Analyze where your pace dropped.',
          'Close, but not this time. Challenge the same record again.',
          'Your past self won. But giving up now is the real loss. Try again tomorrow.',
          'Defeated, but this experience fuels your next victory. Remember which segment was hardest.',
        ]),
        emoji: '💀',
        category: 'doppelganger',
      );
    }
  }

  // ========== 11. 칼로리 분석 ==========
  static CoachingAnalysis _analyzeCalories(RunModel current) {
    final cal = current.calories;
    return CoachingAnalysis(
      title: S.isKo ? '$cal kcal 소모' : '$cal kcal Burned',
      body: _pick(S.isKo ? [
        '${cal}kcal을 소모했습니다. 이건 밥 한 공기(약 300kcal)의 ${(cal / 300 * 100).round()}%에 해당합니다.',
        '${cal}kcal 소모! 러닝은 같은 시간 대비 가장 높은 칼로리를 소모하는 운동입니다.',
        '오늘 ${cal}kcal을 태웠습니다. 꾸준히 달리면 체성분이 변하기 시작합니다.',
      ] : [
        '${cal}kcal burned. That is ${(cal / 300 * 100).round()}% of a bowl of rice (about 300kcal).',
        '${cal}kcal! Running burns the most calories per minute of any exercise.',
        '${cal}kcal burned today. Consistent running will start changing your body composition.',
      ]),
      emoji: '🔥',
      category: 'calories',
    );
  }

  // ========== 12. 랜덤 팁 ==========
  static CoachingAnalysis _getRandomTip() {
    return CoachingAnalysis(
      title: S.isKo ? '코치의 한마디' : 'Coach\'s Tip',
      body: _pick(S.isKo ? _tipsKo : _tipsEn),
      emoji: '💡',
      category: 'tip',
    );
  }

  static String _formatPace(double pace) {
    final min = pace.floor();
    final sec = ((pace - min) * 60).round();
    return "$min'${sec.toString().padLeft(2, '0')}\"/km";
  }

  static const _tipsKo = [
    '러닝 전 동적 스트레칭 5분이 부상 위험을 40%까지 줄여줍니다.',
    '러닝 후 30분 이내에 탄수화물과 단백질을 섭취하면 근육 회복이 빨라집니다.',
    '같은 신발을 600~800km 이상 신으면 쿠셔닝이 70% 이상 소실됩니다.',
    '러닝 중 옆구리 통증이 나타나면 숨을 깊게 내쉬면서 통증 쪽 팔을 올려 스트레칭하세요.',
    '아침 공복 러닝은 지방 연소에 효과적이지만, 30분 이상은 저혈당 위험이 있습니다.',
    '심박수 기반 훈련에서 최대 심박수의 60~70%가 지방 연소 구간입니다.',
    '비 오는 날 러닝은 체온 조절에 유리하고 관절에 충격이 적습니다.',
    '주 3회 러닝 + 주 1회 근력 운동이 가장 효율적인 조합입니다.',
    '러닝 후 가벼운 조깅(쿨다운)이 회복에 효과적입니다. 5분간 걷기로 마무리하세요.',
    '숙면이 러닝 성능에 미치는 영향은 7~15%입니다. 7시간 이상 자는 것이 최고의 보충제입니다.',
    '역풍이 불 때는 몸을 앞으로 살짝 기울이고 보폭을 줄이세요.',
    '러닝 중 음악 템포 160~180 BPM이 자연스러운 케이던스와 일치합니다.',
    '인터벌 트레이닝은 같은 시간 대비 2배의 칼로리를 소모합니다.',
    '러닝 전 카페인 섭취는 지구력을 3~5% 향상시킵니다.',
    '러닝 중 어깨가 올라가면 에너지 낭비입니다. 10분마다 의식적으로 내려주세요.',
    '내리막길에서는 보폭을 줄이고 착지 충격을 최소화하세요. 무릎 부상을 예방합니다.',
    '러닝 후 아이싱보다 냉온 교대욕이 회복에 더 효과적입니다.',
    '새벽 러닝은 대기 오염이 적고 도로가 한산해서 최적의 러닝 시간입니다.',
    '러닝 중 수분 보충은 갈증을 느끼기 전에! 15~20분마다 소량씩 마시세요.',
    '같은 코스만 달리면 몸이 적응합니다. 가끔 새로운 루트를 달려보세요.',
    '러닝 후 바나나 한 개가 전해질 보충에 최고입니다. 칼륨이 풍부합니다.',
    '경사로 훈련은 평지 러닝 대비 근력을 30% 더 키워줍니다.',
    '러닝 일지를 쓰면 동기 부여와 패턴 발견에 큰 도움이 됩니다. 이 앱이 해드리고 있죠!',
    '장거리 러닝 전날 탄수화물을 충분히 섭취하세요. 글리코겐 로딩이 지구력을 높여줍니다.',
    '러닝 후 폼롤러로 허벅지와 종아리를 풀어주면 다음 날 근육통이 줄어듭니다.',
  ];

  static const _tipsEn = [
    'Five minutes of dynamic stretching before running reduces injury risk by 40%.',
    'Eating carbs and protein within 30 minutes after running speeds up recovery.',
    'Running shoes lose 70% cushioning after 600-800km. Time to check yours.',
    'Side stitch? Exhale deeply and stretch the arm on the painful side overhead.',
    'Fasted morning runs burn more fat, but over 30 minutes risks low blood sugar.',
    'In heart rate training, 60-70% max HR is the fat burning zone.',
    'Running in rain is easier on your body — better temperature and less joint impact.',
    'Three runs plus one strength session per week is the most efficient combo.',
    'After running, a light cool-down jog beats ice therapy. End with 5 min of walking.',
    'Sleep affects running performance by 7-15%. 7+ hours is the best supplement.',
    'Headwind? Lean forward slightly and shorten your stride.',
    'Music at 160-180 BPM matches natural running cadence.',
    'Interval training burns twice the calories in the same time.',
    'Caffeine before running improves endurance by 3-5%.',
    'Shoulders creeping up? That wastes energy. Drop them every 10 minutes.',
    'Downhill? Shorten stride and minimize landing impact to protect your knees.',
    'Contrast bathing (hot/cold) is more effective for recovery than icing alone.',
    'Early morning runs have less air pollution and less traffic — optimal conditions.',
    'Hydrate before you feel thirsty. Small sips every 15-20 minutes.',
    'Running the same route? Your body adapts. Try new routes occasionally.',
    'One banana after running is perfect for electrolyte replenishment. Rich in potassium.',
    'Hill training builds 30% more strength than flat running.',
    'Keeping a run journal helps motivation and pattern discovery. This app does it for you!',
    'Load up on carbs the day before a long run. Glycogen loading boosts endurance.',
    'Foam rolling your quads and calves after running reduces next-day soreness.',
  ];

  // ========== 12. 시간대 분석 ==========
  static CoachingAnalysis? _analyzeTimeOfDay(RunModel current) {
    final date = DateTime.tryParse(current.date);
    if (date == null) return null;
    final hour = date.hour;

    if (hour >= 5 && hour < 8) {
      return CoachingAnalysis(
        title: S.isKo ? '새벽 러너!' : 'Early Bird!',
        body: _pick(S.isKo ? [
          '새벽에 뛰었네요! 아침 러닝은 하루 종일 에너지를 높여줍니다. 대기 오염도 적고 도로도 한산합니다.',
          '이른 아침 러닝. 하루를 러닝으로 시작하는 사람은 전체의 상위 3%입니다.',
        ] : [
          'Early morning run! Morning running boosts energy all day with less pollution and traffic.',
          'Starting the day with a run. Only the top 3% do this consistently.',
        ]),
        emoji: '🌅',
        category: 'timeofday',
      );
    } else if (hour >= 21 || hour < 5) {
      return CoachingAnalysis(
        title: S.isKo ? '야간 러닝!' : 'Night Runner!',
        body: _pick(S.isKo ? [
          '밤에 뛰었네요! 야간 러닝은 스트레스 해소에 효과적이지만, 밝은 옷과 반사 장비를 꼭 착용하세요.',
          '야간 러닝. 주변이 어두우니 밝은 색 옷이나 헤드랜턴을 추천합니다. 안전이 최우선!',
        ] : [
          'Night run! Great for stress relief, but wear bright clothes and reflective gear.',
          'Running after dark. Wear bright colors or a headlamp. Safety first!',
        ]),
        emoji: '🌙',
        category: 'timeofday',
      );
    }
    return null;
  }

  // ========== 13. 스플릿 분석 ==========
  static CoachingAnalysis? _analyzeSplits(List<RunPoint> points) {
    // km별 소요 시간 계산
    final splits = <int, int>{}; // km -> seconds
    double dist = 0;
    int nextKm = 1;
    int lastMs = points.first.timestampMs;

    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      dist += _quickDistance(p0.latitude, p0.longitude, p1.latitude, p1.longitude);

      if (dist >= nextKm * 1000) {
        final splitMs = p1.timestampMs - lastMs;
        splits[nextKm] = splitMs ~/ 1000;
        lastMs = p1.timestampMs;
        nextKm++;
      }
    }

    if (splits.length < 2) return null;

    // 가장 빠른/느린 km 찾기
    int fastestKm = 1, slowestKm = 1;
    int fastestTime = splits.values.first, slowestTime = splits.values.first;
    for (final e in splits.entries) {
      if (e.value < fastestTime) { fastestTime = e.value; fastestKm = e.key; }
      if (e.value > slowestTime) { slowestTime = e.value; slowestKm = e.key; }
    }

    final diff = slowestTime - fastestTime;
    if (diff < 30) {
      return CoachingAnalysis(
        title: S.isKo ? '균일한 스플릿!' : 'Even Splits!',
        body: S.isKo
            ? '모든 km을 비슷한 속도로 달렸습니다. 균일한 스플릿은 프로 러너의 특징입니다. 대단해요!'
            : 'You ran each km at a similar pace. Even splits are a mark of pro runners. Impressive!',
        emoji: '📊',
        category: 'split',
      );
    }

    final fastMin = fastestTime ~/ 60;
    final fastSec = fastestTime % 60;
    final slowMin = slowestTime ~/ 60;
    final slowSec = slowestTime % 60;

    return CoachingAnalysis(
      title: S.isKo ? '스플릿 분석' : 'Split Analysis',
      body: _pick(S.isKo ? [
        '가장 빠른 구간: ${fastestKm}km ($fastMin\'${fastSec.toString().padLeft(2, '0')}"), 가장 느린 구간: ${slowestKm}km ($slowMin\'${slowSec.toString().padLeft(2, '0')}"). $diff초 차이. ${slowestKm > fastestKm ? '후반에 페이스가 떨어졌습니다. 초반에 너무 빨리 나간 건 아닌지 확인해보세요.' : '초반이 느리고 후반에 올렸네요. 네거티브 스플릿은 좋은 전략입니다!'}',
        '${slowestKm}km 구간에서 가장 느렸습니다 ($slowMin\'${slowSec.toString().padLeft(2, '0')}"). 이 구간에서 무엇이 달랐는지 기억해보세요. 오르막? 바람? 컨디션?',
        '${fastestKm}km에서 가장 빨랐고, ${slowestKm}km에서 가장 느렸습니다. 차이는 $diff초. 이 차이를 30초 이내로 줄이는 것이 다음 목표입니다.',
      ] : [
        'Fastest: km $fastestKm ($fastMin\'${fastSec.toString().padLeft(2, '0')}"), Slowest: km $slowestKm ($slowMin\'${slowSec.toString().padLeft(2, '0')}"). $diff s gap. ${slowestKm > fastestKm ? 'Pace dropped in the second half. Did you go out too fast?' : 'Started slow, finished fast. Negative splits are a great strategy!'}',
        'Slowest at km $slowestKm ($slowMin\'${slowSec.toString().padLeft(2, '0')}"). What was different? Uphill? Wind? Fatigue?',
        'Fastest at km $fastestKm, slowest at km $slowestKm. ${diff}s difference. Goal: keep it under 30 seconds.',
      ]),
      emoji: '📈',
      category: 'split',
    );
  }

  static double _quickDistance(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * 3.14159 / 180;
    final dLng = (lng2 - lng1) * 3.14159 / 180;
    final a = dLat * dLat + dLng * dLng * (lat1 * 3.14159 / 180).abs();
    return r * a.abs().clamp(0, 1e10) * 0.5;
  }
}
