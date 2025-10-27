// ============================================
// File: lib/services/api_service.dart
// FIXED WITH YOUR IP ADDRESS: 172.22.9.143
// ============================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/parking_lot.dart';
import '../models/user.dart';

class ApiService {
  // ============================================
  // UPDATED WITH YOUR IP ADDRESS
  // ============================================
  static const String baseUrl = 'http://localhost:3000';

  static String? _authToken;

  static void setAuthToken(String? token) {
    _authToken = token;
    print('Auth token set: ${token != null ? "Yes" : "No"}');
  }

  static void logout() {
    _authToken = null;
  }

  static Map<String, String> _getHeaders({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    final authToken = token ?? _authToken;
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  // ============================================
  // AUTH ENDPOINTS
  // ============================================
  static Future<User?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      print('Login response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);
        user.token = data['token'];
        setAuthToken(user.token);
        return user;
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null ;
    }
  }

  static Future<User?> register(
    String username,
    String password,
    String role,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'role': role,
        }),
      );

      print('Register response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);
        user.token = data['token'];
        setAuthToken(user.token);
        return user;
      }
      return null;
    } catch (e) {
      print('Register error: $e');
      return null;
    }
  }

  // ============================================
  // PARKING LOT ENDPOINTS (Admin)
  // ============================================
  static Future<List<ParkingLot>> getParkingLots({
    String? query,
    String? token,
  }) async {
    try {
      final uri = query != null && query.isNotEmpty
          ? Uri.parse('$baseUrl/parking-lots?search=$query')
          : Uri.parse('$baseUrl/parking-lots');

      final response = await http.get(uri, headers: _getHeaders(token: token));

      print('Get lots response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ParkingLot.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get lots error: $e');
      return [];
    }
  }

  static Future<ParkingLot?> createParkingLot(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/parking-lots'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );

      print('Create lot response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ParkingLot.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Create lot error: $e');
      return null;
    }
  }

  static Future<bool> updateParkingLot(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/parking-lots/$id'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );

      print('Update lot response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Update lot error: $e');
      return false;
    }
  }

  static Future<bool> deleteParkingLot(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/parking-lots/$id'),
        headers: _getHeaders(),
      );

      print('Delete lot response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Delete lot error: $e');
      return false;
    }
  }

  // ============================================
  // PARKING SPOTS ENDPOINTS (Admin)
  // ============================================
  static Future<List<Map<String, dynamic>>> getSpotsWithDetails({
    String? token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/parking-spots/details'),
        headers: _getHeaders(token: token),
      );

      print('Get spots with details response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Get spots error: $e');
      return [];
    }
  }

  static Future<http.Response> getSpotDetails(String spotId) async {
    try {
      return await http.get(
        Uri.parse('$baseUrl/parking-spots/$spotId'),
        headers: _getHeaders(),
      );
    } catch (e) {
      print('Get spot details error: $e');
      rethrow;
    }
  }

  // ============================================
  // ADMIN SUMMARY ENDPOINT
  // ============================================
  static Future<Map<String, dynamic>?> getSummary({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/summary'),
        headers: _getHeaders(token: token),
      );

      print('Get summary response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Get summary error: $e');
      return null;
    }
  }

  // ============================================
  // USER BOOKING ENDPOINTS (Task 1 - New)
  // ============================================

  // Get real-time parking statistics
  static Future<Map<String, dynamic>> getParkingStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/parking-stats'),
        headers: _getHeaders(),
      );

      print(
        'Parking stats response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {
        'success': false,
        'stats': {'total': 160, 'occupied': 0, 'available': 160, 'blocks': []},
      };
    } catch (e) {
      print('Get parking stats error: $e');
      return {
        'success': false,
        'stats': {'total': 160, 'occupied': 0, 'available': 160, 'blocks': []},
      };
    }
  }

  // Create new booking
  static Future<Map<String, dynamic>> createBooking({
    required String userId,
    required String vehicleNumber,
    required String blockId,
    String? slotNumber,
    int? floorNumber,
  }) async {
    try {
      final body = <String, dynamic>{
        'userId': userId,
        'vehicleNumber': vehicleNumber,
        'blockId': blockId,
      };

      if (slotNumber != null) body['slotNumber'] = slotNumber;
      if (floorNumber != null) body['floor'] = floorNumber;

      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      print(
        'Create booking response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception('Booking failed: ${response.body}');
    } catch (e) {
      print('Create booking error: $e');
      rethrow;
    }
  }

  // Update payment status
  static Future<Map<String, dynamic>> updatePaymentStatus({
    required String bookingId,
    required String paymentStatus,
    String? transactionId,
  }) async {
    try {
      final body = {'paymentStatus': paymentStatus};

      if (transactionId != null) {
        body['transactionId'] = transactionId;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/bookings/$bookingId/payment'),
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      print(
        'Update payment response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception('Payment update failed: ${response.body}');
    } catch (e) {
      print('Update payment error: $e');
      rethrow;
    }
  }

  // Cancel booking
  static Future<bool> cancelBooking(String bookingId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: _getHeaders(),
      );

      print('Cancel booking response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Cancel booking error: $e');
      return false;
    }
  }

  // Get user's bookings
  static Future<List<Map<String, dynamic>>> getUserBookings(
    String userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/user/$userId'),
        headers: _getHeaders(),
      );

      print('Get user bookings response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['bookings'] != null) {
          return List<Map<String, dynamic>>.from(data['bookings']);
        }
      }
      return [];
    } catch (e) {
      print('Get user bookings error: $e');
      return [];
    }
  }
}
