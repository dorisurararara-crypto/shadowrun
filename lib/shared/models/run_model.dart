class RunModel {
  final int? id;
  final String date;
  final double distanceM;
  final int durationS;
  final double avgPace;
  final int calories;
  final bool isChallenge;
  final String? challengeResult; // 'win', 'lose', null
  final int? shadowRunId;

  const RunModel({
    this.id,
    required this.date,
    required this.distanceM,
    required this.durationS,
    required this.avgPace,
    required this.calories,
    this.isChallenge = false,
    this.challengeResult,
    this.shadowRunId,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'date': date,
    'distance_m': distanceM,
    'duration_s': durationS,
    'avg_pace': avgPace,
    'calories': calories,
    'is_challenge': isChallenge ? 1 : 0,
    'challenge_result': challengeResult,
    'shadow_run_id': shadowRunId,
  };

  factory RunModel.fromMap(Map<String, dynamic> map) => RunModel(
    id: map['id'] as int?,
    date: map['date'] as String,
    distanceM: (map['distance_m'] as num).toDouble(),
    durationS: map['duration_s'] as int,
    avgPace: (map['avg_pace'] as num).toDouble(),
    calories: map['calories'] as int,
    isChallenge: (map['is_challenge'] as int?) == 1,
    challengeResult: map['challenge_result'] as String?,
    shadowRunId: map['shadow_run_id'] as int?,
  );

  String get formattedDistance {
    if (distanceM >= 1000) {
      return '${(distanceM / 1000).toStringAsFixed(2)}km';
    }
    return '${distanceM.toInt()}m';
  }

  String get formattedDuration {
    final h = durationS ~/ 3600;
    final m = (durationS % 3600) ~/ 60;
    final s = durationS % 60;
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get formattedPace {
    final min = avgPace.floor();
    final sec = ((avgPace - min) * 60).round();
    return "$min'${sec.toString().padLeft(2, '0')}\"";
  }
}

class RunPoint {
  final int? id;
  final int runId;
  final double latitude;
  final double longitude;
  final int timestampMs;
  final double speedMps;
  final int? heartRate;

  const RunPoint({
    this.id,
    required this.runId,
    required this.latitude,
    required this.longitude,
    required this.timestampMs,
    required this.speedMps,
    this.heartRate,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'run_id': runId,
    'latitude': latitude,
    'longitude': longitude,
    'timestamp_ms': timestampMs,
    'speed_mps': speedMps,
    'heart_rate': heartRate,
  };

  factory RunPoint.fromMap(Map<String, dynamic> map) => RunPoint(
    id: map['id'] as int?,
    runId: map['run_id'] as int,
    latitude: (map['latitude'] as num).toDouble(),
    longitude: (map['longitude'] as num).toDouble(),
    timestampMs: map['timestamp_ms'] as int,
    speedMps: (map['speed_mps'] as num).toDouble(),
    heartRate: map['heart_rate'] as int?,
  );
}
