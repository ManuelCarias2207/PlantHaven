import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/controllers/plant_controller.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_routes.dart';
import 'package:flutter_app/models/plant_model.dart';
import 'package:flutter_app/views/catalog_view.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MyPlantsView extends StatefulWidget {
  const MyPlantsView({super.key});

  @override
  State<MyPlantsView> createState() => _MyPlantsViewState();
}

class _MyPlantsViewState extends State<MyPlantsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    final auth = context.read<AuthController>();
    if (!await auth.ensureAuthenticated() && mounted) {
      context.go(AppRoutes.login);
      return;
    }
    if (mounted) await context.read<PlantController>().loadMyPlants();
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
          : controller.myPlants.isEmpty
          ? const Center(child: Text('Todavía no has publicado plantas.'))
          : RefreshIndicator(
              onRefresh: () => context.read<PlantController>().loadMyPlants(),
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: controller.myPlants.length,
                itemBuilder: (context, index) {
                  final plant = controller.myPlants[index];
                  final canEdit =
                      plant.estadoPlanta.toUpperCase() == 'DISPONIBLE' &&
                      plant.visible &&
                      !plant.eliminada;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: ListTile(
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
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Retirar'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
