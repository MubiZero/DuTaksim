import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

class UserNotifier extends StateNotifier<User?> {
  final ApiService apiService;
  final Ref ref;

  UserNotifier(this.apiService, this.ref) : super(null);

  Future<void> loadUser() async {
    final userData = await StorageService.getUser();
    if (userData != null) {
      state = User(
        id: userData['id']!,
        name: userData['name']!,
        phone: userData['phone']!,
      );
    }
  }

  Future<void> login(String name, String phone) async {
    final user = await apiService.registerUser(name, phone);
    await StorageService.saveUser(
      id: user.id,
      name: user.name,
      phone: user.phone,
    );
    state = user;
  }

  Future<void> logout() async {
    await StorageService.clearUser();
    state = null;
  }
}

final userNotifierProvider =
    StateNotifierProvider<UserNotifier, User?>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return UserNotifier(apiService, ref);
});

// Alias for easier access
final currentUserProvider = userNotifierProvider;

final userStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(userNotifierProvider);
  if (user == null) {
    return {
      'debtsOwed': 0.0,
      'debtsOwedTo': 0.0,
      'billsCount': 0,
    };
  }

  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getUserStats(user.id);
});
