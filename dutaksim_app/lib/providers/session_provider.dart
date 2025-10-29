import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import '../services/api_service.dart';
import 'dart:async';

final sessionNotifierProvider =
    StateNotifierProvider<SessionNotifier, AsyncValue<BillSession?>>((ref) {
  return SessionNotifier(ref.watch(apiServiceProvider));
});

final nearbySessionsProvider = StateNotifierProvider<NearbySessionsNotifier,
    AsyncValue<List<BillSession>>>((ref) {
  return NearbySessionsNotifier(ref.watch(apiServiceProvider));
});

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class SessionNotifier extends StateNotifier<AsyncValue<BillSession?>> {
  final ApiService _apiService;
  Timer? _refreshTimer;

  SessionNotifier(this._apiService) : super(const AsyncValue.data(null));

  Future<void> createSession({
    required String name,
    required String creatorId,
    double? latitude,
    double? longitude,
    int? radius,
  }) async {
    state = const AsyncValue.loading();
    try {
      final session = await _apiService.createSession(
        name: name,
        creatorId: creatorId,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );
      state = AsyncValue.data(session);
      _startAutoRefresh();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> joinSession({
    String? sessionCode,
    String? sessionId,
    required String userId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final session = await _apiService.joinSession(
        sessionCode: sessionCode,
        sessionId: sessionId,
        userId: userId,
      );
      state = AsyncValue.data(session);
      _startAutoRefresh();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshSession() async {
    final currentSession = state.value;
    if (currentSession == null) return;

    try {
      final session = await _apiService.getSession(currentSession.id);
      state = AsyncValue.data(session);
    } catch (e, stack) {
      // Don't override state on refresh error
      print('Failed to refresh session: $e');
    }
  }

  Future<void> addItem({
    required String name,
    required double price,
    required String addedBy,
    String? forUserId,
    bool? isShared,
  }) async {
    final currentSession = state.value;
    if (currentSession == null) return;

    try {
      await _apiService.addSessionItem(
        sessionId: currentSession.id,
        name: name,
        price: price,
        addedBy: addedBy,
        forUserId: forUserId,
        isShared: isShared,
      );
      // Refresh to get updated list
      await refreshSession();
    } catch (e) {
      throw Exception('Failed to add item: $e');
    }
  }

  Future<void> deleteItem(String itemId) async {
    final currentSession = state.value;
    if (currentSession == null) return;

    try {
      await _apiService.deleteSessionItem(currentSession.id, itemId);
      // Refresh to get updated list
      await refreshSession();
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  Future<String> finalizeSession({
    String? title,
    String? description,
    required String paidBy,
    double? tips,
  }) async {
    final currentSession = state.value;
    if (currentSession == null) {
      throw Exception('No active session');
    }

    try {
      final result = await _apiService.finalizeSession(
        sessionId: currentSession.id,
        title: title,
        description: description,
        paidBy: paidBy,
        tips: tips,
      );
      _stopAutoRefresh();
      state = const AsyncValue.data(null);
      return result['billId'];
    } catch (e) {
      throw Exception('Failed to finalize session: $e');
    }
  }

  Future<void> closeSession() async {
    final currentSession = state.value;
    if (currentSession == null) return;

    try {
      await _apiService.closeSession(currentSession.id);
      _stopAutoRefresh();
      state = const AsyncValue.data(null);
    } catch (e) {
      throw Exception('Failed to close session: $e');
    }
  }

  void leaveSession() {
    _stopAutoRefresh();
    state = const AsyncValue.data(null);
  }

  void _startAutoRefresh() {
    _stopAutoRefresh();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      refreshSession();
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }
}

class NearbySessionsNotifier
    extends StateNotifier<AsyncValue<List<BillSession>>> {
  final ApiService _apiService;

  NearbySessionsNotifier(this._apiService)
      : super(const AsyncValue.data([]));

  Future<void> loadNearbySessions({
    required double latitude,
    required double longitude,
    int? radius,
  }) async {
    state = const AsyncValue.loading();
    try {
      final sessions = await _apiService.getNearbySessions(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );
      state = AsyncValue.data(sessions);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh({
    required double latitude,
    required double longitude,
    int? radius,
  }) async {
    await loadNearbySessions(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }
}
