import 'dart:async';
import 'dart:math' as math;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shadowrun/shared/models/run_model.dart';

class DatabaseHelper {
  static Database? _db;
  static Completer<Database>? _dbCompleter;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    if (_dbCompleter != null) return _dbCompleter!.future;
    _dbCompleter = Completer<Database>();
    try {
      _db = await _initDb();
      _dbCompleter!.complete(_db!);
    } catch (e) {
      _dbCompleter!.completeError(e);
      _dbCompleter = null;
      rethrow;
    }
    return _db!;
  }

  static Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'shadowrun.db');
    return openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE runs ADD COLUMN location TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE runs ADD COLUMN name TEXT');
      await db.execute('ALTER TABLE runs ADD COLUMN shoe_id INTEGER');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS shoes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          brand TEXT,
          total_distance_m REAL NOT NULL DEFAULT 0,
          max_distance_m REAL NOT NULL DEFAULT 1000000,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS goals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          period TEXT NOT NULL,
          target_value REAL NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      // 최종 그림자 간격(m) — 양수=앞섬, 음수=뒤처짐.
      // 기존 레코드는 NULL 유지(표시부에서 fallback 계산).
      await db.execute('ALTER TABLE runs ADD COLUMN final_shadow_gap_m REAL');
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE runs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        distance_m REAL NOT NULL,
        duration_s INTEGER NOT NULL,
        avg_pace REAL NOT NULL,
        calories INTEGER NOT NULL DEFAULT 0,
        is_challenge INTEGER NOT NULL DEFAULT 0,
        challenge_result TEXT,
        shadow_run_id INTEGER,
        location TEXT,
        name TEXT,
        shoe_id INTEGER,
        final_shadow_gap_m REAL,
        FOREIGN KEY (shadow_run_id) REFERENCES runs(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE run_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        run_id INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp_ms INTEGER NOT NULL,
        speed_mps REAL NOT NULL DEFAULT 0,
        heart_rate INTEGER,
        FOREIGN KEY (run_id) REFERENCES runs(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE shoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brand TEXT,
        total_distance_m REAL NOT NULL DEFAULT 0,
        max_distance_m REAL NOT NULL DEFAULT 1000000,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        period TEXT NOT NULL,
        target_value REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    // 기본 설정
    await db.insert('settings', {'key': 'horror_level', 'value': '2'});
    await db.insert('settings', {'key': 'tts_enabled', 'value': 'true'});
    await db.insert('settings', {'key': 'vibration_enabled', 'value': 'true'});
    await db.insert('settings', {'key': 'run_mode', 'value': 'fullmap'});
    await db.insert('settings', {'key': 'unit', 'value': 'km'});
    await db.insert('settings', {'key': 'is_pro', 'value': 'false'});
    await db.insert('settings', {'key': 'daily_challenges', 'value': '0'});
    await db.insert('settings', {'key': 'daily_challenges_date', 'value': ''});
  }

  // --- Runs ---
  static Future<int> insertRun(RunModel run) async {
    final db = await database;
    return db.insert('runs', run.toMap());
  }

  static Future<List<RunModel>> getAllRuns() async {
    final db = await database;
    final maps = await db.query('runs', orderBy: 'date DESC');
    return maps.map((m) => RunModel.fromMap(m)).toList();
  }

  static Future<RunModel?> getRun(int id) async {
    final db = await database;
    final maps = await db.query('runs', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return RunModel.fromMap(maps.first);
  }

  static Future<void> deleteRun(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('run_points', where: 'run_id = ?', whereArgs: [id]);
      await txn.delete('runs', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// 러닝 + 포인트 + 챌린지 카운트를 트랜잭션으로 저장
  static Future<int> insertRunWithPoints(RunModel run, List<RunPoint> points, {bool incrementChallenge = false}) async {
    final db = await database;
    late int runId;
    await db.transaction((txn) async {
      runId = await txn.insert('runs', run.toMap());
      final batch = txn.batch();
      for (final p in points) {
        batch.insert('run_points', RunPoint(
          runId: runId,
          latitude: p.latitude,
          longitude: p.longitude,
          timestampMs: p.timestampMs,
          speedMps: p.speedMps,
          heartRate: p.heartRate,
        ).toMap());
      }
      await batch.commit(noResult: true);
      if (incrementChallenge) {
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final savedDate = (await txn.query('settings', where: 'key = ?', whereArgs: ['daily_challenges_date'])).firstOrNull;
        int count = 0;
        if (savedDate != null && savedDate['value'] == today) {
          final countRow = await txn.query('settings', where: 'key = ?', whereArgs: ['daily_challenges']);
          count = int.tryParse(countRow.firstOrNull?['value'] as String? ?? '0') ?? 0;
        }
        await txn.insert('settings', {'key': 'daily_challenges', 'value': '${count + 1}'}, conflictAlgorithm: ConflictAlgorithm.replace);
        await txn.insert('settings', {'key': 'daily_challenges_date', 'value': today}, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    return runId;
  }

  // --- Run Points ---
  static Future<void> insertPoints(List<RunPoint> points) async {
    final db = await database;
    final batch = db.batch();
    for (final p in points) {
      batch.insert('run_points', p.toMap());
    }
    await batch.commit(noResult: true);
  }

  static Future<List<RunPoint>> getRunPoints(int runId) async {
    final db = await database;
    final maps = await db.query('run_points', where: 'run_id = ?', whereArgs: [runId], orderBy: 'timestamp_ms ASC');
    return maps.map((m) => RunPoint.fromMap(m)).toList();
  }

  // --- Settings ---
  static Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  static Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Stats ---
  static Future<Map<String, dynamic>> getStats() async {
    final db = await database;
    final totalRuns = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM runs'));
    final totalDistance = (await db.rawQuery('SELECT SUM(distance_m) as total FROM runs')).first['total'];
    final wins = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM runs WHERE challenge_result = 'win'"));
    final losses = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM runs WHERE challenge_result = 'lose'"));

    // 연속 승리 스트릭
    final challengeRuns = await db.query('runs', where: 'is_challenge = 1', orderBy: 'date DESC');
    int streak = 0;
    for (final r in challengeRuns) {
      if (r['challenge_result'] == 'win') {
        streak++;
      } else {
        break;
      }
    }

    return {
      'totalRuns': totalRuns ?? 0,
      'totalDistanceM': (totalDistance as num?)?.toDouble() ?? 0.0,
      'wins': wins ?? 0,
      'losses': losses ?? 0,
      'streak': streak,
    };
  }

  static Future<double> getAveragePace() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT AVG(avg_pace) as avg FROM runs WHERE avg_pace > 0 AND avg_pace < 30',
    );
    return (result.first['avg'] as num?)?.toDouble() ?? 0.0;
  }

  // --- Analysis ---
  static Future<List<RunModel>> getRunsByDateRange(DateTime from, DateTime to) async {
    final db = await database;
    final maps = await db.query('runs',
      where: 'date >= ? AND date < ?',
      whereArgs: [from.toIso8601String(), to.toIso8601String()],
      orderBy: 'date ASC',
    );
    return maps.map((m) => RunModel.fromMap(m)).toList();
  }

  static Future<Map<String, List<RunModel>>> getRunsGroupedByDate(DateTime month) async {
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 1);
    final runs = await getRunsByDateRange(from, to);
    final grouped = <String, List<RunModel>>{};
    for (final run in runs) {
      final dateKey = run.date.substring(0, 10);
      grouped.putIfAbsent(dateKey, () => []).add(run);
    }
    return grouped;
  }

  static Future<List<Map<String, dynamic>>> getWeeklyStats(int weeks) async {
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (int i = weeks - 1; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + i * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final from = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final to = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);
      final runs = await getRunsByDateRange(from, to);
      double totalDist = 0;
      double totalPace = 0;
      int paceCount = 0;
      for (final r in runs) {
        totalDist += r.distanceM;
        if (r.avgPace > 0) {
          totalPace += r.avgPace;
          paceCount++;
        }
      }
      result.add({
        'weekStart': from,
        'distance': totalDist,
        'avgPace': paceCount > 0 ? totalPace / paceCount : 0.0,
        'runs': runs.length,
      });
    }
    return result;
  }

  // --- Personal Records ---
  /// 개인 최고 기록: 1km / 5km / 최장거리 / 최장 탈출 시간
  /// - 1K/5K 는 해당 거리 이상 달린 러닝 중 avg_pace 최고(=작은 값)
  /// - bestDistanceM: 단일 러닝 최장
  /// - bestEscapeS: is_challenge && challenge_result='win' 중 duration_s 최대
  static Future<Map<String, dynamic>> getPersonalRecords() async {
    final db = await database;
    final best1K = Sqflite.firstIntValue(
      await db.rawQuery("SELECT MIN(avg_pace) FROM runs WHERE distance_m >= 1000 AND avg_pace > 0"),
    );
    final best5K = Sqflite.firstIntValue(
      await db.rawQuery("SELECT MIN(avg_pace) FROM runs WHERE distance_m >= 5000 AND avg_pace > 0"),
    );
    final bestDistRow = await db.rawQuery("SELECT MAX(distance_m) as m FROM runs");
    final bestDistanceM = (bestDistRow.first['m'] as num?)?.toDouble() ?? 0.0;
    final bestEscapeRow = await db.rawQuery(
      "SELECT MAX(duration_s) as s FROM runs WHERE is_challenge = 1 AND challenge_result = 'win'",
    );
    final bestEscapeS = (bestEscapeRow.first['s'] as num?)?.toInt() ?? 0;
    return {
      'best1KPace': best1K?.toDouble() ?? 0.0,
      'best5KPace': best5K?.toDouble() ?? 0.0,
      'bestDistanceM': bestDistanceM,
      'bestEscapeS': bestEscapeS,
    };
  }

  /// 도플갱어 전적: 총 도전 횟수, 승, 패, 승률, 평균 탈출 거리
  static Future<Map<String, dynamic>> getDoppelgangerStats() async {
    final db = await database;
    final total = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM runs WHERE is_challenge = 1"),
    ) ?? 0;
    final wins = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM runs WHERE is_challenge = 1 AND challenge_result = 'win'"),
    ) ?? 0;
    final losses = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM runs WHERE is_challenge = 1 AND challenge_result = 'lose'"),
    ) ?? 0;
    final avgEscapeRow = await db.rawQuery(
      "SELECT AVG(distance_m) as m FROM runs WHERE is_challenge = 1 AND challenge_result = 'win'",
    );
    final avgEscapeM = (avgEscapeRow.first['m'] as num?)?.toDouble() ?? 0.0;
    final winRate = total > 0 ? wins / total : 0.0;
    return {
      'total': total,
      'wins': wins,
      'losses': losses,
      'winRate': winRate,
      'avgEscapeM': avgEscapeM,
    };
  }

  /// 연속 러닝 streak (달린 날짜 기준). 오늘 또는 어제까지 연속으로 1회 이상 달린 일수.
  static Future<Map<String, dynamic>> getStreakInfo() async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT substr(date, 1, 10) as d FROM runs ORDER BY d DESC",
    );
    final dates = rows.map((r) => r['d'] as String).toSet();
    final today = DateTime.now();
    String fmt(DateTime d) => d.toIso8601String().substring(0, 10);

    int current = 0;
    // 오늘 또는 어제부터 역순으로 연속 일수 계산
    DateTime cursor = today;
    if (!dates.contains(fmt(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (dates.contains(fmt(cursor))) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // 최장 streak: 모든 날짜 탐색
    int longest = 0;
    int run = 0;
    DateTime? prev;
    final sorted = dates.toList()..sort();
    for (final s in sorted) {
      final d = DateTime.parse(s);
      if (prev != null && d.difference(prev).inDays == 1) {
        run++;
      } else {
        run = 1;
      }
      if (run > longest) longest = run;
      prev = d;
    }

    final lastRunDate = sorted.isNotEmpty ? sorted.last : null;
    return {
      'current': current,
      'longest': longest,
      'lastRunDate': lastRunDate,
    };
  }

  /// 히트맵 달력용 — 최근 N일의 날짜별 거리 맵 (yyyy-MM-dd → meters).
  static Future<Map<String, double>> getDailyDistanceMap(int days) async {
    final db = await database;
    final from = DateTime.now().subtract(Duration(days: days - 1));
    final fromIso = DateTime(from.year, from.month, from.day).toIso8601String();
    final rows = await db.rawQuery(
      "SELECT substr(date, 1, 10) as d, SUM(distance_m) as m FROM runs WHERE date >= ? GROUP BY d",
      [fromIso],
    );
    final map = <String, double>{};
    for (final r in rows) {
      map[r['d'] as String] = (r['m'] as num?)?.toDouble() ?? 0.0;
    }
    return map;
  }

  /// 1km splits — run_points 를 순회하며 누적 거리 1km 단위로 끊어 split time 계산.
  /// 반환: [{ km: 1, seconds: 345 }, { km: 2, seconds: 360 }, ...]
  static Future<List<Map<String, dynamic>>> getSplits(int runId) async {
    final points = await getRunPoints(runId);
    if (points.length < 2) return [];
    final splits = <Map<String, dynamic>>[];
    double accumM = 0;
    int kmIndex = 1;
    int? kmStartMs = points.first.timestampMs;
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final cur = points[i];
      final segM = _haversineM(prev.latitude, prev.longitude, cur.latitude, cur.longitude);
      accumM += segM;
      while (accumM >= kmIndex * 1000) {
        final startMs = kmStartMs ?? cur.timestampMs;
        final elapsed = ((cur.timestampMs - startMs) / 1000).round();
        splits.add({'km': kmIndex, 'seconds': elapsed});
        kmStartMs = cur.timestampMs;
        kmIndex++;
      }
    }
    return splits;
  }

  /// 페이스 분포 — easy (>6:30/km), chase (5:00~6:30), sprint (<5:00) 각 구간에서 보낸 초.
  /// GPS speed 필드가 0/null 이면 인접 포인트 delta 로 fallback 계산 (에뮬/일부 단말 대응).
  static Future<Map<String, int>> getPaceDistribution(int runId) async {
    final points = await getRunPoints(runId);
    if (points.length < 2) return {'easy': 0, 'chase': 0, 'sprint': 0};
    int easy = 0, chase = 0, sprint = 0;
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final cur = points[i];
      final dtS = (cur.timestampMs - prev.timestampMs) / 1000;
      if (dtS <= 0 || dtS > 10) continue; // GPS 끊김 구간 제외
      double speed = cur.speedMps > 0 ? cur.speedMps : 0;
      // speed 0 fallback: 위치 delta / 시간
      if (speed <= 0) {
        final dM = _haversineM(prev.latitude, prev.longitude, cur.latitude, cur.longitude);
        if (dM > 0 && dtS > 0) speed = dM / dtS;
      }
      if (speed < 0.3) continue; // 정지 상태
      final paceMinPerKm = 1000 / (speed * 60);
      if (paceMinPerKm > 6.5) {
        easy += dtS.round();
      } else if (paceMinPerKm >= 5.0) {
        chase += dtS.round();
      } else {
        sprint += dtS.round();
      }
    }
    return {'easy': easy, 'chase': chase, 'sprint': sprint};
  }

  static double _haversineM(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    return 2 * r * math.asin(math.sqrt(a).clamp(0.0, 1.0));
  }

  /// 전체 누적 거리(m) — 레벨 시스템 기준.
  static Future<double> getTotalLifetimeDistance() async {
    final db = await database;
    final row = await db.rawQuery('SELECT SUM(distance_m) as m FROM runs');
    return (row.first['m'] as num?)?.toDouble() ?? 0.0;
  }

  /// 최근 12개월 월별 거리 — NRC 스타일 막대/선 그래프용.
  /// 반환: [{'monthStart': DateTime, 'distance': double(m), 'runs': int}]
  static Future<List<Map<String, dynamic>>> getMonthlyDistanceLast12() async {
    final db = await database;
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];
    for (int i = 11; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);
      final rows = await db.rawQuery(
        'SELECT SUM(distance_m) as m, COUNT(*) as c FROM runs WHERE date >= ? AND date < ?',
        [monthStart.toIso8601String(), nextMonth.toIso8601String()],
      );
      final r = rows.first;
      result.add({
        'monthStart': monthStart,
        'distance': (r['m'] as num?)?.toDouble() ?? 0.0,
        'runs': (r['c'] as num?)?.toInt() ?? 0,
      });
    }
    return result;
  }

  /// 러닝 모드별 요약 — freerun / marathon / doppelganger(challenge) 카테고리.
  /// 러닝 기록에 run_mode 컬럼이 없으면 is_challenge / name 기반으로 추정.
  /// 반환: { 'doppelganger': {runs: N, distanceM: X}, 'freerun': {...}, 'marathon': {...} }
  static Future<Map<String, Map<String, dynamic>>> getRunsByMode() async {
    final db = await database;
    final all = await db.query('runs');
    final out = <String, Map<String, dynamic>>{
      'doppelganger': {'runs': 0, 'distanceM': 0.0},
      'freerun': {'runs': 0, 'distanceM': 0.0},
      'marathon': {'runs': 0, 'distanceM': 0.0},
    };
    for (final r in all) {
      final isChallenge = (r['is_challenge'] as int? ?? 0) == 1;
      final name = (r['name'] as String? ?? '').toLowerCase();
      final dist = (r['distance_m'] as num?)?.toDouble() ?? 0.0;
      String key;
      if (isChallenge) {
        key = 'doppelganger';
      } else if (name.contains('marathon') || name.contains('마라톤') || name.contains('legend') || name.contains('전설')) {
        key = 'marathon';
      } else {
        key = 'freerun';
      }
      out[key]!['runs'] = (out[key]!['runs'] as int) + 1;
      out[key]!['distanceM'] = (out[key]!['distanceM'] as double) + dist;
    }
    return out;
  }

  /// 배지 획득 평가 — DB 상태를 스캔해서 달성한 배지 id 리스트 반환.
  /// BadgeDefs 테이블 없이 상수 기반으로 관리 (출시 시점 셋).
  static Future<Set<String>> getEarnedBadges() async {
    final db = await database;
    final stats = await getStats();
    final dopp = await getDoppelgangerStats();
    final streak = await getStreakInfo();
    final longestRun = Sqflite.firstIntValue(
      await db.rawQuery('SELECT CAST(MAX(distance_m) AS INTEGER) FROM runs'),
    ) ?? 0;

    final out = <String>{};
    // 거리 마일스톤 (단일 러닝 최장)
    if (longestRun >= 1000) out.add('dist_1k');
    if (longestRun >= 5000) out.add('dist_5k');
    if (longestRun >= 10000) out.add('dist_10k');
    if (longestRun >= 21097) out.add('dist_half');
    if (longestRun >= 42195) out.add('dist_full');
    // 누적 거리
    final totalKm = ((stats['totalDistanceM'] as double?) ?? 0) / 1000;
    if (totalKm >= 50) out.add('total_50k');
    if (totalKm >= 200) out.add('total_200k');
    if (totalKm >= 500) out.add('total_500k');
    // 도플갱어 승
    final wins = (dopp['wins'] as int?) ?? 0;
    if (wins >= 1) out.add('dopp_first_win');
    if (wins >= 10) out.add('dopp_10_wins');
    if (wins >= 50) out.add('dopp_50_wins');
    // streak
    final longest = (streak['longest'] as int?) ?? 0;
    if (longest >= 3) out.add('streak_3');
    if (longest >= 7) out.add('streak_7');
    if (longest >= 30) out.add('streak_30');
    if (longest >= 100) out.add('streak_100');
    return out;
  }

  // --- Daily Challenge Limit ---
  static Future<int> getDailyChallengeCount() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = await getSetting('daily_challenges_date');
    if (savedDate != today) {
      await setSetting('daily_challenges', '0');
      await setSetting('daily_challenges_date', today);
      return 0;
    }
    final count = await getSetting('daily_challenges');
    return int.tryParse(count ?? '0') ?? 0;
  }

  static Future<void> incrementDailyChallenge() async {
    final count = await getDailyChallengeCount();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await setSetting('daily_challenges', '${count + 1}');
    await setSetting('daily_challenges_date', today);
  }

  // --- Run Name ---
  static Future<void> updateRunName(int runId, String name) async {
    final db = await database;
    await db.update('runs', {'name': name}, where: 'id = ?', whereArgs: [runId]);
  }

  // --- Shoes ---
  static Future<int> insertShoe(String name, String? brand, double maxDistanceM) async {
    final db = await database;
    return db.insert('shoes', {
      'name': name,
      'brand': brand,
      'total_distance_m': 0,
      'max_distance_m': maxDistanceM,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getActiveShoes() async {
    final db = await database;
    return db.query('shoes', where: 'is_active = 1', orderBy: 'created_at DESC');
  }

  static Future<List<Map<String, dynamic>>> getAllShoes() async {
    final db = await database;
    return db.query('shoes', orderBy: 'is_active DESC, created_at DESC');
  }

  static Future<void> addShoeDistance(int shoeId, double distanceM) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE shoes SET total_distance_m = total_distance_m + ? WHERE id = ?',
      [distanceM, shoeId],
    );
  }

  static Future<void> retireShoe(int shoeId) async {
    final db = await database;
    await db.update('shoes', {'is_active': 0}, where: 'id = ?', whereArgs: [shoeId]);
  }

  static Future<void> deleteShoe(int shoeId) async {
    final db = await database;
    await db.delete('shoes', where: 'id = ?', whereArgs: [shoeId]);
  }

  // --- Goals ---
  static Future<int> insertGoal(String type, String period, double targetValue) async {
    final db = await database;
    return db.insert('goals', {
      'type': type,
      'period': period,
      'target_value': targetValue,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<Map<String, dynamic>?> getActiveGoal() async {
    final db = await database;
    final results = await db.query('goals', orderBy: 'id DESC', limit: 1);
    return results.firstOrNull;
  }

  static Future<void> updateGoal(int id, double targetValue, {String? type, String? period}) async {
    final db = await database;
    final updates = <String, dynamic>{'target_value': targetValue};
    if (type != null) updates['type'] = type;
    if (period != null) updates['period'] = period;
    await db.update('goals', updates, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteGoal(int id) async {
    final db = await database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  static Future<Map<String, dynamic>> getGoalProgress(String period) async {
    final now = DateTime.now();
    DateTime from;
    if (period == 'weekly') {
      from = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    } else {
      from = DateTime(now.year, now.month, 1);
    }
    final db = await database;
    final distResult = await db.rawQuery(
      'SELECT SUM(distance_m) as dist, COUNT(*) as count FROM runs WHERE date >= ?',
      [from.toIso8601String()],
    );
    return {
      'distance': (distResult.first['dist'] as num?)?.toDouble() ?? 0.0,
      'runs': (distResult.first['count'] as num?)?.toInt() ?? 0,
    };
  }
}
