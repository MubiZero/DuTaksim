class User {
  final String id;
  final String name;
  final String phone;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.phone,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  String toString() => 'User(id: $id, name: $name, phone: $phone)';
}
