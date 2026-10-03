class LocalLocation {
  final double latitude;
  final double longitude;
  final String placeName;
  const LocalLocation({
    required this.latitude,
    required this.longitude,
    required this.placeName,
  });
  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    'place_name': placeName,
  };
  factory LocalLocation.fromMap(Map<dynamic, dynamic> map) => LocalLocation(
    latitude: (map['latitude'] as num).toDouble(),
    longitude: (map['longitude'] as num).toDouble(),
    placeName: '${map['place_name'] ?? ''}',
  );
}

class LocalChat {
  final String chatId;
  final int plantId;
  final String plantName;
  final String otherUserName;
  final String otherUserRole;
  final String status;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  const LocalChat({
    required this.chatId,
    required this.plantId,
    required this.plantName,
    required this.otherUserName,
    required this.otherUserRole,
    required this.status,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
  });
  LocalChat copyWith({
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
  }) => LocalChat(
    chatId: chatId,
    plantId: plantId,
    plantName: plantName,
    otherUserName: otherUserName,
    otherUserRole: otherUserRole,
    status: status,
    lastMessage: lastMessage ?? this.lastMessage,
    lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    unreadCount: unreadCount ?? this.unreadCount,
  );
  Map<String, dynamic> toMap() => {
    'chat_id': chatId,
    'plant_id': plantId,
    'plant_name': plantName,
    'other_user_name': otherUserName,
    'other_user_role': otherUserRole,
    'status': status,
    'last_message': lastMessage,
    'last_message_time': lastMessageTime.toIso8601String(),
    'unread_count': unreadCount,
  };
  factory LocalChat.fromMap(Map<dynamic, dynamic> map) => LocalChat(
    chatId: '${map['chat_id']}',
    plantId: (map['plant_id'] as num).toInt(),
    plantName: '${map['plant_name'] ?? ''}',
    otherUserName: '${map['other_user_name'] ?? ''}',
    otherUserRole: '${map['other_user_role'] ?? ''}',
    status: '${map['status'] ?? ''}',
    lastMessage: '${map['last_message'] ?? ''}',
    lastMessageTime:
        DateTime.tryParse('${map['last_message_time']}') ?? DateTime.now(),
    unreadCount: (map['unread_count'] as num?)?.toInt() ?? 0,
  );
}

class LocalMessage {
  final String id;
  final String chatId;
  final int senderId;
  final String textContent;
  final LocalLocation? locationData;
  final DateTime timestamp;
  final bool isMine;
  const LocalMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.textContent,
    required this.locationData,
    required this.timestamp,
    required this.isMine,
  });
  Map<String, dynamic> toMap() => {
    'id': id,
    'chat_id': chatId,
    'sender_id': senderId,
    'text_content': textContent,
    'location_data': locationData?.toMap(),
    'timestamp': timestamp.toIso8601String(),
    'is_mine': isMine,
  };
  factory LocalMessage.fromMap(Map<dynamic, dynamic> map) => LocalMessage(
    id: '${map['id']}',
    chatId: '${map['chat_id']}',
    senderId: (map['sender_id'] as num).toInt(),
    textContent: '${map['text_content'] ?? ''}',
    locationData: map['location_data'] is Map
        ? LocalLocation.fromMap(map['location_data'] as Map)
        : null,
    timestamp: DateTime.tryParse('${map['timestamp']}') ?? DateTime.now(),
    isMine: map['is_mine'] == true,
  );
}
