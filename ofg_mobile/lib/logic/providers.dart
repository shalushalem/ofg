// lib/logic/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/ofg_models.dart';
import '../presentation/theme/ofg_theme.dart' hide kDefaultApiBase;

// ---------------------------------------------------------------------------
// 1. Core API Client Provider
// ---------------------------------------------------------------------------
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: kDefaultApiBase);
});

// ---------------------------------------------------------------------------
// 2. Current User State
// ---------------------------------------------------------------------------
final authStateProvider = StateProvider<OfgUser?>((ref) => null);

// ---------------------------------------------------------------------------
// Helper: handle 401 by clearing session gracefully
// ---------------------------------------------------------------------------
Future<T?> _guardedAuth<T>(
  Ref ref,
  Future<T> Function() call, {
  T? fallback,
}) async {
  // If no token set, don't even attempt (avoids pointless 401 calls)
  final api = ref.read(apiClientProvider);
  if (api.token == null || api.token!.isEmpty) return fallback;
  try {
    return await call();
  } on ApiException catch (e) {
    if (e.statusCode == 401) {
      // Session expired — log out silently
      await OfgStorage.clear();
      ref.read(apiClientProvider).token = null;
      ref.read(authStateProvider.notifier).state = null;
      return fallback;
    }
    rethrow;
  }
}

// ---------------------------------------------------------------------------
// 3. Feed Category Filter
// ---------------------------------------------------------------------------
final feedCategoryProvider = StateProvider<String?>((ref) => null);

