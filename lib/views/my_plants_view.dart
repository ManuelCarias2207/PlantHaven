import 'package:flutter_app/views/received_requests_view.dart';
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
  final _search = TextEditingController();
  String _filter = 'Todas';
  int _page = 1;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load([int? page]) async {
    final target = page ?? _page;
    final ok = await context.read<PlantController>().loadMyPlants(
      busqueda: _search.text,
      estado: ['DISPONIBLE', 'SOLICITADA', 'ADOPTADA'].contains(_filter)
          ? _filter
          : null,
      retirada: _filter == 'Retiradas'
          ? true
          : (_filter == 'Todas' ? null : false),
      pagina: target,
    );
    if (mounted && ok) setState(() => _page = target);
  }

  Future<void> _showPublication(int id) async {
    final controller = context.read<PlantController>();
    final plant = await controller.loadMyPlant(id);
    if (!mounted) return;
    if (plant == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(controller.friendlyError())));
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SizedBox(
                height: 180,
                child: PlantImage(url: plant.fotografiaUrl),
              ),
              const SizedBox(height: 16),
              Text(plant.nombre, style: Theme.of(context).textTheme.titleLarge),
              Text(plant.eliminada ? 'Retirada' : plant.estadoPlanta),
              const SizedBox(height: 12),
              Text('Categoría: ${plant.categoria?.nombre ?? "Sin categoría"}'),
              Text('Tamaño: ${plant.tamano}'),
              Text('Cuidados: ${plant.nivelCuidado}'),
              Text('Salud: ${plant.estadoSalud}'),
              Text('Luz: ${plant.necesidadLuz}'),
              Text('Agua: ${plant.necesidadAgua}'),
              Text('Ubicación: ${plant.ubicacion}'),
              if (plant.descripcion?.isNotEmpty == true)
                Text(plant.descripcion!),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
    if (mounted) await _load(1);
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
    if (!mounted) return;
    if (success) {
      await _load();
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(controller.friendlyError())));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlantController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Solicitudes recibidas',
            icon: const Icon(Icons.inbox_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReceivedRequestsView()),
              );
              if (mounted) await _load();
            },
          ),
        ],
        title: Text(
          'Mis publicaciones',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TextField(
              controller: _search,
              maxLength: 100,
              onSubmitted: controller.isLoading ? null : (_) => _load(1),
              decoration: InputDecoration(
                hintText: 'Buscar mis publicaciones',
                counterText: '',
                suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  onPressed: controller.isLoading ? null : () => _load(1),
                  icon: const Icon(Icons.search),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DropdownButton<String>(
              isExpanded: true,
              value: _filter,
              items: const [
                DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                DropdownMenuItem(
                  value: 'DISPONIBLE',
                  child: Text('Disponibles'),
                ),
                DropdownMenuItem(
                  value: 'SOLICITADA',
                  child: Text('Solicitadas'),
                ),
                DropdownMenuItem(value: 'ADOPTADA', child: Text('Adoptadas')),
                DropdownMenuItem(value: 'Retiradas', child: Text('Retiradas')),
              ],
              onChanged: controller.isLoading
                  ? null
                  : (value) {
                      setState(() => _filter = value!);
                      _load(1);
                    },
            ),
          ),
          if (controller.state == PlantState.error)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(controller.friendlyError()),
            ),
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.myPlants.isEmpty
                ? const Center(
                    child: Text('No hay publicaciones para esta búsqueda.'),
                  )
                : RefreshIndicator(
                    onRefresh: () => _load(),
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
                            onTap: () => _showPublication(plant.idPlanta),
                            contentPadding: const EdgeInsets.all(12),
                            leading: SizedBox(
                              width: 56,
                              height: 56,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: PlantImage(url: plant.fotografiaUrl),
                              ),
                            ),
                            title: Text(
                              plant.nombre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${plant.estadoPlanta}${plant.eliminada ? ' · Retirada' : ''}\n${plant.ubicacion}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              tooltip: 'Editar o retirar publicación',
                              enabled: canEdit,
                              onSelected: (value) {
                                if (value == 'edit') {
                                  context
                                      .push(
                                        AppRoutes.editPlant.replaceFirst(
                                          ':id',
                                          '${plant.idPlanta}',
                                        ),
                                      )
                                      .then((_) {
                                        if (mounted) _load();
                                      });
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
                        );
                      },
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  tooltip: 'Página anterior',
                  onPressed: controller.isLoading || _page == 1
                      ? null
                      : () => _load(_page - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Página $_page'),
                IconButton(
                  tooltip: 'Página siguiente',
                  onPressed:
                      controller.isLoading || controller.myPlants.length < 10
                      ? null
                      : () => _load(_page + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
