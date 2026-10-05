import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehicle.dart';
import '../models/violation.dart';
import '../models/alert_model.dart';
import '../models/weight_record.dart';

class ApiService {
  // Configurable base URL:
  // Use http://10.0.2.2:8000 for Android Emulator
  // Use http://127.0.0.1:8000 for iOS Simulator / Web / Desktop
  // Use http://<LAN_IP>:8000 for Physical Phone on Wi-Fi
  static String baseUrl = 'http://127.0.0.1:8000';
  static String? authToken;
  static Map<String, dynamic>? currentUser;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  // 1. Authentication
  static Future<bool> login(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        authToken = data['token'];
        currentUser = data;
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // 2. Fetch Dashboard Statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/dashboard/stats'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print('getDashboardStats error: $e');
    }
    // Safe default offline fallback
    return {
      'total_scans_today': 128,
      'total_violations_today': 14,
      'total_fines_collected': 240000.0,
      'critical_alerts_count': 3,
      'average_excess_weight_kg': 3250.0,
      'active_checkpoints_count': 4,
      'recent_violations': [],
      'recent_alerts': [],
    };
  }

  // 3. Weight Check (Manual or Sensor Trigger)
  static Future<WeightRecord?> checkWeight({
    required String plateNumber,
    required double weightKg,
    String checkpoint = 'Raipur Highway Toll Plaza (NH-53)',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/weight-check'),
        headers: _headers,
        body: jsonEncode({
          'sensor_id': 'MOBILE_MANUAL_CHECK',
          'plate_number': plateNumber,
          'measured_weight_kg': weightKg,
          'checkpoint_name': checkpoint,
        }),
      );
      if (res.statusCode == 200) {
        return WeightRecord.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      print('checkWeight error: $e');
    }
    return null;
  }

  // 4. Fetch Violations
  static Future<List<Violation>> getViolations() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/violations'), headers: _headers);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((v) => Violation.fromJson(v)).toList();
      }
    } catch (e) {
      print('getViolations error: $e');
    }
    return [];
  }

  // 5. Fetch Alerts
  static Future<List<AlertModel>> getAlerts({bool unreadOnly = false}) async {
    try {
      final url = '$baseUrl/api/alerts?unread_only=${unreadOnly ? "true" : "false"}';
      final res = await http.get(Uri.parse(url), headers: _headers);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((a) => AlertModel.fromJson(a)).toList();
      }
    } catch (e) {
      print('getAlerts error: $e');
    }
    return [];
  }

  // 6. Acknowledge Alert
  static Future<bool> acknowledgeAlert(int alertId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/alerts/acknowledge/$alertId'),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 7. Pay Violation / E-Challan
  static Future<bool> payChallan(int violationId) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/api/violations/$violationId/pay'),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 8. ANPR Scan
  static Future<Map<String, dynamic>?> scanPlate({
    String? plateHint,
    double? simulatedWeight,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/anpr/scan'));
      if (plateHint != null) request.fields['plate_hint'] = plateHint;
      if (simulatedWeight != null) request.fields['simulated_weight'] = simulatedWeight.toString();
      request.fields['checkpoint_name'] = 'Raipur Highway Toll Plaza (NH-53)';

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('scanPlate error: $e');
    }
    return null;
  }

  // 9. Locations
  static Future<List<dynamic>> getLocations() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/locations'), headers: _headers);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print('getLocations error: $e');
    }
    return [];
  }
}
