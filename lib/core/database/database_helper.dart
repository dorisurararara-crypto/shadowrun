import 'dart:async';
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
      version: 3,
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

  static Future<void> updateGoal(int id, double targetValue) async {
    final db = await database;
    await db.update('goals', {'target_value': targetValue}, where: 'id = ?', whereArgs: [id]);
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
