import 'dart:async';

import 'package:flutter_app/services/plant_service.dart';
import 'package:flutter_app/views/my_requests_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/views/adoptions_view.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/core/config/api_config.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_routes.dart';
import 'package:flutter_app/models/plant_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// DTO conservado para la pantalla de detalle. El catálogo consume PlantModel.
/*class Plant {
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
}*/

class CatalogView extends StatefulWidget {
  final PlantService? service;
  const CatalogView({super.key, this.service});
  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final Set<int> _favoriteIds = <int>{};
  String _location = 'Todas las ubicaciones';
  String _category = 'Todas las plantas';
  String _size = 'Todos los tamaños', _care = 'Todos los cuidados';
  List<PlantModel> _items = [];
  Map<String, List<String>> _options = {};
  int _page = 0, _total = 0, _generation = 0;
  bool _loading = false, _more = false;
  String? _error;
  Timer? _debounce;
  late final PlantService _service = widget.service ?? PlantService();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNeeded);
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    if (!await context.read<AuthController>().ensureAuthenticated()) {
      if (mounted) context.go(AppRoutes.login);
      return;
    }
    if (mounted) await _load();
  }

  Future<void> _load({bool more = false}) async {
    if (!mounted) return;
    if (more && (_loading || !_more || _error != null)) return;
    final generation = more ? _generation : ++_generation;
    final page = more ? _page + 1 : 1;
    setState(() {
      _loading = true;
      _error = null;
      if (!more) {
        _items = [];
        _more = false;
      }
    });
    try {
      final data = await _service.GetCatalogPage(
        page: page,
        filters: {
          if (_searchController.text.trim().isNotEmpty)
            'busqueda': _searchController.text.trim(),
          if (_location != 'Todas las ubicaciones') 'ubicacion': _location,
          if (_category != 'Todas las plantas') 'categoria': _category,
          if (_size != 'Todos los tamaños') 'tamano': _size,
          if (_care != 'Todos los cuidados') 'nivel_cuidado': _care,
        },
      );
      if (!mounted || generation != _generation) return;
      final incoming = (data['plantas'] as List)
          .map((p) => PlantModel.fromJson(p))
          .toList();
      setState(() {
        final merged = more ? [..._items, ...incoming] : incoming;
        _items = {for (final p in merged) p.idPlanta: p}.values.toList();
        _page = page;
        _total = data['total'] as int;
        _more = data['hay_mas'] as bool? ?? page * 12 < _total;
        _options = (data['filtros'] as Map? ?? {}).map(
          (k, v) => MapEntry(k.toString(), (v as List).cast<String>()),
        );
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(
          () => _error = 'No se pudo cargar el catálogo. Comprueba tu conexión y reintenta.',
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _loadMoreWhenNeeded(),
        );
      }
    }
  }

  void _loadMoreWhenNeeded() {
    if (!mounted || !_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 400) _load(more: true);
  }

  void _searchChanged(String value) {
    _debounce?.cancel();
    ++_generation;
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plants = _items;
    final visiblePlants = plants;
    final locations = {
      'Todas las ubicaciones',
      ...?_options['ubicacion'],
      _location,
    }.toList();
    final categories = {
      'Todas las plantas',
      ...?_options['categoria'],
      _category,
    }.toList();
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
            tooltip: 'Mis adopciones',
            icon: const Icon(Icons.handshake_outlined),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AdoptionsView()))
                .then((_) => _load()),
          ),
          IconButton(
            tooltip: 'Mis solicitudes',
            icon: const Icon(Icons.mark_email_read_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyRequestsView()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            color: AppColors.primary,
            onPressed: () =>
                context.push(AppRoutes.myPublications).then((_) => _load()),
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
        onPressed: () =>
            context.push(AppRoutes.publishPlant).then((_) => _load()),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text(
          'Publicar planta',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBar: _bottomNavigation(context),
      body: RefreshIndicator(
        onRefresh: () => _load(),
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
    physics: const AlwaysScrollableScrollPhysics(),
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
        onChanged: _searchChanged,
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
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _FilterButton(
              icon: Icons.straighten,
              label: _size,
              onTap: () async {
                final value = await _showPicker(
                  'Tamaño',
                  {'Todos los tamaños', ...?_options['tamano'], _size}.toList(),
                );
                if (!mounted || value == null) return;
                setState(() => _size = value);
                await _load();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _FilterButton(
              icon: Icons.water_drop_outlined,
              label: _care,
              onTap: () async {
                final value = await _showPicker(
                  'Nivel de cuidado',
                  {
                    'Todos los cuidados',
                    ...?_options['nivel_cuidado'],
                    _care,
                  }.toList(),
                );
                if (!mounted || value == null) return;
                setState(() => _care = value);
                await _load();
              },
            ),
          ),
        ],
      ),
      TextButton(
        onPressed: () {
          _debounce?.cancel();
          setState(() {
            _location = 'Todas las ubicaciones';
            _category = 'Todas las plantas';
            _size = 'Todos los tamaños';
            _care = 'Todos los cuidados';
            _searchController.clear();
          });
          _load();
        },
        child: const Text('Limpiar filtros'),
      ),
      const SizedBox(height: 9),
      const Text(
        'Los resultados se actualizan automáticamente',
        style: TextStyle(fontSize: 12, color: AppColors.textDisabled),
      ),
      const SizedBox(height: 28),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
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
            '($_total resultados)',
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
      if (visible.isEmpty && !_loading && _error == null)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(
            child: Text('No encontramos plantas con esos filtros.'),
          ),
        ),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: visible.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 3 : 2,
          mainAxisExtent: 310,
          crossAxisSpacing: 10,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (_, i) => PlantCard(
          plant: visible[i],
          isFavorite: _favoriteIds.contains(visible[i].idPlanta),
          onFavoriteTap: () => _toggleFavorite(visible[i]),
          onReturn: () => _load(),
        ),
      ),
      if (_loading)
        const Padding(
          padding: EdgeInsets.all(18),
          child: Center(child: CircularProgressIndicator()),
        ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(_error!),
              TextButton(
                onPressed: () {
                  final more = _items.isNotEmpty;
                  setState(() => _error = null);
                  _load(more: more);
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
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
      if (index == 1) context.push(AppRoutes.publishPlant).then((_) => _load());
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
    });
    await _load();
  }

  Future<void> _chooseCategory(List<String> values) async {
    final value = await _showPicker('Tipo de planta', values);
    if (!mounted || value == null) return;
    setState(() {
      _category = value;
    });
    await _load();
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
                      final selected =
                          value == _location ||
                          value == _category ||
                          value == _size ||
                          value == _care;
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
  final VoidCallback? onReturn;
  const PlantCard({
    super.key,
    required this.plant,
    required this.isFavorite,
    required this.onFavoriteTap,
    this.onReturn,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context
        .push(
          AppRoutes.plantDetail.replaceFirst(':id', '${plant.idPlanta}'),
          extra: plant,
        )
        .then((_) => onReturn?.call()),
    child: Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 130,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PlantImage(url: plant.fotografiaUrl),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton.filledTonal(
                    onPressed: onFavoriteTap,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    plant.categoria?.nombre ?? 'Sin categoría',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Tamaño: ${plant.tamano}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Cuidado: ${plant.nivelCuidado}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  const Text(
                    'Disponible · Ver detalle',
                    style: TextStyle(fontSize: 11, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
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
