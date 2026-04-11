import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shadowrun/shared/models/run_model.dart';

class DatabaseHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'shadowrun.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
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
    await db.delete('run_points', where: 'run_id = ?', whereArgs: [id]);
    await db.delete('runs', where: 'id = ?', whereArgs: [id]);
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
}
