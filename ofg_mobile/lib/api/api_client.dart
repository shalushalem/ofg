// lib/api/api_client.dart
// OFG Connects – HTTP client + secure storage helpers

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ofg_models.dart';

// ---------------------------------------------------------------------------
// Compile-time constant – override via --dart-define=BASE_URL=...
// ---------------------------------------------------------------------------
const String kDefaultApiBase =
    String.fromEnvironment('BASE_URL', defaultValue: 'https://ofg-connects-production.up.railway.app');

// ---------------------------------------------------------------------------
// ApiException
// ---------------------------------------------------------------------------

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ---------------------------------------------------------------------------
// ApiClient
// ---------------------------------------------------------------------------

class ApiClient {
  final String baseUrl;
  String? token;

  // Shared HTTP client for connection reuse
  final http.Client _httpClient;

  static const Duration _timeout = Duration(seconds: 15);

  ApiClient({required this.baseUrl, this.token})
      : _httpClient = http.Client();

  // -------------------------------------------------------------------------
  // Header builders
  // -------------------------------------------------------------------------

  Map<String, String> get _jsonHeaders {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, String> _adminHeaders({bool includeJson = true}) {
    return {
      if (includeJson) 'Content-Type': 'application/json',
      if (includeJson) 'Accept': 'application/json',
      if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      'X-Admin-Secret': 'ofg_admin_2024',
    };
  }

  // -------------------------------------------------------------------------
  // URL builder
  // -------------------------------------------------------------------------

  Uri _uri(String path) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p');
  }

  // -------------------------------------------------------------------------
  // Response parser
  // -------------------------------------------------------------------------

