import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
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

  // --- Users API ---
  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final url = Uri.parse('$baseUrl/users');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
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
            headers: {'Content-Type': 'application/json'},
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
            headers: {'Content-Type': 'application/json'},
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
      final response = await http.delete(url).timeout(const Duration(seconds: 5));
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
      final response = await http.get(url).timeout(const Duration(seconds: 5));
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
            headers: {'Content-Type': 'application/json'},
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
            headers: {'Content-Type': 'application/json'},
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
      final response = await http.delete(url).timeout(const Duration(seconds: 5));
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
      final response = await http.get(url).timeout(const Duration(seconds: 5));
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

  // --- Inspections & AI YOLOv12 API ---

  /// Fetch list of all Inspections from Go Backend API (GET /api/inspections)
  static Future<List<Map<String, dynamic>>> getInspections() async {
    try {
      final url = Uri.parse('$baseUrl/inspections');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
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
    String status = 'inProgress',
  }) async {
    try {
      final url = Uri.parse('$baseUrl/inspections');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'vehicleId': vehicleId,
              'nopol': nopol,
              'merk': merk,
              'tipe': tipe,
              'jenis': jenis,
              'employeeId': employeeId,
              'status': status,
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
      final response = await http.delete(url).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ Error deleting inspection at $baseUrl: $e');
      return false;
    }
  }
}
