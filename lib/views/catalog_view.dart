import 'package:flutter/material.dart';
import 'package:flutter_app/core/config/api_config.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_routes.dart';
import 'package:go_router/go_router.dart';

class Plant {
  final int id;
  final String nombre, categoria, estado, precio, tamano, nivelCuidado, luz, ubicacion;
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

final List<Plant> mockPlants = [
  Plant(id: 1, nombre: 'Monstera Deliciosa', categoria: 'Tropicales', estado: 'DISPONIBLE', precio: 'Gratis', tamano: 'Mediano', nivelCuidado: 'Intermedio', luz: 'Media', ubicacion: 'Sonsonate centro', fechaPublicacion: DateTime(2026, 9, 30)),
  Plant(id: 2, nombre: 'Pothos Dorado', categoria: 'Colgantes', estado: 'DISPONIBLE', precio: 'Gratis', tamano: 'Pequeño', nivelCuidado: 'Fácil', luz: 'Baja', ubicacion: 'Sonsonate centro', fechaPublicacion: DateTime(2026, 9, 28)),
  Plant(id: 3, nombre: 'Sansevieria', categoria: 'Suculentas', estado: 'DISPONIBLE', precio: 'Gratis', tamano: 'Mediano', nivelCuidado: 'Fácil', luz: 'Baja', ubicacion: 'Santa Ana', fechaPublicacion: DateTime(2026, 9, 27)),
  Plant(id: 4, nombre: 'Calathea Ornata', categoria: 'Tropicales', estado: 'SOLICITADA', precio: 'Gratis', tamano: 'Mediano', nivelCuidado: 'Intermedio', luz: 'Media', ubicacion: 'Sonsonate centro', fechaPublicacion: DateTime(2026, 9, 25)),
  Plant(id: 5, nombre: 'Ficus Lyrata', categoria: 'Interior', estado: 'DISPONIBLE', precio: 'Gratis', tamano: 'Grande', nivelCuidado: 'Intermedio', luz: 'Alta', ubicacion: 'Acajutla', fechaPublicacion: DateTime(2026, 9, 23)),
  Plant(id: 6, nombre: 'Aloe Vera', categoria: 'Suculentas', estado: 'DISPONIBLE', precio: 'Gratis', tamano: 'Pequeño', nivelCuidado: 'Fácil', luz: 'Alta', ubicacion: 'Sonsonate centro', fechaPublicacion: DateTime(2026, 9, 20)),
  Plant(id: 7, nombre: 'Helecho Boston', categoria: 'Interior', estado: 'DISPONIBLE', precio: 'Gratis', tamano: 'Mediano', nivelCuidado: 'Intermedio', luz: 'Media', ubicacion: 'Juayúa', fechaPublicacion: DateTime(2026, 9, 18)),
  Plant(id: 8, nombre: 'Cactus Estrella', categoria: 'Suculentas', estado: 'DISPONIBLE', precio: 'Gratis', tamano: 'Pequeño', nivelCuidado: 'Fácil', luz: 'Alta', ubicacion: 'Sonsonate centro', fechaPublicacion: DateTime(2026, 9, 16)),
  Plant(id: 9, nombre: 'Palmera Areca', categoria: 'Tropicales', estado: 'DISPONIBLE', precio: 'Gratis', tamano: 'Grande', nivelCuidado: 'Intermedio', luz: 'Media', ubicacion: 'Santa Ana', fechaPublicacion: DateTime(2026, 9, 14)),
  Plant(id: 10, nombre: 'Peperomia Verde', categoria: 'Interior', estado: 'DISPONIBLE', precio: 'Gratis', tamano: 'Pequeño', nivelCuidado: 'Fácil', luz: 'Media', ubicacion: 'Sonsonate centro', fechaPublicacion: DateTime(2026, 9, 12)),
  Plant(id: 11, nombre: 'Hoya Carnosa', categoria: 'Colgantes', estado: 'DISPONIBLE', precio: 'Gratis', tamano: 'Mediano', nivelCuidado: 'Intermedio', luz: 'Media', ubicacion: 'Armenia', fechaPublicacion: DateTime(2026, 9, 10)),
  Plant(id: 12, nombre: 'Pilea Peperomioides', categoria: 'Interior', estado: 'DISPONIBLE', precio: 'Gratis', tamano: 'Pequeño', nivelCuidado: 'Fácil', luz: 'Media', ubicacion: 'Sonsonate centro', fechaPublicacion: DateTime(2026, 9, 8)),
];

class CatalogView extends StatefulWidget {
  const CatalogView({super.key});
  @override State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final Set<int> _favoriteIds = <int>{};
  String _location = 'Todas las ubicaciones';
  String _category = 'Todas las plantas';
  int _shownCount = 6;
  bool _isLoadingMore = false;

