class BillSession {
  final String id;
  final String sessionCode;
  final String name;
  final String creatorId;
  final String creatorName;
  final double? latitude;
  final double? longitude;
  final int radius;
  final String status; // active, closed, finalized
  final String? billId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<SessionParticipant> participants;
  final List<SessionItem> items;
  final int? distance; // Distance in meters (for nearby sessions)

  BillSession({
    required this.id,
    required this.sessionCode,
    required this.name,
    required this.creatorId,
    required this.creatorName,
    this.latitude,
    this.longitude,
    required this.radius,
    required this.status,
    this.billId,
    required this.createdAt,
    required this.expiresAt,
    this.participants = const [],
    this.items = const [],
    this.distance,
  });

  factory BillSession.fromJson(Map<String, dynamic> json) {
    return BillSession(
      id: json['id'],
      sessionCode: json['session_code'],
      name: json['name'],
      creatorId: json['creator_id'],
      creatorName: json['creator_name'] ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      radius: json['radius'] ?? 50,
      status: json['status'],
      billId: json['bill_id'],
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      participants: json['participants'] != null
          ? (json['participants'] as List).map((p) => SessionParticipant.fromJson(p)).toList()
          : [],
      items: json['items'] != null
          ? (json['items'] as List).map((i) => SessionItem.fromJson(i)).toList()
          : [],
      distance: json['distance'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_code': sessionCode,
      'name': name,
      'creator_id': creatorId,
      'creator_name': creatorName,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'status': status,
      'bill_id': billId,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'participants': participants.map((p) => p.toJson()).toList(),
      'items': items.map((i) => i.toJson()).toList(),
      'distance': distance,
    };
  }

  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + item.price);
  }

  bool get isActive => status == 'active' && expiresAt.isAfter(DateTime.now());
  bool get isExpired => expiresAt.isBefore(DateTime.now());
  bool get isFinalized => status == 'finalized';
}

class SessionParticipant {
  final String id;
  final String name;
  final String phone;
  final String role; // creator, participant
  final DateTime joinedAt;

  SessionParticipant({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.joinedAt,
  });

  factory SessionParticipant.fromJson(Map<String, dynamic> json) {
    return SessionParticipant(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      role: json['role'] ?? 'participant',
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  bool get isCreator => role == 'creator';
}

class SessionItem {
  final String id;
  final String sessionId;
  final String addedBy;
  final String addedByName;
  final String name;
  final double price;
  final String? forUserId;
  final String? forUserName;
  final bool isShared;
  final DateTime createdAt;

  SessionItem({
    required this.id,
    required this.sessionId,
    required this.addedBy,
    required this.addedByName,
    required this.name,
    required this.price,
    this.forUserId,
    this.forUserName,
    required this.isShared,
    required this.createdAt,
  });

  factory SessionItem.fromJson(Map<String, dynamic> json) {
    return SessionItem(
      id: json['id'],
      sessionId: json['session_id'],
      addedBy: json['added_by'],
      addedByName: json['added_by_name'] ?? '',
      name: json['name'],
      price: double.parse(json['price'].toString()),
      forUserId: json['for_user_id'],
      forUserName: json['for_user_name'],
      isShared: json['is_shared'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'added_by': addedBy,
      'added_by_name': addedByName,
      'name': name,
      'price': price,
      'for_user_id': forUserId,
      'for_user_name': forUserName,
      'is_shared': isShared,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ContactUser {
  final String? id; // null if not registered
  final String name;
  final String phone;
  final bool isRegistered;

  ContactUser({
    this.id,
    required this.name,
    required this.phone,
    required this.isRegistered,
  });

  factory ContactUser.fromJson(Map<String, dynamic> json) {
    return ContactUser(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'],
      isRegistered: json['id'] != null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'is_registered': isRegistered,
    };
  }
}
