class UserModel {
  final int id;
  final String name;
  final String email;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.isOnline = false,
    this.lastSeenAt,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory UserModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return UserModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(
        json['id']?.toString() ?? '',
      ) ??
          0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      isOnline: json['isOnline'] == true,
      lastSeenAt: json['lastSeenAt'] == null
          ? null
          : DateTime.tryParse(
        json['lastSeenAt'].toString(),
      ),
      lastMessage: json['lastMessage']?.toString(),
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.tryParse(
        json['lastMessageAt'].toString(),
      ),
      unreadCount: json['unreadCount'] is int
          ? json['unreadCount']
          : int.tryParse(
        json['unreadCount']?.toString() ?? '',
      ) ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'isOnline': isOnline,
      'lastSeenAt': lastSeenAt?.toIso8601String(),
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'unreadCount': unreadCount,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    bool? isOnline,
    DateTime? lastSeenAt,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}