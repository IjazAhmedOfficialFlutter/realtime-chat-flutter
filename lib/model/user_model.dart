class UserModel {
  final int id;
  final String name;
  final String email;
  final bool isOnline;
  final DateTime? lastSeenAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.isOnline = false,
    this.lastSeenAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int
          ? json['id']
          : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      isOnline: json['isOnline'] == true,
      lastSeenAt: json['lastSeenAt'] == null
          ? null
          : DateTime.tryParse(
        json['lastSeenAt'].toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'isOnline': isOnline,
      'lastSeenAt': lastSeenAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    bool? isOnline,
    DateTime? lastSeenAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}