// ---------------------------------------------------------------------------
// 4. Real Video Feed Fetcher (respects category) — works for both logged-in and anonymous
// ---------------------------------------------------------------------------
final feedProvider = FutureProvider<List<OfgVideo>>((ref) async {
  final api = ref.read(apiClientProvider);
  final category = ref.watch(feedCategoryProvider);
  try {
    final payload = await api.getFeed(category: category);
    final list = payload is Map ? payload['items'] ?? payload['videos'] : payload;
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((item) => OfgVideo.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  } on ApiException catch (e) {
    if (e.statusCode == 401) {
      await OfgStorage.clear();
      ref.read(apiClientProvider).token = null;
      ref.read(authStateProvider.notifier).state = null;
      return [];
    }
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// 5. Real Shorts Feed Fetcher
// ---------------------------------------------------------------------------
final shortsProvider = FutureProvider<List<OfgVideo>>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final payload = await api.getShorts();
    final list = payload is Map ? payload['items'] ?? payload['videos'] : payload;
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((item) => OfgVideo.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  } on ApiException catch (e) {
    if (e.statusCode == 401) {
      await OfgStorage.clear();
      ref.read(apiClientProvider).token = null;
      ref.read(authStateProvider.notifier).state = null;
      return [];
    }
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// 6. Search Query State
// ---------------------------------------------------------------------------
final searchQueryProvider = StateProvider<String>((ref) => '');

// ---------------------------------------------------------------------------
// 7. Global Interaction State Caches (Likes, Saves, Follows)
// ---------------------------------------------------------------------------
final globalLikedProvider = StateProvider<Map<String, bool>>((ref) => {});
final globalSavedProvider = StateProvider<Map<String, bool>>((ref) => {});
final globalLikeCountProvider = StateProvider<Map<String, int>>((ref) => {});
final globalFollowingProvider = StateProvider<Map<String, bool>>((ref) => {});

// ---------------------------------------------------------------------------
// 8. Video Comments (family provider)
// ---------------------------------------------------------------------------
final videoCommentsProvider =
    FutureProvider.family<List<OfgComment>, String>((ref, videoId) async {
  if (videoId.isEmpty) return [];
  final api = ref.read(apiClientProvider);
  final payload = await api.getComments(videoId);

  final list =
      payload is Map ? payload['items'] ?? payload['comments'] : payload;
  if (list is! List) return [];

  return list
      .whereType<Map>()
      .map((item) => OfgComment.fromJson(Map<String, dynamic>.from(item)))
      .toList();
});

// ---------------------------------------------------------------------------
// 8. Creator Stats
// ---------------------------------------------------------------------------
final creatorStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final result = await _guardedAuth<Map<String, dynamic>>(
    ref,
    () async {
      final api = ref.read(apiClientProvider);
      final payload = await api.getCreatorStats();
      return Map<String, dynamic>.from(payload);
    },
    fallback: {'views': 0, 'videos': 0, 'likes': 0, 'followers': 0, 'following': 0,
               'totalWatchTime': 0.0, 'avgCompletionRate': 0.0, 'topCategory': '—'},
  );
  return result ?? {'views': 0, 'videos': 0, 'likes': 0, 'followers': 0, 'following': 0,
                    'totalWatchTime': 0.0, 'avgCompletionRate': 0.0, 'topCategory': '—'};
});

// ---------------------------------------------------------------------------
// 9. Creator Videos
// ---------------------------------------------------------------------------
final creatorVideosProvider = FutureProvider<List<OfgVideo>>((ref) async {
  final result = await _guardedAuth<List<OfgVideo>>(
    ref,
    () async {
      final api = ref.read(apiClientProvider);
      final payload = await api.getCreatorVideos();
      final list = payload is Map ? payload['items'] ?? payload['videos'] : payload;
      if (list is! List) return <OfgVideo>[];
      return list
          .whereType<Map>()
          .map((item) => OfgVideo.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    },
    fallback: [],
  );
  return result ?? [];
});

// ---------------------------------------------------------------------------
// 10. Library – History
// ---------------------------------------------------------------------------
final libraryHistoryProvider = FutureProvider<List<OfgVideo>>((ref) async {
  final result = await _guardedAuth<List<OfgVideo>>(
    ref,
    () async {
      final api = ref.read(apiClientProvider);
      final payload = await api.getHistory();
      final list = payload is Map ? payload['items'] ?? payload['videos'] : payload;
      if (list is! List) return <OfgVideo>[];
      return list
          .whereType<Map>()
          .map((item) => OfgVideo.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    },
    fallback: [],
  );
  return result ?? [];
});

// ---------------------------------------------------------------------------
// 11. Library – Saved
// ---------------------------------------------------------------------------
final librarySavedProvider = FutureProvider<List<OfgVideo>>((ref) async {
  final result = await _guardedAuth<List<OfgVideo>>(
    ref,
    () async {
      final api = ref.read(apiClientProvider);
      final payload = await api.getSaved();
      final list = payload is Map ? payload['items'] ?? payload['videos'] : payload;
      if (list is! List) return <OfgVideo>[];
      return list
          .whereType<Map>()
          .map((item) => OfgVideo.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    },
    fallback: [],
  );
  return result ?? [];
});

// ---------------------------------------------------------------------------
// 12. Notifications
// ---------------------------------------------------------------------------
final notificationsProvider =
    FutureProvider<List<OfgNotification>>((ref) async {
  final result = await _guardedAuth<List<OfgNotification>>(
    ref,
    () async {
      final api = ref.read(apiClientProvider);
      final payload = await api.getNotifications();
      final list = payload is Map ? payload['items'] ?? payload['notifications'] : payload;
      if (list is! List) return <OfgNotification>[];
      return list
          .whereType<Map>()
          .map((item) => OfgNotification.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    },
    fallback: [],
  );
  return result ?? [];
});

// ---------------------------------------------------------------------------
// 13. Search Results
// ---------------------------------------------------------------------------
final searchResultsProvider = FutureProvider<List<OfgVideo>>((ref) async {
  final api = ref.read(apiClientProvider);
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  
  final payload = await api.search(q: query);

  final list = payload is Map ? payload['items'] ?? payload['videos'] : payload;
  if (list is! List) return [];

  return list
      .whereType<Map>()
      .map((item) => OfgVideo.fromJson(Map<String, dynamic>.from(item)))
      .toList();
});

// ---------------------------------------------------------------------------
// 14. Admin Videos
// ---------------------------------------------------------------------------
final adminVideosProvider = FutureProvider<List<OfgVideo>>((ref) async {
  final api = ref.read(apiClientProvider);
  final payload = await api.get('/admin/videos?status=all', admin: true);

  final list = payload is Map ? payload['items'] ?? payload['videos'] : payload;
  if (list is! List) return [];

  return list
      .whereType<Map>()
      .map((item) => OfgVideo.fromJson(Map<String, dynamic>.from(item)))
      .toList();
});

// ---------------------------------------------------------------------------
// 15. Admin Reports
// ---------------------------------------------------------------------------
final adminReportsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final payload = await api.get('/admin/reports?status=pending', admin: true);

  final list = payload is Map ? payload['items'] ?? payload['reports'] : payload;
  if (list is! List) return [];

  return list;
});