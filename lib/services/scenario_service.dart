import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class ScenarioStatus {
  final bool active;
  final String? scenario;
  final String message;

  ScenarioStatus({
    required this.active,
    this.scenario,
    required this.message,
  });

  factory ScenarioStatus.fromJson(Map<String, dynamic> json) {
    return ScenarioStatus(
      active: json['active'] ?? false,
      scenario: json['scenario'],
      message: json['message'] ?? '',
    );
  }
}

class ScenarioService {
  static String get scenarioUrl => '${ApiConfig.baseUrl}/scenario';

  /// Check if there's an active storm scenario on the server
  static Future<ScenarioStatus> checkScenarioStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$scenarioUrl/status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // Return inactive status on timeout
          throw TimeoutException('Server check timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ScenarioStatus.fromJson(data);
      } else {
        // Server error, assume no scenario
        return ScenarioStatus(
          active: false,
          message: 'Unable to check scenario status',
        );
      }
    } catch (e) {
      // Network error, assume no scenario
      return ScenarioStatus(
        active: false,
        message: 'Server unreachable',
      );
    }
  }

  /// Get full storm scenario details
  static Future<Map<String, dynamic>?> getStormScenario() async {
    try {
      final response = await http.get(
        Uri.parse('$scenarioUrl/storm-scenario'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching storm scenario: $e');
      return null;
    }
  }

  /// Activate storm scenario (admin/demo only)
  static Future<bool> activateScenario() async {
    try {
      final response = await http.post(
        Uri.parse('$scenarioUrl/activate'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Error activating scenario: $e');
      return false;
    }
  }

  /// Deactivate storm scenario (admin/demo only)
  static Future<bool> deactivateScenario() async {
    try {
      final response = await http.post(
        Uri.parse('$scenarioUrl/deactivate'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Error deactivating scenario: $e');
      return false;
    }
  }
}
