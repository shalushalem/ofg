// lib/logic/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/ofg_models.dart';
import '../presentation/theme/ofg_theme.dart';

// 1. Core API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: kDefaultApiBase);
});

// 2. Current User State
final authStateProvider = StateProvider<OfgUser?>((ref) => null);

// 3. Real Video Feed Fetcher
final feedProvider = FutureProvider<List<OfgVideo>>((ref) async {
  final api = ref.read(apiClientProvider);
  final payload = await api.get('/videos');
  
  final list = payload is Map ? payload['items'] : payload;
  if (list is! List) return [];
  
  return list
      .whereType<Map>()
      .map((item) => OfgVideo.fromJson(Map<String, dynamic>.from(item)))
      .toList();
});

// 4. Real Shorts Feed Fetcher
final shortsProvider = FutureProvider<List<OfgVideo>>((ref) async {
  final api = ref.read(apiClientProvider);
  final payload = await api.get('/shorts');
  
  final list = payload is Map ? payload['items'] : payload;
  if (list is! List) return [];
  
  return list
      .whereType<Map>()
      .map((item) => OfgVideo.fromJson(Map<String, dynamic>.from(item)))
      .toList();
});