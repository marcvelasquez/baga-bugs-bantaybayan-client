import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/api_models.dart';

class ApiService {
  static String? _authToken;

  static void setAuthToken(String token) {
    _authToken = token;
  }

  static void clearAuthToken() {
    _authToken = null;
  }

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  static Future<http.Response> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else {
      throw Exception(
          'API Error: ${response.statusCode} - ${response.body}');
    }
  }

  // Auth endpoints
  static Future<AuthToken> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.authUrl}/register'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'username': username,
        'password': password,
      }),
    );

    await _handleResponse(response);
    return AuthToken.fromJson(jsonDecode(response.body));
  }

  static Future<AuthToken> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.authUrl}/login'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    final responseData = await _handleResponse(response);
    final token = AuthToken.fromJson(jsonDecode(responseData.body));
    setAuthToken(token.accessToken);
    return token;
  }

  // Report endpoints
  static Future<ReportModel> createReport(ReportModel report) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.reportsUrl}/'),
      headers: _headers,
      body: jsonEncode(report.toJson()),
    );

    final responseData = await _handleResponse(response);
    return ReportModel.fromJson(jsonDecode(responseData.body));
  }

  static Future<List<ReportModel>> getReports({
    int skip = 0,
    int limit = 100,
    String? incidentType,
  }) async {
    var url = '${ApiConfig.reportsUrl}/?skip=$skip&limit=$limit';
    if (incidentType != null) {
      url += '&incident_type=$incidentType';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    final responseData = await _handleResponse(response);
    final List<dynamic> data = jsonDecode(responseData.body);
    return data.map((json) => ReportModel.fromJson(json)).toList();
  }

  static Future<ReportStats> getReportStats() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.reportsUrl}/stats'),
      headers: _headers,
    );

    final responseData = await _handleResponse(response);
    return ReportStats.fromJson(jsonDecode(responseData.body));
  }

  static Future<ReportModel> getReport(int reportId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.reportsUrl}/$reportId'),
      headers: _headers,
    );

    final responseData = await _handleResponse(response);
    return ReportModel.fromJson(jsonDecode(responseData.body));
  }

  static Future<ReportModel> updateReport(int reportId, Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.reportsUrl}/$reportId'),
      headers: _headers,
      body: jsonEncode(updates),
    );

    final responseData = await _handleResponse(response);
    return ReportModel.fromJson(jsonDecode(responseData.body));
  }

  static Future<void> deleteReport(int reportId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.reportsUrl}/$reportId'),
      headers: _headers,
    );

    await _handleResponse(response);
  }

  static Future<List<ReportModel>> getNearbyReports({
    required double latitude,
    required double longitude,
    double radius = 100.0,
    String? incidentType,
  }) async {
    var url = '${ApiConfig.reportsUrl}/nearby/$latitude/$longitude?radius=$radius';
    if (incidentType != null) {
      url += '&incident_type=$incidentType';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    final responseData = await _handleResponse(response);
    final List<dynamic> data = jsonDecode(responseData.body);
    return data.map((json) => ReportModel.fromJson(json)).toList();
  }

  static Future<ReportModel> upvoteReport(int reportId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.reportsUrl}/$reportId/upvote'),
      headers: _headers,
    );

    final responseData = await _handleResponse(response);
    return ReportModel.fromJson(jsonDecode(responseData.body));
  }

  static Future<ReportModel> removeUpvote(int reportId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.reportsUrl}/$reportId/upvote'),
      headers: _headers,
    );

    final responseData = await _handleResponse(response);
    return ReportModel.fromJson(jsonDecode(responseData.body));
  }

  // Incident endpoints
  static Future<IncidentModel> createIncident(IncidentModel incident) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.incidentsUrl}/'),
      headers: _headers,
      body: jsonEncode(incident.toJson()),
    );

    final responseData = await _handleResponse(response);
    return IncidentModel.fromJson(jsonDecode(responseData.body));
  }

  static Future<List<IncidentModel>> getIncidents({
    int skip = 0,
    int limit = 100,
    bool? isActive,
    String? incidentType,
  }) async {
    var url = '${ApiConfig.incidentsUrl}/?skip=$skip&limit=$limit';
    if (isActive != null) {
      url += '&is_active=$isActive';
    }
    if (incidentType != null) {
      url += '&incident_type=$incidentType';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    final responseData = await _handleResponse(response);
    final List<dynamic> data = jsonDecode(responseData.body);
    return data.map((json) => IncidentModel.fromJson(json)).toList();
  }

  static Future<List<IncidentModel>> getActiveIncidents() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.incidentsUrl}/active'),
      headers: _headers,
    );

    final responseData = await _handleResponse(response);
    final List<dynamic> data = jsonDecode(responseData.body);
    return data.map((json) => IncidentModel.fromJson(json)).toList();
  }

  static Future<IncidentModel> getIncident(int incidentId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.incidentsUrl}/$incidentId'),
      headers: _headers,
    );

    final responseData = await _handleResponse(response);
    return IncidentModel.fromJson(jsonDecode(responseData.body));
  }

  static Future<IncidentModel> updateIncident(
      int incidentId, Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.incidentsUrl}/$incidentId'),
      headers: _headers,
      body: jsonEncode(updates),
    );

    final responseData = await _handleResponse(response);
    return IncidentModel.fromJson(jsonDecode(responseData.body));
  }

  static Future<void> deleteIncident(int incidentId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.incidentsUrl}/$incidentId'),
      headers: _headers,
    );

    await _handleResponse(response);
  }

  // User endpoints
  static Future<List<UserModel>> getUsers({
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.usersUrl}/?skip=$skip&limit=$limit'),
      headers: _headers,
    );

    final responseData = await _handleResponse(response);
    final List<dynamic> data = jsonDecode(responseData.body);
    return data.map((json) => UserModel.fromJson(json)).toList();
  }

  static Future<UserModel> getUser(int userId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.usersUrl}/$userId'),
      headers: _headers,
    );

    final responseData = await _handleResponse(response);
    return UserModel.fromJson(jsonDecode(responseData.body));
  }

  // Weather endpoints
  static Future<WeatherModel> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.weatherUrl}/current?latitude=$latitude&longitude=$longitude'),
      headers: _headers,
    );

    final responseData = await _handleResponse(response);
    return WeatherModel.fromJson(jsonDecode(responseData.body));
  }

  static Future<WeatherForecast> getWeatherForecast({
    required double latitude,
    required double longitude,
    int days = 7,
  }) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.weatherUrl}/forecast?latitude=$latitude&longitude=$longitude&days=$days'),
      headers: _headers,
    );

    final responseData = await _handleResponse(response);
    return WeatherForecast.fromJson(jsonDecode(responseData.body));
  }

  // Handbook endpoints
  static Future<HandbookResponse> generateHandbook({
    required String weatherDescription,
    required double temperature,
    required double precipitation,
    required double rain,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.handbookUrl}/generate'),
      headers: _headers,
      body: jsonEncode({
        'weather_description': weatherDescription,
        'temperature': temperature,
        'precipitation': precipitation,
        'rain': rain,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    final responseData = await _handleResponse(response);
    return HandbookResponse.fromJson(jsonDecode(responseData.body));
  }

  static Future<List<SafetyTip>> getStaticTips() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.handbookUrl}/static-tips'),
      headers: _headers,
    );

    final responseData = await _handleResponse(response);
    final List<dynamic> data = jsonDecode(responseData.body);
    return data.map((tip) => SafetyTip.fromJson(tip)).toList();
  }
}
