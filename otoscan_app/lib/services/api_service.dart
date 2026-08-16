import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Authentication state stored in memory
  static String? authToken;
  static Map<String, dynamic>? currentUser;

  // Dynamically resolve backend host URL:
  // - Android Emulator: 10.0.2.2:8080
  // - Windows / macOS / Web: localhost:8080
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8080/api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8080/api';
    } catch (_) {}
    return 'http://localhost:8080/api';
  }

  static String get serverBaseUrl {
    final b = baseUrl;
    if (b.endsWith('/api')) {
      return b.substring(0, b.length - 4);
    }
    return b;
  }

  // Request Headers with optional Authorization Bearer Token
  static Map<String, String> get authHeaders {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  // --- Auth API ---
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email.trim(),
              'password': password.trim(),
            }),
          )
          .timeout(const Duration(seconds: 8));

      final body = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['status'] == 'success') {
        authToken = body['token']?.toString();
        currentUser = body['user'] as Map<String, dynamic>?;
        debugPrint('✅ Login successful for ${currentUser?['email']} with role: ${currentUser?['role']}');
        return {'success': true, 'data': body};
      }
      return {
        'success': false,
        'message': body['message'] ?? 'Login gagal. Periksa kembali email dan password.',
      };
    } catch (e) {
      debugPrint('⚠️ Error in login: $e');
      return {
        'success': false,
        'message': 'Gagal terhubung ke server backend ($e)',
      };
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/register');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'name': name.trim(),
              'email': email.trim(),
              'password': password.trim(),
              'phone': phone.trim(),
              'address': address.trim(),
            }),
          )
          .timeout(const Duration(seconds: 8));

      final body = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201 && body['status'] == 'success') {
        authToken = body['token']?.toString();
        currentUser = body['user'] as Map<String, dynamic>?;
        return {'success': true, 'data': body};
      }
      return {
        'success': false,
        'message': body['message'] ?? 'Registrasi gagal.',
      };
    } catch (e) {
      debugPrint('⚠️ Error in register: $e');
      return {
        'success': false,
        'message': 'Gagal terhubung ke server backend ($e)',
      };
    }
  }

  static Future<void> logout() async {
    try {
      final url = Uri.parse('$baseUrl/auth/logout');
      await http.post(url, headers: authHeaders).timeout(const Duration(seconds: 4));
    } catch (_) {}
    authToken = null;
    currentUser = null;
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final url = Uri.parse('$baseUrl/auth/me');
      final response = await http.get(url, headers: authHeaders).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        currentUser = body['data'] as Map<String, dynamic>?;
        return currentUser;
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching profile: $e');
    }
    return null;
  }

  static Future<bool> updateProfile({
    String? name,
    String? password,
    String? phone,
    String? address,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/me');
      final response = await http
          .put(
            url,
            headers: authHeaders,
            body: json.encode({
              if (name != null) 'name': name,
              if (password != null && password.isNotEmpty) 'password': password,
              if (phone != null) 'phone': phone,
              if (address != null) 'address': address,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        currentUser = body['data'] as Map<String, dynamic>?;
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ Error updating profile: $e');
    }
    return false;
  }

  // --- Users API (Admin) ---
  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final url = Uri.parse('$baseUrl/users');
      final response = await http.get(url, headers: authHeaders).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List data = body['data'] ?? [];
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching users from $baseUrl: $e');
    }
    return [];
  }

  static Future<bool> createUser({
    required String name,
    required String email,
    required String phone,
    required String address,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/users');
      final response = await http
          .post(
            url,
            headers: authHeaders,
            body: json.encode({
              'name': name,
              'email': email.isEmpty ? null : email,
              'phone': phone,
              'address': address,
            }),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ Error creating user at $baseUrl: $e');
      return false;
    }
  }

  static Future<bool> updateUser({
    required String id,
    required String name,
    required String email,
    required String phone,
    required String address,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/users/$id');
      final response = await http
          .put(
            url,
            headers: authHeaders,
            body: json.encode({
              'name': name,
              'email': email.isEmpty ? null : email,
              'phone': phone,
              'address': address,
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      debugPrint('⚠️ Update User failed (${response.statusCode}): ${response.body}');
    } catch (e) {
      debugPrint('⚠️ Error updating user at $baseUrl: $e');
    }
    return false;
  }

  static Future<bool> deleteUser(String id) async {
    try {
      final url = Uri.parse('$baseUrl/users/$id');
      final response = await http.delete(url, headers: authHeaders).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ Error deleting user at $baseUrl: $e');
      return false;
    }
  }

  // --- Vehicles API ---
  static Future<List<Map<String, dynamic>>> getVehicles() async {
    try {
      final url = Uri.parse('$baseUrl/vehicles');
      final response = await http.get(url, headers: authHeaders).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List data = body['data'] ?? [];
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching vehicles from $baseUrl: $e');
    }
    return [];
  }

  static Future<bool> createVehicle({
    required String nopol,
    required String merk,
    required String tipe,
    required String jenis,
    String? userId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/vehicles');
      final response = await http
          .post(
            url,
            headers: authHeaders,
            body: json.encode({
              'nopol': nopol,
              'merk': merk,
              'tipe': tipe,
              'jenis': jenis,
              'user_id': userId,
            }),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ Error creating vehicle at $baseUrl: $e');
      return false;
    }
  }

  static Future<bool> updateVehicle({
    required String id,
    required String nopol,
    required String merk,
    required String tipe,
    required String jenis,
    String? userId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/vehicles/$id');
      final response = await http
          .put(
            url,
            headers: authHeaders,
            body: json.encode({
              'nopol': nopol,
              'merk': merk,
              'tipe': tipe,
              'jenis': jenis,
              'user_id': userId,
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      debugPrint('⚠️ Update Vehicle failed (${response.statusCode}): ${response.body}');
    } catch (e) {
      debugPrint('⚠️ Error updating vehicle at $baseUrl: $e');
    }
    return false;
  }

  static Future<bool> deleteVehicle(String id) async {
    try {
      final url = Uri.parse('$baseUrl/vehicles/$id');
      final response = await http.delete(url, headers: authHeaders).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ Error deleting vehicle at $baseUrl: $e');
      return false;
    }
  }

  // --- Employees API ---
  static Future<List<Map<String, dynamic>>> getEmployees() async {
    try {
      final url = Uri.parse('$baseUrl/employees');
      final response = await http.get(url, headers: authHeaders).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List data = body['data'] ?? [];
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching employees from $baseUrl: $e');
    }
    return [];
  }

  /// Fetch list of master Inspection Statuses from Go Backend API (GET /api/master/inspection-statuses)
  static Future<List<Map<String, dynamic>>> getInspectionStatuses() async {
    try {
      final url = Uri.parse('$baseUrl/master/inspection-statuses');
      final response = await http.get(url, headers: authHeaders).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List data = body['data'] ?? [];
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching master inspection statuses: $e');
    }
    return [];
  }

  // --- Inspections & AI YOLOv12 API ---

  /// Fetch list of all Inspections from Go Backend API (GET /api/inspections)
  static Future<List<Map<String, dynamic>>> getInspections() async {
    try {
      final url = Uri.parse('$baseUrl/inspections');
      final response = await http.get(url, headers: authHeaders).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List data = body['data'] ?? [];
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching inspections from $baseUrl: $e');
    }
    return [];
  }

  /// 1. Create a new Inspection record on Go Backend API
  static Future<String?> createInspection({
    String? vehicleId,
    String? nopol,
    String? merk,
    String? tipe,
    String? jenis,
    String? employeeId,
    String? statusId,
    String status = 'inProgress',
  }) async {
    try {
      final url = Uri.parse('$baseUrl/inspections');
      final response = await http
          .post(
            url,
            headers: authHeaders,
            body: json.encode({
              'vehicleId': vehicleId,
              'nopol': nopol,
              'merk': merk,
              'tipe': tipe,
              'jenis': jenis,
              'employeeId': employeeId,
              'statusId': statusId,
              'status': statusId ?? status,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = json.decode(response.body);
        final data = body['data'];
        if (data != null && data['id'] != null) {
          debugPrint('✅ Inspection created successfully on backend with ID: ${data['id']}');
          return data['id'].toString();
        }
      }
      debugPrint('⚠️ Create Inspection failed (${response.statusCode}): ${response.body}');
    } catch (e) {
      debugPrint('⚠️ Error creating inspection at $baseUrl: $e');
    }
    return null;
  }

  /// 2. Upload photo per angle and run YOLOv12 AI detection on Go Backend API
  static Future<Map<String, dynamic>?> detectDamageAI({
    required String inspectionId,
    required String imagePath,
    required String angleName,
    String? angleCaptureId,
    Uint8List? imageBytes,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/inspections/$inspectionId/detect');
      final request = http.MultipartRequest('POST', url);

      if (authToken != null && authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      request.fields['angleName'] = angleName;
      if (angleCaptureId != null && angleCaptureId.isNotEmpty) {
        request.fields['angleCaptureId'] = angleCaptureId;
      }

      if (imageBytes != null && imageBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: '${angleName.replaceAll(' ', '_').toLowerCase()}.jpg',
          ),
        );
      } else if (imagePath.isNotEmpty && File(imagePath).existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imagePath,
          ),
        );
      } else {
        debugPrint('⚠️ Image file or bytes are empty for AI detection');
        return null;
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ AI Detection completed on Go Backend: ${response.body}');
        return json.decode(response.body) as Map<String, dynamic>;
      }
      debugPrint('⚠️ AI Detection failed (${response.statusCode}): ${response.body}');
    } catch (e) {
      debugPrint('⚠️ Error in AI detection at $baseUrl: $e');
    }
    return null;
  }

  static Future<bool> deleteInspection(String id) async {
    try {
      final url = Uri.parse('$baseUrl/inspections/$id');
      final response = await http.delete(url, headers: authHeaders).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ Error deleting inspection at $baseUrl: $e');
      return false;
    }
  }
}
