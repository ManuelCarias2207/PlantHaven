import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/controllers/plant_controller.dart';
import 'package:flutter_app/core/config/api_config.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_routes.dart';
import 'package:flutter_app/models/plant_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// DTO conservado para la pantalla de detalle. El catálogo consume PlantModel.
class Plant {
  final int id;
  final String nombre,
      categoria,
      estado,
      precio,
      tamano,
      nivelCuidado,
      luz,
      ubicacion;
  final DateTime fechaPublicacion;
  const Plant({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.estado,
    required this.precio,
    required this.tamano,
    required this.nivelCuidado,
    required this.luz,
    required this.ubicacion,
    required this.fechaPublicacion,
  });
}

class CatalogView extends StatefulWidget {
  const CatalogView({super.key});
  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final Set<int> _favoriteIds = <int>{};
  String _location = 'Todas las ubicaciones';
  String _category = 'Todas las plantas';
  int _shownCount = 6;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNeeded);
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    final auth = context.read<AuthController>();
    if (!await auth.ensureAuthenticated()) {
      if (mounted) context.go(AppRoutes.login);
      return;
    }
    if (mounted) await context.read<PlantController>().loadCatalog();
  }

  List<PlantModel> _filtered(List<PlantModel> source) {
    final query = _searchController.text.trim().toLowerCase();
    return source.where((plant) {
      final category = plant.categoria?.nombre ?? 'Sin categoría';
      return plant.estadoPlanta.toUpperCase() == 'DISPONIBLE' &&
          (query.isEmpty || plant.nombre.toLowerCase().contains(query)) &&
          (_location == 'Todas las ubicaciones' ||
              plant.ubicacion == _location) &&
          (_category == 'Todas las plantas' || category == _category);
    }).toList();
  }

  void _loadMoreWhenNeeded() {
    final plants = _filtered(context.read<PlantController>().plants);
    if (_scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 500 &&
        !_isLoadingMore &&
        _shownCount < plants.length) {
      setState(() => _isLoadingMore = true);
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _shownCount += 6;
          _isLoadingMore = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlantController>();
    final plants = _filtered(controller.plants);
    final visiblePlants = plants.take(_shownCount).toList();
    final locations = [
      'Todas las ubicaciones',
      ...controller.plants
          .map((p) => p.ubicacion)
          .where((v) => v.trim().isNotEmpty)
          .toSet(),
    ];
    final categories = [
      'Todas las plantas',
      ...controller.plants
          .map((p) => p.categoria?.nombre ?? '')
          .where((v) => v.trim().isNotEmpty)
          .toSet(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          'PlantHaven',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 21,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            color: AppColors.primary,
            onPressed: () => context.push(AppRoutes.myPublications),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            color: AppColors.primary,
            onPressed: () => context.push(AppRoutes.profile),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => context.push(AppRoutes.publishPlant),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text(
          'Publicar planta',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBar: _bottomNavigation(context),
      body: controller.isLoading && controller.plants.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : controller.state == PlantState.error && controller.plants.isEmpty
          ? _ErrorState(message: controller.friendlyError(), onRetry: _prepare)
          : RefreshIndicator(
              onRefresh: () async {
                setState(() => _shownCount = 6);
                await controller.loadCatalog();
              },
              child: _catalogBody(plants, visiblePlants, locations, categories),
            ),
    );
  }

  Widget _catalogBody(
    List<PlantModel> plants,
    List<PlantModel> visible,
    List<String> locations,
    List<String> categories,
  ) => ListView(
    controller: _scrollController,
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
    children: [
      const Text(
        'Encuentra tu próxima\ncompañera verde',
        style: TextStyle(
          fontSize: 30,
          height: 1.08,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Adopta una planta y dale un nuevo hogar lleno de luz, cuidado y cariño.',
        style: TextStyle(
          color: AppColors.textSecondary,
          height: 1.45,
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 22),
      TextField(
        controller: _searchController,
        onChanged: (_) => setState(() => _shownCount = 6),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Buscar plantas (ej. Monstera, Pothos...)',
          filled: true,
          fillColor: AppColors.fieldBackground,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _FilterButton(
              icon: Icons.location_on_outlined,
              label: _location,
              onTap: () => _chooseLocation(locations),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _FilterButton(
              icon: Icons.spa_outlined,
              label: _category,
              onTap: () => _chooseCategory(categories),
            ),
          ),
        ],
      ),
      const SizedBox(height: 9),
      const Text(
        'Los resultados se actualizan automáticamente',
        style: TextStyle(fontSize: 12, color: AppColors.textDisabled),
      ),
      const SizedBox(height: 28),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Expanded(
            child: Text(
              'Plantas disponibles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          Text(
            '(${plants.length} plantas disponibles)',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.swap_vert, size: 17, color: AppColors.primary),
          const Text(
            ' Recientes',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      if (visible.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(
            child: Text('No encontramos plantas con esos filtros.'),
          ),
        ),
      ...visible.map(
        (plant) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PlantCard(
            plant: plant,
            isFavorite: _favoriteIds.contains(plant.idPlanta),
            onFavoriteTap: () => _toggleFavorite(plant),
          ),
        ),
      ),
      if (_isLoadingMore)
        const Padding(
          padding: EdgeInsets.all(18),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
    ],
  );

  void _toggleFavorite(PlantModel plant) => setState(() {
    if (!_favoriteIds.add(plant.idPlanta)) _favoriteIds.remove(plant.idPlanta);
  });
  Widget _bottomNavigation(BuildContext context) => BottomNavigationBar(
    backgroundColor: Colors.white,
    currentIndex: 0,
    type: BottomNavigationBarType.fixed,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textDisabled,
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
        icon: Icon(Icons.chat_bubble_outline),
        activeIcon: Icon(Icons.chat_bubble),
        label: 'Mensajes',
      ),
    ],
  );
  Future<void> _chooseLocation(List<String> values) async {
    final value = await _showPicker('Ubicación', values);
    if (!mounted || value == null) return;
    setState(() {
      _location = value;
      _shownCount = 6;
    });
  }

  Future<void> _chooseCategory(List<String> values) async {
    final value = await _showPicker('Tipo de planta', values);
    if (!mounted || value == null) return;
    setState(() {
      _category = value;
      _shownCount = 6;
    });
  }

  Future<String?> _showPicker(String title, List<String> values) =>
      showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.white,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * .55,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: values.length,
                    itemBuilder: (context, index) {
                      final value = values[index];
                      final selected = value == _location || value == _category;
                      return ListTile(
                        title: Text(value),
                        trailing: selected
                            ? const Icon(Icons.check, color: AppColors.primary)
                            : null,
                        onTap: () => Navigator.pop(sheetContext, value),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
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
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}

class _FilterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FilterButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(26),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
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
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  const PlantCard({
    super.key,
    required this.plant,
    required this.isFavorite,
    required this.onFavoriteTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push(
      AppRoutes.plantDetail.replaceFirst(':id', '${plant.idPlanta}'),
      extra: plant,
    ),
    child: Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
                child: PlantImage(url: plant.fotografiaUrl),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Disponible para adopción',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.redAccent : AppColors.primary,
                      size: 20,
                    ),
                    onPressed: onFavoriteTap,
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _tag('Gratis'),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${plant.categoria?.nombre ?? 'Sin categoría'}  ${plant.estadoPlanta}',
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
                      'Cuidado: ${plant.nivelCuidado.isEmpty ? 'Intermedio' : plant.nivelCuidado}',
                      pale: true,
                    ),
                    _tag(
                      'Luz: ${plant.necesidadLuz.isEmpty ? 'Media' : plant.necesidadLuz}',
                      pale: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget _tag(String text, {bool pale = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: pale ? AppColors.fieldBackground : const Color(0xFFDCE9DF),
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
    if (imageUrl.isEmpty) return _placeholder();
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
    color: AppColors.fieldBackground,
    child: const Center(
      child: Icon(
        Icons.local_florist_outlined,
        color: AppColors.accent,
        size: 42,
      ),
    ),
  );
}
