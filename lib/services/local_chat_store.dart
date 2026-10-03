import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/models/local_chat.dart';

class LocalChatStore {
  static const _chatsBoxName = 'local_chats';
  static const _messagesBoxName = 'local_messages';
  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(_chatsBoxName);
    await Hive.openBox<Map>(_messagesBoxName);
  }

  Box<Map> get _chats => Hive.box<Map>(_chatsBoxName);
  Box<Map> get _messages => Hive.box<Map>(_messagesBoxName);

  List<LocalChat> chats() =>
      _chats.values.map(LocalChat.fromMap).toList()
        ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
  LocalChat? chat(String chatId) {
    final value = _chats.get(chatId);
    return value == null ? null : LocalChat.fromMap(value);
  }

  Future<void> saveChat(LocalChat chat) =>
      _chats.put(chat.chatId, chat.toMap());
  List<LocalMessage> messages(String chatId) =>
      _messages.values
          .map(LocalMessage.fromMap)
          .where((message) => message.chatId == chatId)
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  Future<void> saveMessage(LocalMessage message) async {
    await _messages.put(message.id, message.toMap());
    final current = chat(message.chatId);
    if (current != null)
      await saveChat(
        current.copyWith(
          lastMessage: message.locationData == null
              ? message.textContent
              : 'Punto de encuentro compartido',
          lastMessageTime: message.timestamp,
          unreadCount: message.isMine
              ? current.unreadCount
              : current.unreadCount + 1,
        ),
      );
  }

  Future<void> markRead(String chatId) async {
    final current = chat(chatId);
    if (current != null) await saveChat(current.copyWith(unreadCount: 0));
  }
}
