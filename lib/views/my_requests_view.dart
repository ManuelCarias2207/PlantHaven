import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/adoption_request_controller.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/models/adoption_request_model.dart';
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
              onPressed: () => _openChatPlaceholder(request),
            ),
          ),
        ],
      ),
    ),
  );

  void _openChatPlaceholder(AdoptionRequest request) {
    // TODO: navegar al chat con request_id y plant_id; request.id y request.plantId están disponibles.
  }
}
