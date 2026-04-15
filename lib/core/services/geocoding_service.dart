import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const _clientId = String.fromEnvironment('NAVER_CLIENT_ID');
  static const _clientSecret = String.fromEnvironment('NAVER_CLIENT_SECRET');

  /// 좌표 → 지역명 (예: "서울시 마포구")
  static Future<String?> reverseGeocode(double lat, double lng) async {
    if (_clientId.isEmpty || _clientSecret.isEmpty) {
      debugPrint('GeocodingService: API 키 미설정');
      return null;
    }

    try {
      final url = Uri.parse(
        'https://maps.apigw.ntruss.com/map-reversegeocode/v2/gc'
        '?coords=$lng,$lat&output=json&orders=legalcode',
      );

      final response = await http.get(url, headers: {
        'X-NCP-APIGW-API-KEY-ID': _clientId,
        'X-NCP-APIGW-API-KEY': _clientSecret,
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        debugPrint('Reverse geocode 실패: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return null;

      final region = results[0]['region'];
      final area1 = region?['area1']?['name'] ?? ''; // 시/도
      final area2 = region?['area2']?['name'] ?? ''; // 구/군
      final area3 = region?['area3']?['name'] ?? ''; // 동/읍/면

      if (area1.isEmpty) return null;
      final parts = [area1, if (area2.isNotEmpty) area2, if (area3.isNotEmpty) area3];
      return parts.join(' ');
    } catch (e) {
      debugPrint('Reverse geocode 에러: $e');
      return null;
    }
  }
}
