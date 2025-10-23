import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart' as browser;
import '../models/parking_lot.dart';
import '../models/reservation.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  static final http.Client _client = kIsWeb
      ? browser.BrowserClient()
      : http.Client();

  static String? _authToken;
  static void setAuthToken(String? token) => _authToken = token;

  static Map<String, String> _headers([String? token]) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final authToken = token ?? _authToken;
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  static Uri _uri(String path) => Uri.parse('$baseUrl$path');

  static Future<http.Response> _get(String path, {String? token}) =>
      _client.get(_uri(path), headers: _headers(token));

  static Future<http.Response> _post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) => _client.post(
    _uri(path),
    headers: _headers(token),
    body: jsonEncode(body),
  );

  static Future<http.Response> _put(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) =>
      _client.put(_uri(path), headers: _headers(token), body: jsonEncode(body));

  static Future<http.Response> _delete(String path, {String? token}) =>
      _client.delete(_uri(path), headers: _headers(token));

  static T _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) onSuccess,
    T defaultValue,
  ) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return onSuccess(data);
    } else if (response.statusCode == 401) {
      print(
        'Unauthorized request to ${response.request?.url}. Token may be invalid or expired.',
      );
      return defaultValue;
    }
    print(
      'Request failed with status ${response.statusCode}: ${response.body}',
    );
    return defaultValue;
  }

  static Future<List<ParkingLot>> getParkingLots({
    String? query,
    String? token,
  }) async {
    try {
      final params = <String, String>{
        '_t': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      if (query != null && query.isNotEmpty) {
        params['query'] = query;
      }
      final res = await _get('/lots?${Uri(queryParameters: params).query}', token: token);
      print('GET /lots status: ${res.statusCode}, body: ${res.body}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List<dynamic>) {
          return data.map((item) => ParkingLot.fromJson(item)).toList();
        }
        print('Invalid data type: ${data.runtimeType}');
        return [];
      }
      return [];
    } catch (e) {
      print('getParkingLots error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getSpotsWithDetails({String? token}) async {
    try {
      final res = await _get('/spots/details', token: token);
      print('GET /spots/details status: ${res.statusCode}, body: ${res.body}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List<dynamic>) return data.cast<Map<String, dynamic>>();
        print('Invalid data type: ${data.runtimeType}');
        return [];
      }
      return [];
    } catch (e) {
      print('getSpotsWithDetails error: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getReservations({
    String? userId,
    String? token,
  }) async {
    try {
      final res = await _get('/reservations', token: token);
      print('GET /reservations status: ${res.statusCode}, body: ${res.body}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List<dynamic>) return data;
        print('Invalid data type: ${data.runtimeType}');
        return [];
      }
      return [];
    } catch (e) {
      print('getReservations error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getSummary({String? token}) async {
    try {
      final res = await _get('/admin/summary', token: token);
      print('GET /summary status: ${res.statusCode}, body: ${res.body}');
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('getSummary error: $e');
      return {};
    }
  }

  static Future<ParkingLot?> createParkingLot(
    Map<String, dynamic> data, {
    String? token,
  }) async {
    try {
      final res = await _post('/admin/lots', data, token: token);
      print('POST /lots status: ${res.statusCode}, body: ${res.body}');
      if (res.statusCode == 201) {
        final jsonData = jsonDecode(res.body) as Map<String, dynamic>;
        return ParkingLot.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      print('createParkingLot error: $e');
      return null;
    }
  }

  static Future<bool> updateParkingLot(
    String id,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    try {
      final res = await _put('/admin/lots/$id', data, token: token);
      print('PUT /lots/$id status: ${res.statusCode}, body: ${res.body}');
      return res.statusCode == 200;
    } catch (e) {
      print('updateParkingLot error: $e');
      return false;
    }
  }

  static Future<bool> deleteParkingLot(
    String id, {
    String? token,
  }) async {
    try {
      final res = await _delete('/admin/lots/$id', token: token);
      print('DELETE /lots/$id status: ${res.statusCode}, body: ${res.body}');
      return res.statusCode == 200;
    } catch (e) {
      print('deleteParkingLot error: $e');
      return false;
    }
  }

  static Future<http.Response> getSpotDetails(
    String spotId, {
    String? token,
  }) async {
    try {
      final res = await _get('/spots/$spotId/details', token: token);
      print('GET /spots/$spotId/details status: ${res.statusCode}, body: ${res.body}');
      return res;
    } catch (e) {
      print('getSpotDetails error: $e');
      return http.Response('{"error": "$e"}', 500);
    }
  }

  static Future<User?> login(String username, String password) async {
    final res = await _post('/auth/login', {
      'username': username,
      'password': password,
    }, token: '');

    return _handleResponse<User?>(res, (data) {
      final user = User.fromJson(data);
      setAuthToken(user.token);
      return user;
    }, null);
  }

  static void logout() {
    setAuthToken(null);
  }

  static Future<Map<String, dynamic>?> releaseReservation(String resvId, {String? token}) async {
    if (resvId.isEmpty) {
      print('releaseReservation: Empty resvId, skipping.');
      return null;
    }

    try {
      final res = await _put('/reservations/$resvId/release', {}, token: token);
      print('PUT /reservations/$resvId/release - Status: ${res.statusCode} - Body: ${res.body}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data; // e.g., {'message': 'Released', 'cost': 5.25}
      }
      return null;
    } catch (e) {
      print('releaseReservation error: $e');
      return null;
    }
  }

  static Future<User?> register(
    String username,
    String password,
    String role,
  ) async {
    final res = await _post('/auth/register', {
      'username': username,
      'password': password,
      'role': role,
    }, token: '');
    print('POST /auth/register status: ${res.statusCode}');
    if (res.statusCode == 201) {
      final user = User.fromJson(jsonDecode(res.body));
      setAuthToken(user.token);
      return user;
    }
    return null;
  }

  static Future<bool> reserveSpot(
    String lotId,
    String vehicleNumber, {
    String? token,
  }) async {
    try {
      final data = {'lotId': lotId, 'vehicleNumber': vehicleNumber};
      final res = await _post('/reservations', data, token: token);
      print('POST /reservations status: ${res.statusCode}, body: ${res.body}');
      return res.statusCode == 201;
    } catch (e) {
      print('reserveSpot error: $e');
      return false;
    }
  }
}