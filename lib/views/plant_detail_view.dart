import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/models/plant_model.dart';
import 'package:flutter_app/views/catalog_view.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/core/constants/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class PlantDetailView extends StatelessWidget {
  final PlantModel plant;
  const PlantDetailView({super.key, required this.plant});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle de planta')),
    body: ListView(
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: PlantImage(url: plant.fotografiaUrl),
        ),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plant.nombre,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${plant.categoria?.nombre ?? 'Planta'} · ${plant.tamano}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              Text(
                plant.descripcion?.isNotEmpty == true ? plant.descripcion! : 'Una compañera verde lista para encontrar un nuevo hogar.',
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 24),
              if (context.watch<AuthController>().currentUser?.idUsuario ==
                  plant.idUsuario) ...[
                const Text('Esta es tu publicación.'),
                const SizedBox(height: 8),
                if (plant.estadoPlanta == 'DISPONIBLE' &&
                    plant.visible &&
                    !plant.eliminada)
                  FilledButton.icon(
                    onPressed: () => context.push(
                      AppRoutes.editPlant.replaceFirst(
                        ':id',
                        '${plant.idPlanta}',
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar publicación'),
                  ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.myPublications),
                  child: const Text('Ir a mis publicaciones'),
                ),
              ] else ...[
                const FilledButton(
                  onPressed: null,
                  child: Text('Solicitar adopción'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'El envío de solicitudes aún no está disponible en esta versión.',
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
