// flutter pub add http
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mfu_student_workspace/models/api_models.dart';
import 'package:mfu_student_workspace/services/auth_service.dart';

// ================= base =================
/// Error ที่ Controller โยนออกไป — ใช้ e.message แสดงใน SnackBar ได้เลย
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// ค่าที่ทุก Controller ใช้ร่วมกัน (baseURL, token, อ่าน response, จัดการ error)
class BaseController {
  // Android emulator ใช้ http://10.0.2.2:3000/api แทน localhost
  String get baseURL => 'http://localhost:3000/api';
  final authService = AuthService();

  /// header สำหรับ API ที่ต้อง login (ถ้าไม่มี token ให้โยน 401)
  Future<Map<String, String>> authHeaders({bool json = false}) async {
    final token = await authService.loadToken();
    if (token == null || token.isEmpty) {
      throw ApiException('Please log in again', statusCode: 401);
    }
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  /// ตรวจ status code แล้วแปลง body เป็น JSON
  /// ถ้า status ไม่ใช่ 2xx จะโยน ApiException พร้อมข้อความจาก backend ({ message })
  dynamic decode(http.Response response) {
    dynamic body;
    try {
      body = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      body = null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('Wrong status code: ${response.statusCode}');
      final msg = (body is Map && body['message'] is String)
          ? body['message'] as String
          : 'Server error (${response.statusCode})';
      throw ApiException(msg, statusCode: response.statusCode);
    }
    return body;
  }

  /// ครอบทุก request: timeout 10 วินาที + แปลง error ที่ไม่ใช่ ApiException เป็น 'Connection error'
  Future<T> guard<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(const Duration(seconds: 10));
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint(e.toString());
      throw ApiException('Connection error');
    }
  }
}

// ================= auth =================
class AuthController extends BaseController {
  // register -> POST /api/auth/register
  // สำเร็จ: ไม่คืนค่า | ซ้ำ: โยน ApiException('Student ID or email already exists')
  Future<void> register({
    required String studentId,
    required String fullName,
    required String email,
    required String password,
  }) {
    return guard(() async {
      final response = await http.post(
        Uri.parse('$baseURL/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': studentId,
          'full_name': fullName,
          'email': email,
          'password': password,
        }),
      );
      decode(response); // ไม่ใช่ 201 จะโยน error เอง
    });
  }

  // login -> POST /api/auth/login (username = student_id)
  // รหัสผิด: คืน null | สำเร็จ: บันทึก token แล้วคืนข้อมูลผู้ใช้
  Future<UserModel?> login(String studentId, String password) {
    return guard(() async {
      final response = await http.post(
        Uri.parse('$baseURL/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'student_id': studentId, 'password': password}),
      );
      if (response.statusCode == 401) {
        // wrong student id / password
        return null;
      }
      Map<String, dynamic> data = decode(response);
      // save token
      await authService.saveToken(data['token']);
      return UserModel.fromJSON(data['user']);
    });
  }

  // logout -> POST /api/auth/logout
  // JWT เป็น stateless: ต่อให้ server ตอบไม่ได้ ก็ต้องลบ token ในเครื่องเสมอ
  Future<void> logout() async {
    try {
      final headers = await authHeaders();
      await http
          .post(Uri.parse('$baseURL/auth/logout'), headers: headers)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // ignore
    } finally {
      await authService.removeToken();
    }
  }
}

// ================= user =================
class UserController extends BaseController {
  // getMe -> GET /api/users/me
  Future<UserModel> getMe() {
    return guard(() async {
      final response = await http.get(
        Uri.parse('$baseURL/users/me'),
        headers: await authHeaders(),
      );
      return UserModel.fromJSON(decode(response));
    });
  }

  // updateMe -> PUT /api/users/me
  // ส่งเฉพาะช่องที่ต้องการแก้ (fullName / avatarUrl / เปลี่ยนรหัสผ่าน)
  // หมายเหตุ: backend ยังไม่รองรับการแก้ email
  Future<void> updateMe({
    String? fullName,
    String? avatarUrl,
    String? currentPassword,
    String? newPassword,
  }) {
    return guard(() async {
      final body = <String, dynamic>{
        if (fullName != null) 'full_name': fullName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (newPassword != null) 'current_password': currentPassword,
        if (newPassword != null) 'new_password': newPassword,
      };
      final response = await http.put(
        Uri.parse('$baseURL/users/me'),
        headers: await authHeaders(json: true),
        body: jsonEncode(body),
      );
      decode(response);
    });
  }

  // getUser -> GET /api/users/:studentId  (ใช้ค้นหาชื่อก่อนเพิ่มสมาชิก)
  // ไม่พบผู้ใช้: คืน null
  Future<UserModel?> getUser(String studentId) {
    return guard(() async {
      final response = await http.get(
        Uri.parse('$baseURL/users/$studentId'),
        headers: await authHeaders(),
      );
      if (response.statusCode == 404) return null;
      return UserModel.fromJSON(decode(response));
    });
  }
}

