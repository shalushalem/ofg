// lib/api/api_client.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.baseUrl});

  String baseUrl;
  String? token;
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);

  Future<dynamic> get(String path) => _request('GET', path);
  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _request('POST', path, body: body);

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}$path');
    final request = await _client.openUrl(method, uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    
    if (body != null) {
      final bytes = utf8.encode(jsonEncode(body));
      request.headers.set(HttpHeaders.contentLengthHeader, bytes.length.toString());
      request.add(bytes);
    }
    
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    final decoded = text.isEmpty ? null : jsonDecode(text);
    
    if (response.statusCode >= 400) {
      final message = decoded is Map && decoded['error'] != null
          ? decoded['error'].toString()
          : 'Server error ${response.statusCode}';
      throw ApiException(message);
    }
    return decoded;
  }
}

// --- SMART WI-FI SCANNER ---
Future<String?> findLocalServer() async {
  String? mySubnet;
  
  try {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          final parts = addr.address.split('.');
          mySubnet = '${parts[0]}.${parts[1]}.${parts[2]}';
          break;
        }
      }
      if (mySubnet != null) break;
    }
  } catch (_) {}

  List<String> subnets = mySubnet != null ? [mySubnet] : ['192.168.1', '192.168.0', '10.0.0'];

  for (String subnet in subnets) {
    List<Future<String?>> futures = [];
    for (int i = 1; i < 255; i++) {
      futures.add(Future(() async {
        String testIp = '$subnet.$i';
        try {
          final socket = await Socket.connect(
            testIp, 
            8787, 
            timeout: const Duration(milliseconds: 350)
          );
          socket.destroy();
          return 'http://$testIp:8787';
        } catch (_) {
          return null;
        }
      }));
    }
    
    List<String?> results = await Future.wait(futures);
    for (var res in results) {
      if (res != null) return res; 
    }
  }
  return null;
}