  List<Plant> get _filteredPlants {
    final query = _searchController.text.trim().toLowerCase();
    return mockPlants.where((plant) {
      return plant.estado == 'DISPONIBLE' &&
          (query.isEmpty || plant.nombre.toLowerCase().contains(query)) &&
          (_location == 'Todas las ubicaciones' || plant.ubicacion == _location) &&
          (_category == 'Todas las plantas' || plant.categoria == _category);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNeeded);
  }

  void _loadMoreWhenNeeded() {
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 500 && !_isLoadingMore && _shownCount < _filteredPlants.length) {
      setState(() => _isLoadingMore = true);
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() { _shownCount += 4; _isLoadingMore = false; });
      });
    }
  }

  void _toggleFavorite(Plant plant) {
    setState(() {
      if (!_favoriteIds.add(plant.id)) _favoriteIds.remove(plant.id);
    });
  }

  @override
  void dispose() { _searchController.dispose(); _scrollController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final plants = _filteredPlants;
    final visiblePlants = plants.take(_shownCount).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0, titleSpacing: 20, title: const Text('PlantHaven', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 21)), actions: [IconButton(icon: const Icon(Icons.inventory_2_outlined), color: AppColors.primary, onPressed: () => context.push(AppRoutes.myPublications)), IconButton(icon: const Icon(Icons.person_outline), color: AppColors.primary, onPressed: () => context.push(AppRoutes.profile)), const SizedBox(width: 8)]),
      floatingActionButton: FloatingActionButton.extended(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), onPressed: () => context.push(AppRoutes.publishPlant), icon: const Icon(Icons.add_photo_alternate_outlined), label: const Text('Publicar planta', style: TextStyle(fontWeight: FontWeight.w700))),
      bottomNavigationBar: _bottomNavigation(context),
      body: ListView(controller: _scrollController, padding: const EdgeInsets.fromLTRB(20, 12, 20, 110), children: [
        const Text('Encuentra tu próxima\ncompañera verde', style: TextStyle(fontSize: 30, height: 1.08, fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(height: 12),
        const Text('Adopta una planta y dale un nuevo hogar lleno de luz, cuidado y cariño.', style: TextStyle(color: AppColors.textSecondary, height: 1.45, fontSize: 14)),
        const SizedBox(height: 22),
        TextField(controller: _searchController, onChanged: (_) => setState(() => _shownCount = 6), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar plantas (ej. Monstera, Pothos...)', filled: true, fillColor: AppColors.fieldBackground, border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(30))))),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: _FilterButton(icon: Icons.location_on_outlined, label: _location, onTap: _chooseLocation)), const SizedBox(width: 10), Expanded(child: _FilterButton(icon: Icons.spa_outlined, label: _category, onTap: _chooseCategory))]),
        const SizedBox(height: 9), const Text('Los resultados se actualizan automáticamente', style: TextStyle(fontSize: 12, color: AppColors.textDisabled)), const SizedBox(height: 28),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [const Expanded(child: Text('Plantas disponibles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary))), Text('(${plants.length} plantas disponibles)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)), const SizedBox(width: 8), const Icon(Icons.swap_vert, size: 17, color: AppColors.primary), const Text(' Recientes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary))]),
        const SizedBox(height: 14),
        if (visiblePlants.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: Text('No encontramos plantas con esos filtros.'))),
        ...visiblePlants.map((plant) => Padding(padding: const EdgeInsets.only(bottom: 16), child: PlantCard(plant: plant, isFavorite: _favoriteIds.contains(plant.id), onFavoriteTap: () => _toggleFavorite(plant)))),
        if (_isLoadingMore) const Padding(padding: EdgeInsets.all(18), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      ],),
    );
  }

  Widget _bottomNavigation(BuildContext context) => BottomNavigationBar(backgroundColor: Colors.white, currentIndex: 0, type: BottomNavigationBarType.fixed, selectedItemColor: AppColors.primary, unselectedItemColor: AppColors.textDisabled, onTap: (index) { if (index == 1) context.push(AppRoutes.publishPlant); if (index == 2) context.go(AppRoutes.messages); }, items: const [BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'), BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), activeIcon: Icon(Icons.add_circle), label: 'Publicar'), BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Mensajes')]);

  Future<void> _chooseLocation() async { final value = await _showPicker('Ubicación', ['Todas las ubicaciones', ...mockPlants.map((plant) => plant.ubicacion).toSet().toList()]); if (!mounted || value == null) return; setState(() { _location = value; _shownCount = 6; }); }
  Future<void> _chooseCategory() async { final value = await _showPicker('Tipo de planta', ['Todas las plantas', ...mockPlants.map((plant) => plant.categoria).toSet().toList()]); if (!mounted || value == null) return; setState(() { _category = value; _shownCount = 6; }); }
  Future<String?> _showPicker(String title, List<String> values) {
    return showModalBottomSheet<String>(
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
                  child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
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
                      trailing: selected ? const Icon(Icons.check, color: AppColors.primary) : null,
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
}

class _FilterButton extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _FilterButton({required this.icon, required this.label, required this.onTap});
  @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(26), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), border: Border.all(color: AppColors.border)), child: Row(children: [Icon(icon, size: 17, color: AppColors.accent), const SizedBox(width: 6), Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary))), const Icon(Icons.keyboard_arrow_down, size: 17)])));
}

