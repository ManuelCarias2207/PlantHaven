import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_routes.dart';
import 'package:flutter_app/models/local_chat.dart';
import 'package:flutter_app/services/local_chat_store.dart';
import 'package:flutter_app/views/local_chat_view.dart';
import 'package:go_router/go_router.dart';

class MessagesView extends StatefulWidget {
  const MessagesView({super.key});
  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  final _searchController = TextEditingController();
  final _store = LocalChatStore();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final chats = _store
        .chats()
        .where(
          (chat) =>
              chat.plantName.toLowerCase().contains(query) ||
              chat.otherUserName.toLowerCase().contains(query),
        )
        .toList();
    final unread = _store.chats().fold<int>(
      0,
      (total, chat) => total + chat.unreadCount,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Mensajes',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (unread > 0)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCE9DF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '$unread nuevo',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar en mensajes...',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(26)),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEEEBE2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.accent),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'El chat seguro solo se habilita al existir una solicitud Pendiente o en Proceso.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: chats.isEmpty
                ? const _EmptyMessages()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      return _ChatTile(
                        chat: chat,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LocalChatView(chat: chat),
                            ),
                          );
                          if (mounted) setState(() {});
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomNavigation(context),
    );
  }

  Widget _bottomNavigation(BuildContext context) => BottomNavigationBar(
    backgroundColor: Colors.white,
    currentIndex: 2,
    type: BottomNavigationBarType.fixed,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textDisabled,
    onTap: (index) {
      if (index == 0) context.go(AppRoutes.catalog);
      if (index == 1) context.push(AppRoutes.publishPlant);
    },
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Inicio',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.add_circle_outline),
        activeIcon: Icon(Icons.add_circle),
        label: 'Publicar',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline),
        activeIcon: Icon(Icons.chat_bubble),
        label: 'Mensajes',
      ),
    ],
  );
}

class _ChatTile extends StatelessWidget {
  final LocalChat chat;
  final VoidCallback onTap;
  const _ChatTile({required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      elevation: 0,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: const CircleAvatar(
          backgroundColor: AppColors.fieldBackground,
          child: Icon(Icons.local_florist_outlined, color: AppColors.accent),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                chat.otherUserName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            if (chat.unreadCount > 0)
              const Icon(Icons.circle, size: 10, color: AppColors.primary),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCE9DF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                chat.status,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              chat.lastMessage.isEmpty ? chat.plantName : chat.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              _relative(chat.lastMessageTime),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relative(DateTime date) {
    final minutes = DateTime.now().difference(date).inMinutes;
    if (minutes < 1) return 'Ahora';
    if (minutes < 60) return 'Hace $minutes min';
    return 'Hace ${minutes ~/ 60} h';
  }
}

class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 58,
            color: AppColors.accent,
          ),
          const SizedBox(height: 14),
          const Text(
            '¿No ves una conversación?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cuando exista una solicitud pendiente o en proceso, tu chat aparecerá aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.search),
            label: const Text('Explorar plantas disponibles'),
          ),
        ],
      ),
    ),
  );
}
