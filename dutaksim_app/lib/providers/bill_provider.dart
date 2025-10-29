import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../services/api_service.dart';
import 'user_provider.dart';

final billsProvider = FutureProvider<List<Bill>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getUserBills(user.id);
});

class BillCreationState {
  final String title;
  final String description;
  final List<String> participantIds;
  final List<BillItem> items;
  final double tips;

  BillCreationState({
    this.title = '',
    this.description = '',
    this.participantIds = const [],
    this.items = const [],
    this.tips = 0,
  });

  BillCreationState copyWith({
    String? title,
    String? description,
    List<String>? participantIds,
    List<BillItem>? items,
    double? tips,
  }) {
    return BillCreationState(
      title: title ?? this.title,
      description: description ?? this.description,
      participantIds: participantIds ?? this.participantIds,
      items: items ?? this.items,
      tips: tips ?? this.tips,
    );
  }

  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + item.price) + tips;
  }
}

class BillCreationNotifier extends StateNotifier<BillCreationState> {
  BillCreationNotifier() : super(BillCreationState());

  void setTitle(String title) {
    state = state.copyWith(title: title);
  }

  void setDescription(String description) {
    state = state.copyWith(description: description);
  }

  void setParticipants(List<String> participantIds) {
    state = state.copyWith(participantIds: participantIds);
  }

  void addItem(BillItem item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  void updateItem(int index, BillItem item) {
    final items = List<BillItem>.from(state.items);
    items[index] = item;
    state = state.copyWith(items: items);
  }

  void removeItem(int index) {
    final items = List<BillItem>.from(state.items);
    items.removeAt(index);
    state = state.copyWith(items: items);
  }

  void setTips(double tips) {
    state = state.copyWith(tips: tips);
  }

  void reset() {
    state = BillCreationState();
  }
}

final billCreationProvider =
    StateNotifierProvider<BillCreationNotifier, BillCreationState>((ref) {
  return BillCreationNotifier();
});
