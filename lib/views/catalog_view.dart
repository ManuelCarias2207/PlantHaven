import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/controllers/plant_controller.dart';
import 'package:flutter_app/core/config/api_config.dart';
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
  final _searchController = TextEditingController();
  String _selectedCategory = 'Tipo de planta';

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlantController>();
    final query = _searchController.text.trim().toLowerCase();
    final plants = controller.plants.where((plant) {
      final searchable =
          '${plant.nombre} ${plant.ubicacion} '
                  '${plant.categoria?.nombre ?? ''}'
              .toLowerCase();
      final categoryMatches =
          _selectedCategory == 'Tipo de planta' ||
          (plant.categoria?.nombre ?? '').toLowerCase() ==
              _selectedCategory.toLowerCase();
      return (query.isEmpty || searchable.contains(query)) && categoryMatches;
    }).toList();
    final categories = controller.plants
        .map((plant) => plant.categoria?.nombre ?? '')
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();

    final content = <Widget>[];
    if (controller.isLoading && controller.plants.isEmpty) {
      content.add(
        const Padding(
          padding: EdgeInsets.only(top: 80),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (plants.isEmpty) {
      content.add(
        const Padding(
          padding: EdgeInsets.only(top: 70),
          child: Center(
            child: Text('No hay plantas que coincidan con tu búsqueda.'),
          ),
        ),
      );
    } else {
      content.addAll(
        plants.map(
          (plant) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PlantCard(plant: plant),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        title: Text(
          'PlantHaven',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () => context.push(AppRoutes.myPublications),
          ),
          IconButton(
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          children: [
            Text(
              'Encuentra tu próxima compañera verde',
              style: GoogleFonts.inter(
                fontSize: 29,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Plantitas sanas listas para llenar tu hogar de calma y vida.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar plantas (ej. Monstera, Pothos...)',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FilterChip(
                    icon: Icons.location_on_outlined,
                    label: 'Sonsonate centro',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FilterChip(
                    icon: Icons.spa_outlined,
                    label: _selectedCategory,
                    onTap: () => _chooseCategory(categories),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Los resultados se actualizan automáticamente.',
              style: TextStyle(fontSize: 12, color: AppColors.textDisabled),
            ),
            const SizedBox(height: 26),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  'Plantas disponibles',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '(${plants.length} disponibles)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.swap_vert, size: 18, color: AppColors.accent),
                    const Text(
                      'Recientes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...content,
          ],
        ),
      ),
    );
  }

  Future<void> _chooseCategory(List<String> categories) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Tipo de planta'),
              trailing: const Icon(Icons.close),
              onTap: () => Navigator.pop(context, 'Tipo de planta'),
            ),
            ListTile(
              title: const Text('Todas'),
              onTap: () => Navigator.pop(context, 'Tipo de planta'),
            ),
            ...categories.map(
              (category) => ListTile(
                title: Text(category),
                onTap: () => Navigator.pop(context, category),
              ),
            ),
          ],
        ),
      ),
    );
    if (value != null && mounted) setState(() => _selectedCategory = value);
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FilterChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(24),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, size: 17),
        ],
      ),
    ),
  );
}

class PlantCard extends StatelessWidget {
  final PlantModel plant;
  const PlantCard({super.key, required this.plant});
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: AppColors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            SizedBox(
              height: 190,
              width: double.infinity,
              child: PlantImage(url: plant.fotografiaUrl),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Disponible para adopción',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: AppColors.white,
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.favorite_border,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plant.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _tag('Gratis'),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                '${plant.categoria?.nombre ?? 'Planta'} · ${plant.estadoPlanta.isEmpty ? 'Arácea' : plant.estadoPlanta}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 13),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _tag(
                    'Tamaño: ${plant.tamano.isEmpty ? 'Mediano' : plant.tamano}',
                    pale: true,
                  ),
                  _tag(
                    'Cuidado: ${plant.nivelCuidado.isEmpty ? 'Fácil' : plant.nivelCuidado}',
                    pale: true,
                  ),
                  _tag(
                    'Luz: ${plant.necesidadLuz.isEmpty ? 'Indirecta' : plant.necesidadLuz}',
                    pale: true,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 17,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      plant.ubicacion.isEmpty
                          ? 'Sonsonate centro'
                          : plant.ubicacion,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: () => context.push(
                    AppRoutes.plantDetail.replaceFirst(
                      ':id',
                      '${plant.idPlanta}',
                    ),
                    extra: plant,
                  ),
                  child: const Text('Ver detalles'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _tag(String text, {bool pale = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: pale
          ? AppColors.fieldBackground
          : AppColors.accent.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: pale ? AppColors.textSecondary : AppColors.primary,
      ),
    ),
  );
}

class PlantImage extends StatelessWidget {
  final String? url;
  const PlantImage({super.key, required this.url});
  @override
  Widget build(BuildContext context) {
    final value = url?.trim() ?? '';
    final imageUrl = value.startsWith('/')
        ? '${ApiConfig.baseUrl}$value'
        : value;
    return Container(
      color: AppColors.fieldBackground,
      child: imageUrl.isEmpty
          ? const _ImagePlaceholder()
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, _, _) => const _ImagePlaceholder(),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const _ImagePlaceholder(),
            ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();
  @override
  Widget build(BuildContext context) => const Center(
    child: Icon(
      Icons.local_florist_outlined,
      color: AppColors.accent,
      size: 54,
    ),
  );
}
