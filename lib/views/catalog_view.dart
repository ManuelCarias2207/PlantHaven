import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/controllers/plant_controller.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_routes.dart';
import 'package:flutter_app/models/plant_model.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CatalogView extends StatefulWidget {
  const CatalogView({super.key});

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
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
    if (mounted) await context.read<PlantController>().loadCatalog();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlantController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Catalogo',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Mis publicaciones',
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () => context.push(AppRoutes.myPublications),
          ),
          IconButton(
            tooltip: 'Mi perfil',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        onPressed: () => context.push(AppRoutes.publishPlant),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Publicar planta'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
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
            icon: Icon(Icons.forum_outlined),
            activeIcon: Icon(Icons.forum),
            label: 'Mensajes',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<PlantController>().loadCatalog(),
        child: controller.isLoading && controller.plants.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : controller.plants.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('No hay plantas disponibles todavía.')),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: controller.plants.length,
                itemBuilder: (context, index) =>
                    _PlantCatalogCard(plant: controller.plants[index]),
              ),
      ),
    );
  }
}

class _PlantCatalogCard extends StatelessWidget {
  final PlantModel plant;

  const _PlantCatalogCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _PlantImage(url: plant.fotografiaUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.nombre,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${plant.tamano} · ${plant.nivelCuidado}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${plant.necesidadLuz} · ${plant.necesidadAgua}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plant.ubicacion,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

class PlantImage extends StatelessWidget {
  final String? url;

  const PlantImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) => _PlantImage(url: url);
}

class _PlantImage extends StatelessWidget {
  final String? url;

  const _PlantImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null || url!.isEmpty
          ? const Icon(
              Icons.local_florist_outlined,
              color: AppColors.accent,
              size: 38,
            )
          : Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.local_florist_outlined,
                color: AppColors.accent,
                size: 38,
              ),
            ),
    );
  }
}