class PlantCard extends StatelessWidget {
  final Plant plant; final bool isFavorite; final VoidCallback onFavoriteTap;
  const PlantCard({super.key, required this.plant, required this.isFavorite, required this.onFavoriteTap});
  @override Widget build(BuildContext context) => Card(margin: EdgeInsets.zero, elevation: 0, color: Colors.white, clipBehavior: Clip.antiAlias, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Stack(children: [Container(height: 180, width: double.infinity, color: AppColors.fieldBackground, child: const Center(child: Icon(Icons.local_florist_outlined, size: 64, color: AppColors.accent))), Positioned(top: 14, left: 14, child: Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)), child: const Text('Disponible para adopción', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)))), Positioned(top: 10, right: 10, child: CircleAvatar(backgroundColor: Colors.white, child: IconButton(padding: EdgeInsets.zero, icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.redAccent : AppColors.primary, size: 20), onPressed: onFavoriteTap))) ]), Padding(padding: const EdgeInsets.fromLTRB(16, 15, 16, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(plant.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis)), const SizedBox(width: 8), _tag(plant.precio)]), const SizedBox(height: 6), Text('${plant.categoria}  ${plant.estado}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)), const SizedBox(height: 13), Wrap(spacing: 7, runSpacing: 7, children: [_tag('Tamaño: ${plant.tamano}', pale: true), _tag('Cuidado: ${plant.nivelCuidado}', pale: true), _tag('Luz: ${plant.luz}', pale: true)])]))]));
  Widget _tag(String text, {bool pale = false}) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: pale ? AppColors.fieldBackground : const Color(0xFFDCE9DF), borderRadius: BorderRadius.circular(8)), child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: pale ? AppColors.textSecondary : AppColors.primary)));
}

class PlantImage extends StatelessWidget {
  final String? url;
  const PlantImage({super.key, required this.url});
  @override Widget build(BuildContext context) { final value = url?.trim() ?? ''; final imageUrl = value.startsWith('/') ? '${ApiConfig.baseUrl}$value' : value; if (imageUrl.isEmpty) return _placeholder(); return Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity, errorBuilder: (context, error, stackTrace) => _placeholder()); }
  Widget _placeholder() => Container(color: AppColors.fieldBackground, child: const Center(child: Icon(Icons.local_florist_outlined, color: AppColors.accent, size: 42)));
}
