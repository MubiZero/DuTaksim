import 'user.dart';

class BillItem {
  final String? id;
  final String name;
  final double price;
  final bool isShared;
  final List<String> participantIds;
  List<User>? participants;

  BillItem({
    this.id,
    required this.name,
    required this.price,
    this.isShared = false,
    this.participantIds = const [],
    this.participants,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      id: json['id'] as String?,
      name: json['name'] as String,
      price: double.parse(json['price'].toString()),
      isShared: json['is_shared'] as bool? ?? false,
      participantIds: (json['participant_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      participants: (json['participants'] as List<dynamic>?)
          ?.map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'price': price,
      'is_shared': isShared,
      'participant_ids': participantIds,
      if (participants != null)
        'participants': participants!.map((e) => e.toJson()).toList(),
    };
  }

  BillItem copyWith({
    String? id,
    String? name,
    double? price,
    bool? isShared,
    List<String>? participantIds,
    List<User>? participants,
  }) {
    return BillItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isShared: isShared ?? this.isShared,
      participantIds: participantIds ?? this.participantIds,
      participants: participants ?? this.participants,
    );
  }
}
