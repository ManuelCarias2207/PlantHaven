import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/adoption_request_controller.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/models/adoption_request_model.dart';
import 'package:flutter_app/models/local_chat.dart';
import 'package:flutter_app/services/local_chat_store.dart';
import 'package:flutter_app/views/local_chat_view.dart';
import 'package:provider/provider.dart';

class MyRequestsView extends StatefulWidget {
  const MyRequestsView({super.key});
  @override
  State<MyRequestsView> createState() => _MyRequestsViewState();
}

class _MyRequestsViewState extends State<MyRequestsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AdoptionRequestController>().loadMine(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdoptionRequestController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mis solicitudes')),
      body: controller.isLoading && controller.myRequests.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : controller.error != null && controller.myRequests.isEmpty
          ? _RequestError(
              message: controller.error!,
              onRetry: controller.loadMine,
            )
          : RefreshIndicator(
              onRefresh: () async {
                await controller.loadMine();
              },
              child: controller.myRequests.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(child: Text('Todavía no tienes solicitudes.')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: controller.myRequests.length,
                      itemBuilder: (context, index) =>
                          _RequestCard(request: controller.myRequests[index]),
                    ),
            ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final AdoptionRequest request;
  const _RequestCard({required this.request});
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.plantName.isEmpty
                ? 'Solicitud de adopción'
                : request.plantName,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            request.status,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            request.reason.isEmpty ? 'Sin motivo indicado.' : request.reason,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: const Text('Mensajes'),
              onPressed: () => _openLocalChat(context, request),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _openLocalChat(
    BuildContext context,
    AdoptionRequest request,
  ) async {
    final chat = LocalChat(
      chatId: 'request-${request.id}',
      plantId: request.plantId,
      plantName: request.plantName,
      otherUserName: request.adopterName.isEmpty
          ? 'Donante'
          : request.adopterName,
      otherUserRole: 'Donante',
      status: request.status,
      lastMessage: request.reason,
      lastMessageTime: request.createdAt ?? DateTime.now(),
      unreadCount: 0,
    );
    await LocalChatStore().saveChat(chat);
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LocalChatView(chat: chat)),
    );
  }
}

class _RequestError extends StatelessWidget {
  final String message;
  final Future<bool> Function() onRetry;

  const _RequestError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: AppColors.accent,
          ),
          const SizedBox(height: 12),
          const Text(
            'No se pudieron cargar tus solicitudes.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}
