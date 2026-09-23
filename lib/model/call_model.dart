class CallModel {
  final int id;
  final int callerId;
  final int receiverId;
  final String roomName;
  final String callType;
  final String status;
  final DateTime? createdAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;
  final int? durationSeconds;

  const CallModel({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.roomName,
    required this.callType,
    required this.status,
    this.createdAt,
    this.answeredAt,
    this.endedAt,
    this.durationSeconds,
  });

  factory CallModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return CallModel(
      id: _intValue(json['id']),
      callerId: _intValue(json['callerId']),
      receiverId: _intValue(json['receiverId']),
      roomName: json['roomName']?.toString() ?? '',
      callType: json['callType']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: _dateValue(json['createdAt']),
      answeredAt: _dateValue(json['answeredAt']),
      endedAt: _dateValue(json['endedAt']),
      durationSeconds: json['durationSeconds'] == null
          ? null
          : _intValue(json['durationSeconds']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'callerId': callerId,
      'receiverId': receiverId,
      'roomName': roomName,
      'callType': callType,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'answeredAt': answeredAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'durationSeconds': durationSeconds,
    };
  }

  CallModel copyWith({
    int? id,
    int? callerId,
    int? receiverId,
    String? roomName,
    String? callType,
    String? status,
    DateTime? createdAt,
    DateTime? answeredAt,
    DateTime? endedAt,
    int? durationSeconds,
  }) {
    return CallModel(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      receiverId: receiverId ?? this.receiverId,
      roomName: roomName ?? this.roomName,
      callType: callType ?? this.callType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      answeredAt: answeredAt ?? this.answeredAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds:
      durationSeconds ?? this.durationSeconds,
    );
  }

  static int _intValue(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  static DateTime? _dateValue(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}