  dynamic _parse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return <String, dynamic>{};
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    }

    String message;
    try {
      final decoded = jsonDecode(response.body);
      message = (decoded is Map)
          ? (decoded['message'] ??
              decoded['error'] ??
              decoded['msg'] ??
              response.reasonPhrase ??
              'Request failed')
          : response.reasonPhrase ?? 'Request failed';
    } catch (_) {
      message = response.body.isNotEmpty
          ? response.body
          : (response.reasonPhrase ?? 'Request failed');
    }

    throw ApiException(message.toString(), statusCode: response.statusCode);
  }

  // -------------------------------------------------------------------------
  // GET
  // -------------------------------------------------------------------------

  Future<dynamic> get(String path, {bool admin = false}) async {
    try {
      final response = await _httpClient
          .get(_uri(path), headers: admin ? _adminHeaders() : _jsonHeaders)
          .timeout(_timeout);
      return _parse(response);
    } on SocketException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } on TimeoutException {
      throw const ApiException('Request timed out. Check your connection.');
    }
  }

  // -------------------------------------------------------------------------
  // POST
  // -------------------------------------------------------------------------

  Future<dynamic> post(String path, Map<String, dynamic> body,
      {bool admin = false}) async {
    try {
      final response = await _httpClient
          .post(
            _uri(path),
            headers: admin ? _adminHeaders() : _jsonHeaders,
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _parse(response);
    } on SocketException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } on TimeoutException {
      throw const ApiException('Request timed out. Check your connection.');
    }
  }

  // -------------------------------------------------------------------------
  // PUT
  // -------------------------------------------------------------------------

  Future<dynamic> put(String path, Map<String, dynamic> body,
      {bool admin = false}) async {
    try {
      final response = await _httpClient
          .put(
            _uri(path),
            headers: admin ? _adminHeaders() : _jsonHeaders,
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _parse(response);
    } on SocketException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } on TimeoutException {
      throw const ApiException('Request timed out. Check your connection.');
    }
  }

  // -------------------------------------------------------------------------
  // DELETE
  // -------------------------------------------------------------------------

  Future<dynamic> delete(String path, {bool admin = false}) async {
    try {
      final response = await _httpClient
          .delete(_uri(path), headers: admin ? _adminHeaders() : _jsonHeaders)
          .timeout(_timeout);
      return _parse(response);
    } on SocketException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } on TimeoutException {
      throw const ApiException('Request timed out. Check your connection.');
    }
  }

  // -------------------------------------------------------------------------
  // streamedUpload – Memory-Safe Upload to Pre-signed URL
  // -------------------------------------------------------------------------

  Future<void> streamedUpload(
    String uploadUrl,
    File file,
    String contentType,
  ) async {
    try {
      final uri = Uri.parse(uploadUrl);
      final length = await file.length();
      
      final request = http.StreamedRequest('PUT', uri)
        ..contentLength = length
        ..headers['Content-Type'] = contentType;

      // Stream the file chunk by chunk to prevent OOM crashes
      file.openRead().listen(
        request.sink.add,
        onDone: request.sink.close,
        onError: request.sink.addError,
      );

      // Increased timeout to 60 minutes for large videos
      final streamedResponse = await _httpClient
          .send(request)
          .timeout(const Duration(minutes: 60));

      if (streamedResponse.statusCode < 200 ||
          streamedResponse.statusCode >= 300) {
        final body = await streamedResponse.stream.bytesToString();
        throw ApiException(
          'Upload failed: $body',
          statusCode: streamedResponse.statusCode,
        );
      }
    } on SocketException catch (e) {
      throw ApiException('Network error during upload: ${e.message}');
    } on TimeoutException {
      throw const ApiException('Upload timed out. Check your connection.');
    }
  }

  /// Upload a file via the Railway proxy server → Railway uploads to R2.
  /// Use this instead of [streamedUpload] on mobile — direct phone→R2
  /// connections fail on some Indian ISPs (errno 103 ECONNABORTED).
  Future<Map<String, dynamic>> uploadViaProxy(
    File file,
    String filename,
    String contentType, {
    String type = 'video',
    void Function(double progress)? onProgress,
  }) async {
    try {
      final fileLength = await file.length();
      
      // Using native dart:io HttpClient to completely avoid http package memory limits
      // This streams data chunk-by-chunk directly from storage into the network socket.
      final client = HttpClient();
      client.connectionTimeout = const Duration(minutes: 60);
      
      final request = await client.postUrl(_uri('/upload/proxy'));
      request.headers.set('Authorization', 'Bearer ${token ?? ""}');
      request.headers.set('Content-Type', contentType);
      request.headers.set('X-Filename', filename);
      request.headers.set('X-Upload-Type', type);
      request.contentLength = fileLength;
      
      int bytesSent = 0;
      final stream = file.openRead().map((chunk) {
        bytesSent += chunk.length;
        if (fileLength > 0) {
          onProgress?.call(bytesSent / fileLength);
        }
        return chunk;
      });
      
      await request.addStream(stream);
      final response = await request.close();
      
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(body) as Map<String, dynamic>;
      }
      throw ApiException('Upload failed (${response.statusCode}): $body',
          statusCode: response.statusCode);
    } on SocketException catch (e) {
      throw ApiException('Network error during upload: ${e.message}');
    } on TimeoutException {
      throw const ApiException('Upload timed out after 60 minutes.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Upload failed: $e');
    }
  }



  // -------------------------------------------------------------------------
  // Convenience API methods
  // -------------------------------------------------------------------------

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await post('/auth/login', {
      'email': email,
      'password': password,
    });
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final res = await post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async {
    final res = await get('/auth/me');
    return res as Map<String, dynamic>;
  }

  Future<void> logout() async {
    try {
      await delete('/auth/logout');
    } catch (_) {
      // Ignore logout errors – clear local state regardless
    }
  }

  // Feed
  Future<Map<String, dynamic>> getFeed({
    String? category,
    int page = 0,
    int limit = 30,
  }) async {
    final query = StringBuffer('/feed?page=$page&limit=$limit');
    if (category != null && category.isNotEmpty) {
      query.write('&category=${Uri.encodeComponent(category)}');
    }
    final res = await get(query.toString());
    return res as Map<String, dynamic>;
  }

  // Shorts
  Future<Map<String, dynamic>> getShorts({int page = 0, int limit = 20}) async {
    final res = await get('/shorts?page=$page&limit=$limit');
    return res as Map<String, dynamic>;
  }

  // Search
  Future<Map<String, dynamic>> search({
    required String q,
    String? category,
    int page = 0,
  }) async {
    final query = StringBuffer('/search?q=${Uri.encodeComponent(q)}&page=$page');
    if (category != null && category.isNotEmpty) {
      query.write('&category=${Uri.encodeComponent(category)}');
    }
    final res = await get(query.toString());
    return res as Map<String, dynamic>;
  }

  // Video
  Future<Map<String, dynamic>> getVideo(String id) async {
    final res = await get('/videos/$id');
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> likeVideo(String id) async {
    final res = await post('/videos/$id/like', {});
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> saveVideo(String id) async {
    final res = await post('/videos/$id/save', {});
    return res as Map<String, dynamic>;
  }

  Future<void> postWatch(String id,
      {required int watchTime,
      required double completionRate,
      required double progress}) async {
    await post('/videos/$id/watch', {
      'watchTime': watchTime,
      'completionRate': completionRate,
      'progress': progress,
    });
  }

  // Comments
  Future<Map<String, dynamic>> getComments(String videoId) async {
    final res = await get('/videos/$videoId/comments');
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postComment(
      String videoId, String content) async {
    final res = await post('/videos/$videoId/comments', {'content': content});
    return res as Map<String, dynamic>;
  }

  // Follow
  Future<Map<String, dynamic>> follow(String userId) async {
    final res = await post('/follow/$userId', {});
    return res as Map<String, dynamic>;
  }

  // User profile
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final res = await get('/users/$userId');
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) async {
    final res = await put('/users/me', data);
    return res as Map<String, dynamic>;
  }

  // Upload
  Future<Map<String, dynamic>> initUpload(
      {required String filename, required String contentType, String type = 'video'}) async {
    final res = await post('/upload/init', {
      'filename': filename,
      'contentType': contentType,
      'type': type,
    });
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitUpload({
    required String title,
    required String description,
    required String category,
    required String mediaUrl,
    required String thumbnailUrl,
    required String duration,
    required bool isShort,
  }) async {
    final res = await post('/upload', {
      'title': title,
      'description': description,
      'category': category,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'isShort': isShort,
    });
    return res as Map<String, dynamic>;
  }

  // Creator
  Future<Map<String, dynamic>> getCreatorStats() async {
    final res = await get('/creator/stats');
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCreatorVideos() async {
    final res = await get('/creator/videos');
    return res as Map<String, dynamic>;
  }

  // Library
  Future<Map<String, dynamic>> getHistory() async {
    final res = await get('/library/history');
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSaved() async {
    final res = await get('/library/saved');
    return res as Map<String, dynamic>;
  }

  // Settings
  Future<Map<String, dynamic>> getSettings() async {
    final res = await get('/settings');
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postSetting(String key, dynamic value) async {
    final res = await post('/settings', {'key': key, 'value': value});
    return res as Map<String, dynamic>;
  }

  // Notifications
  Future<Map<String, dynamic>> getNotifications() async {
    final res = await get('/notifications');
    return res as Map<String, dynamic>;
  }

  Future<void> readAllNotifications() async {
    await post('/notifications/read-all', {});
  }

  // Reports
  Future<void> submitReport({
    required String type,
    required String targetId,
    required String reason,
  }) async {
    await post('/reports', {
      'type': type,
      'targetId': targetId,
      'reason': reason,
    });
  }

  // Admin
  Future<Map<String, dynamic>> adminGetVideos() async {
    final res = await get('/admin/videos', admin: true);
    return res as Map<String, dynamic>;
  }

  Future<void> adminFeatureVideo(String id) async {
    await post('/admin/videos/$id/feature', {});
  }

  Future<void> adminDeleteVideo(String id) async {
    await delete('/admin/videos/$id', admin: true);
  }

  Future<void> adminBanUser(String id) async {
    await post('/admin/users/$id/ban', {});
  }

  Future<Map<String, dynamic>> adminGetReports() async {
    final res = await get('/admin/reports', admin: true);
    return res as Map<String, dynamic>;
  }

  Future<void> adminResolveReport(String id, String status) async {
    await post('/admin/reports/$id/resolve', {'status': status});
  }

  void dispose() {
    _httpClient.close();
  }

  // ==========================================================================
  // Donation System API
  // ==========================================================================

  Future<Map<String, dynamic>> donate({
    required String creatorId,
    required double amount,
    String message = '',
    bool isAnonymous = false,
  }) async {
    final result = await post('/donations', {
      'creatorId': creatorId,
      'amount': amount,
      'message': message,
      'isAnonymous': isAnonymous,
    });
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> getDonationHistory({int page = 0}) async {
    final result = await get('/donations/history?page=$page');
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> getCreatorWallet() async {
    final result = await get('/creator/wallet');
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> getPublicWallet(String creatorId) async {
    final result = await get('/users/$creatorId/wallet');
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> getCreatorDonations({int page = 0}) async {
    final result = await get('/creator/donations?page=$page');
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> getCreatorPayouts({int page = 0}) async {
    final result = await get('/creator/payouts?page=$page');
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> requestPayout(double amount) async {
    final result = await post('/creator/payouts', {'amount': amount});
    return Map<String, dynamic>.from(result as Map);
  }

  Future<void> updatePayoutAccount(String payoutAccount) async {
    await post('/creator/wallet/payout-account', {'payoutAccount': payoutAccount});
  }

  Future<Map<String, dynamic>> getAdminDonations({int page = 0, String status = ''}) async {
    final result = await get('/admin/donations?page=$page&status=$status', admin: true);
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> getAdminPayouts({int page = 0, String status = 'pending'}) async {
    final result = await get('/admin/payouts?page=$page&status=$status', admin: true);
    return Map<String, dynamic>.from(result as Map);
  }

  Future<void> approveAdminPayout(String payoutId) async {
    await post('/admin/payouts/$payoutId/approve', {}, admin: true);
  }

  Future<void> rejectAdminPayout(String payoutId, String reason) async {
    await post('/admin/payouts/$payoutId/reject', {'reason': reason}, admin: true);
  }
}

// ---------------------------------------------------------------------------
// findLocalServer – scans 192.168.x.x:8787 for a running OFG server
// ---------------------------------------------------------------------------

Future<String?> findLocalServer({
  String subnetPrefix = '192.168.1',
  int port = 8787,
  Duration timeout = const Duration(milliseconds: 400),
}) async {
  final candidates = [
    for (int i = 1; i <= 254; i++) '$subnetPrefix.$i',
  ];

  const batchSize = 30;
  for (int b = 0; b < candidates.length; b += batchSize) {
    final batch = candidates.skip(b).take(batchSize).toList();
    final futures = batch.map((host) => _probeHost(host, port, timeout));
    final results = await Future.wait(futures, eagerError: false);
    for (int i = 0; i < results.length; i++) {
      if (results[i] == true) {
        return 'http://${batch[i]}:$port';
      }
    }
  }
  return null;
}

Future<bool> _probeHost(String host, int port, Duration timeout) async {
  try {
    final socket =
        await Socket.connect(host, port, timeout: timeout);
    socket.destroy();
    return true;
  } catch (_) {
    return false;
  }
}

// ---------------------------------------------------------------------------
// OfgStorage – secure token + preferences-based URL/user cache
// ---------------------------------------------------------------------------

class OfgStorage {
  static const _tokenKey = 'ofg_token';
  static const _baseUrlKey = 'ofg_base_url';
  static const _userKey = 'ofg_user';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return _secureStorage.read(key: _tokenKey);
  }

  static Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  static Future<void> saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
  }

  static Future<String?> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey);
  }

  static Future<void> saveUser(OfgUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, user.toJsonString());
  }

  static Future<OfgUser?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_userKey);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return OfgUser.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    await clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}