// ================= project =================
class ProjectController extends BaseController {
  // list -> GET /api/projects (โปรเจคที่ฉันเป็นสมาชิก)
  Future<List<ProjectData>> getProjects() {
    return guard(() async {
      final response = await http.get(
        Uri.parse('$baseURL/projects'),
        headers: await authHeaders(),
      );
      List<dynamic> data = decode(response);
      return data.map((json) => ProjectData.fromJSON(json)).toList();
    });
  }

  // get -> GET /api/projects/:id (รายละเอียด + สมาชิก)
  Future<ProjectData> getProject(String id) {
    return guard(() async {
      final response = await http.get(
        Uri.parse('$baseURL/projects/$id'),
        headers: await authHeaders(),
      );
      return ProjectData.fromJSON(decode(response));
    });
  }

  // create -> POST /api/projects  (ผู้สร้างจะเป็น PC อัตโนมัติ) คืน id ของโปรเจคใหม่
  Future<String> createProject({
    required String title,
    String? courseCode,
    String? description,
    String? deadline, // YYYY-MM-DD
  }) {
    return guard(() async {
      final response = await http.post(
        Uri.parse('$baseURL/projects'),
        headers: await authHeaders(json: true),
        body: jsonEncode({
          'title': title,
          'course_code': courseCode,
          'description': description,
          'deadline': deadline,
        }),
      );
      Map<String, dynamic> data = decode(response);
      return data['id'] as String;
    });
  }

  // update -> PUT /api/projects/:id (PC เท่านั้น) ส่งเฉพาะช่องที่แก้
  Future<void> updateProject(
    String id, {
    String? title,
    String? courseCode,
    String? description,
    String? deadline,
  }) {
    return guard(() async {
      final body = <String, dynamic>{
        if (title != null) 'title': title,
        if (courseCode != null) 'course_code': courseCode,
        if (description != null) 'description': description,
        if (deadline != null) 'deadline': deadline,
      };
      final response = await http.put(
        Uri.parse('$baseURL/projects/$id'),
        headers: await authHeaders(json: true),
        body: jsonEncode(body),
      );
      decode(response);
    });
  }

  // delete -> DELETE /api/projects/:id (PC เท่านั้น)
  Future<void> deleteProject(String id) {
    return guard(() async {
      final response = await http.delete(
        Uri.parse('$baseURL/projects/$id'),
        headers: await authHeaders(),
      );
      decode(response);
    });
  }

  // dashboard -> GET /api/dashboard (สรุปงานของฉันทุกโปรเจค)
  Future<DashboardModel> getDashboard() {
    return guard(() async {
      final response = await http.get(
        Uri.parse('$baseURL/dashboard'),
        headers: await authHeaders(),
      );
      return DashboardModel.fromJSON(decode(response));
    });
  }

  // announce -> POST /api/projects/:id/announce (PC เท่านั้น) แจ้งเตือนสมาชิกทุกคน
  // คืนจำนวนคนที่ได้รับแจ้งเตือน
  Future<int> announce(
    String id, {
    required String title,
    required String message,
  }) {
    return guard(() async {
      final response = await http.post(
        Uri.parse('$baseURL/projects/$id/announce'),
        headers: await authHeaders(json: true),
        body: jsonEncode({'title': title, 'message': message}),
      );
      Map<String, dynamic> data = decode(response);
      return (data['sent'] ?? 0) as int;
    });
  }
}

// ================= member =================
class MemberController extends BaseController {
  // list -> GET /api/projects/:id/members
  Future<List<MemberModel>> getMembers(String projectId) {
    return guard(() async {
      final response = await http.get(
        Uri.parse('$baseURL/projects/$projectId/members'),
        headers: await authHeaders(),
      );
      List<dynamic> data = decode(response);
      return data.map((json) => MemberModel.fromJSON(json)).toList();
    });
  }

  // add -> POST /api/projects/:id/members (PC เท่านั้น)
  // สมาชิกที่เพิ่มทีหลังเป็น MEMBER เสมอ (schema มีแค่ PC / MEMBER)
  // 404 = ไม่มีผู้ใช้นี้ | 409 = เป็นสมาชิกอยู่แล้ว (ข้อความอยู่ใน ApiException.message)
  Future<void> addMember(String projectId, String studentId) {
    return guard(() async {
      final response = await http.post(
        Uri.parse('$baseURL/projects/$projectId/members'),
        headers: await authHeaders(json: true),
        body: jsonEncode({'student_id': studentId, 'project_role': 'MEMBER'}),
      );
      decode(response);
    });
  }

  // remove -> DELETE /api/projects/:id/members/:studentId (PC เท่านั้น, ลบ PC ไม่ได้)
  Future<void> removeMember(String projectId, String studentId) {
    return guard(() async {
      final response = await http.delete(
        Uri.parse('$baseURL/projects/$projectId/members/$studentId'),
        headers: await authHeaders(),
      );
      decode(response);
    });
  }
}
