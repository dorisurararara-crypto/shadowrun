class RunModel {
  static bool _useMiles = false;
  static void setUnit(String unit) => _useMiles = unit == 'miles' || unit == 'mi';
  static bool get useMiles => _useMiles;

  final int? id;
  final String date;
  final double distanceM;
  final int durationS;
  final double avgPace;
  final int calories;
  final bool isChallenge;
  final String? challengeResult; // 'win', 'lose', null
  final int? shadowRunId;
  final String? location;
  final String? name;
  final int? shoeId;
  /// 도플갱어 모드 최종 간격(m). 양수=앞섬(승리), 음수=뒤처짐(잡힘). 비도전 모드 null.
  final double? finalShadowGapM;

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
    this.location,
    this.name,
    this.shoeId,
    this.finalShadowGapM,
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
    'location': location,
    'name': name,
    'shoe_id': shoeId,
    'final_shadow_gap_m': finalShadowGapM,
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
    location: map['location'] as String?,
    name: map['name'] as String?,
    shoeId: map['shoe_id'] as int?,
    finalShadowGapM: (map['final_shadow_gap_m'] as num?)?.toDouble(),
  );

  String get formattedDistance => formattedDistanceUnit(_useMiles ? 'mi' : 'km');

  String formattedDistanceUnit(String unit) {
    if (unit == 'mi') {
      final miles = distanceM / 1609.344;
      if (miles >= 0.1) return '${miles.toStringAsFixed(2)}mi';
      final yards = (distanceM * 1.09361).toInt();
      return '${yards}yd';
    }
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

  String get formattedPace => formattedPaceUnit(_useMiles ? 'mi' : 'km');

  String formattedPaceUnit(String unit) {
    final pace = unit == 'mi' ? avgPace * 1.60934 : avgPace;
    if (pace <= 0 || pace.isInfinite) return "--'--\"";
    final min = pace.floor();
    final sec = ((pace - min) * 60).round();
    return "$min'${sec.toString().padLeft(2, '0')}\"";
  }

  /// 한글 날짜: "4월 12일 토요일" / 영어: "Apr 12, Sat"
  String formattedDateLocalized(bool isKo) {
    final dt = DateTime.tryParse(date);
    if (dt == null) return date;

    if (isKo) {
      const weekdaysKo = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
      return '${dt.month}월 ${dt.day}일 ${weekdaysKo[dt.weekday - 1]}';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${months[dt.month - 1]} ${dt.day}, ${weekdays[dt.weekday - 1]}';
    }
  }

  /// 날짜 + 장소 조합: "4월 12일 토요일 · 마포구"
  String formattedDateWithLocation(bool isKo) {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    final dateStr = formattedDateLocalized(isKo);
    if (location != null && location!.isNotEmpty) {
      return '$dateStr · $location';
    }
    return dateStr;
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
