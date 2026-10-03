import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/adoption_request_controller.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/controllers/plant_controller.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_routes.dart';
import 'package:flutter_app/models/plant_model.dart';
import 'package:flutter_app/models/adoption_request_model.dart';
import 'package:flutter_app/models/local_chat.dart';
import 'package:flutter_app/services/local_chat_store.dart';
import 'package:flutter_app/views/local_chat_view.dart';
import 'package:flutter_app/views/catalog_view.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

Future<void> _openLocalChat(
  BuildContext context,
  AdoptionRequest request,
) async {
  final chat = LocalChat(
    chatId: 'request-${request.id}',
    plantId: request.plantId,
    plantName: request.plantName,
    otherUserName: request.adopterName.isEmpty
        ? 'Adoptante'
        : request.adopterName,
    otherUserRole: 'Adoptante',
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

class MyPlantsView extends StatefulWidget {
  const MyPlantsView({super.key});

  @override
  State<MyPlantsView> createState() => _MyPlantsViewState();
}

class _MyPlantsViewState extends State<MyPlantsView> {
  String? _loadError;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    try {
      if (!mounted) return;
      setState(() => _loadError = null);
      final auth = context.read<AuthController>();
      if (!await auth.ensureAuthenticated() && mounted) {
        context.go(AppRoutes.login);
        return;
      }
      if (mounted) {
        await Future.wait([
          context.read<PlantController>().loadMyPlants(),
          context.read<AdoptionRequestController>().loadReceived(),
        ]);
      }
    } catch (error, stackTrace) {
      debugPrint('[MyPlantsView] Error cargando publicaciones: $error');
      debugPrint('$stackTrace');
      if (mounted) setState(() => _loadError = error.toString());
    }
  }

  Future<void> _retire(PlantModel plant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirar publicación'),
        content: Text('¿Deseas retirar "${plant.nombre}" del catálogo?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final controller = context.read<PlantController>();
    final success = await controller.deletePlant(plant);
    if (!mounted || success) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(controller.friendlyError())));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlantController>();
    final requestController = context.watch<AdoptionRequestController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Mis publicaciones',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      body: controller.isLoading && controller.myPlants.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : (_loadError != null ||
                controller.state == PlantState.error &&
                    controller.myPlants.isEmpty)
          ? _MyPlantsError(
              message: _loadError ?? controller.friendlyError(),
              onRetry: _prepare,
            )
          : controller.myPlants.isEmpty
          ? const Center(child: Text('Todavía no has publicado plantas.'))
          : RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  context.read<PlantController>().loadMyPlants(),
                  context.read<AdoptionRequestController>().loadReceived(),
                ]);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: controller.myPlants.length,
                itemBuilder: (context, index) {
                  final plant = controller.myPlants[index];
                  final canEdit =
                      plant.estadoPlanta.toUpperCase() == 'DISPONIBLE' &&
                      !plant.eliminada;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: PlantImage(url: plant.fotografiaUrl),
                          title: Text(
                            plant.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${plant.estadoPlanta}${plant.eliminada ? ' · Retirada' : ''}\n${plant.ubicacion}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            enabled: canEdit,
                            onSelected: (value) {
                              if (value == 'edit') {
                                context.push(
                                  AppRoutes.editPlant.replaceFirst(
                                    ':id',
                                    '${plant.idPlanta}',
                                  ),
                                );
                              }
                              if (value == 'delete') {
                                _retire(plant);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Retirar'),
                              ),
                            ],
                          ),
                        ),
                        ...requestController.receivedRequests
                            .where(
                              (request) => request.plantId == plant.idPlanta,
                            )
                            .map(_requestTile),
                      ],
                    ),
                  );
                },
              ),
            ),
      bottomNavigationBar: _bottomNavigation(context),
    );
  }

  Widget _bottomNavigation(BuildContext context) => BottomNavigationBar(
    backgroundColor: Colors.white,
    currentIndex: 0,
    type: BottomNavigationBarType.fixed,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textDisabled,
    onTap: (index) {
      if (index == 0) context.go(AppRoutes.catalog);
      if (index == 1) context.push(AppRoutes.publishPlant);
      if (index == 2) context.go(AppRoutes.messages);
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

  Widget _requestTile(AdoptionRequest request) => Container(
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.fieldBackground,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Solicitud de ${request.adopterName.isEmpty ? 'adoptante' : request.adopterName}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          request.reason.isEmpty ? 'Sin motivo indicado.' : request.reason,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              request.status,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: const Text('Mensajes'),
              onPressed: () => _openLocalChat(context, request),
            ),
          ],
        ),
      ],
    ),
  );

  void _openChatPlaceholder(AdoptionRequest request) {
    // TODO: navegar al chat con request_id, plant_id y datos básicos del otro usuario.
    // request.id, request.plantId, request.adopterName y request.adopterEmail están disponibles.
  }
}

class _MyPlantsError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _MyPlantsError({required this.message, required this.onRetry});

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
            'No se pudieron cargar tus publicaciones.',
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
