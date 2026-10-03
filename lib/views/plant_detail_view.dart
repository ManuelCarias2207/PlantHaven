import 'package:flutter/services.dart';
import 'package:flutter_app/controllers/auth_controller.dart';

import 'package:flutter_app/core/constants/app_routes.dart';

import 'package:go_router/go_router.dart';

import 'package:flutter/material.dart';

import 'package:flutter_app/core/constants/app_colors.dart';

import 'package:flutter_app/controllers/adoption_request_controller.dart';

import 'package:flutter_app/models/adoption_request_model.dart';

import 'package:flutter_app/models/plant_model.dart';

import 'package:flutter_app/views/catalog_view.dart';

import 'package:flutter_app/views/adoption_success_view.dart';

import 'package:provider/provider.dart';

class PlantDetailView extends StatefulWidget {
  final PlantModel plant;

  const PlantDetailView({super.key, required this.plant});

  @override
  State<PlantDetailView> createState() => _PlantDetailViewState();
}

class _PlantDetailViewState extends State<PlantDetailView> {
  bool _favorite = false;

  bool _requestSent = false;

  bool _notificationsEnabled = false;

  AdoptionRequest? _submittedRequest;

  PlantModel get plant => widget.plant;

  bool get _isOwner =>
      context.read<AuthController>().currentUser?.idUsuario == plant.idUsuario;

  bool get _isAvailable => plant.estadoPlanta.toUpperCase() == 'DISPONIBLE';

  String get _category => plant.categoria?.nombre ?? 'Sin categoría';

  String get _size => plant.tamano.isEmpty ? 'No indicado' : plant.tamano;

  String get _care =>
      plant.nivelCuidado.isEmpty ? 'No indicado' : plant.nivelCuidado;

  String get _light =>
      plant.necesidadLuz.isEmpty ? 'No indicada' : plant.necesidadLuz;

  String get _water => plant.necesidadAgua.isEmpty
      ? 'Consultar al donante'
      : plant.necesidadAgua;

  String get _health =>
      plant.estadoSalud.isEmpty ? 'No indicada' : plant.estadoSalud;

  String get _location =>
      plant.ubicacion.isEmpty ? 'No indicada' : plant.ubicacion;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingRequest());
  }

  Future<void> _loadExistingRequest() async {
    if (_isOwner) return;

    final controller = context.read<AdoptionRequestController>();

    await controller.loadMine(plantId: plant.idPlanta);

    if (!mounted) return;

    AdoptionRequest? existing;

    for (final item in controller.myRequests) {
      if (item.plantId == plant.idPlanta &&
          ['PENDIENTE', 'ACEPTADA'].contains(item.status)) {
        existing = item;

        break;
      }
    }

    if (existing != null) {
      setState(() {
        _submittedRequest = existing;

        _requestSent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,

    appBar: AppBar(
      backgroundColor: AppColors.background,

      elevation: 0,

      titleSpacing: 4,

      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.primary),

        onPressed: () => Navigator.pop(context),
      ),

      title: const Text(
        'Volver a explorar',

        style: TextStyle(
          fontSize: 13,

          fontWeight: FontWeight.w700,

          color: AppColors.primary,
        ),
      ),

      actions: [
        Text(
          'REF: PH-${plant.idPlanta.toString().padLeft(4, '0')}',

          style: const TextStyle(
            fontSize: 10,

            fontWeight: FontWeight.w700,

            color: AppColors.primary,
          ),
        ),

        const SizedBox(width: 8),

        IconButton(
          tooltip: _notificationsEnabled
              ? 'Notificaciones activadas'
              : 'Activar notificaciones',

          icon: Icon(
            _notificationsEnabled
                ? Icons.notifications_active
                : Icons.notifications_none,

            color: _notificationsEnabled ? AppColors.accent : AppColors.primary,
          ),

          onPressed: () {
            setState(() => _notificationsEnabled = !_notificationsEnabled);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 1200),

                content: Text(
                  _notificationsEnabled
                      ? 'Notificaciones activadas'
                      : 'Notificaciones desactivadas',
                ),
              ),
            );
          },
        ),
      ],
    ),

    bottomNavigationBar: _isOwner
        ? SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () => context.push(AppRoutes.myPublications),
                child: const Text('Gestionar mi publicación'),
              ),
            ),
          )
        : _RequestBar(
            enabled: _isAvailable && !_requestSent,

            label: _requestSent
                ? 'Solicitud enviada'
                : _isAvailable
                ? 'Solicitar adopción  →'
                : 'No disponible para adopción',

            onPressed: _requestAdoptionRemote,
          ),

    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          _Gallery(
            plant: plant,

            favorite: _favorite,

            onFavorite: () => setState(() => _favorite = !_favorite),
          ),

          const SizedBox(height: 24),

          _StatusChip(
            label: _isAvailable
                ? 'Disponible para adopción'
                : plant.estadoPlanta,
          ),

          const SizedBox(height: 12),

          Text(
            plant.nombre,

            style: const TextStyle(
              fontSize: 32,

              height: 1.08,

              fontWeight: FontWeight.w800,

              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            plant.descripcion?.trim().isNotEmpty == true
                ? plant.descripcion!
                : 'Información proporcionada por la persona donante.',

            style: const TextStyle(
              fontSize: 15,

              fontStyle: FontStyle.italic,

              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          _sectionTitle(Icons.grid_view_rounded, 'Características'),

          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,

            shrinkWrap: true,

            physics: const NeverScrollableScrollPhysics(),

            mainAxisSpacing: 10,

            crossAxisSpacing: 10,

            childAspectRatio: 2.25,

            children: [
              _FeatureTile(
                icon: Icons.home_work_outlined,

                title: 'Tipo',

                value: _category,
              ),

              _FeatureTile(
                icon: Icons.straighten,

                title: 'Tamaño',

                value: _size,
              ),

              _FeatureTile(
                icon: Icons.wb_sunny_outlined,

                title: 'Luz',

                value: _light,
              ),

              _FeatureTile(
                icon: Icons.spa_outlined,

                title: 'Cuidado',

                value: _care,
              ),

              _FeatureTile(
                icon: Icons.health_and_safety_outlined,

                title: 'Salud',

                value: _health,

                valueColor: AppColors.accent,
              ),

              _FeatureTile(
                icon: Icons.location_on_outlined,

                title: 'Zona',

                value: _location,
              ),
            ],
          ),

          const SizedBox(height: 28),

          _sectionTitle(Icons.description_outlined, 'Descripción de la planta'),

          const SizedBox(height: 12),

          _SoftPanel(
            child: Text(
              plant.descripcion?.trim().isNotEmpty == true
                  ? plant.descripcion!
                  : 'La persona donante no agregó una descripción para esta planta.',

              style: const TextStyle(
                height: 1.55,

                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 28),

          _sectionTitle(Icons.water_drop_outlined, 'Cuidados recomendados'),

          const SizedBox(height: 12),

          _SoftPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Información de riego: $_water',

                  style: const TextStyle(
                    height: 1.5,

                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 14),

                Wrap(
                  spacing: 8,

                  runSpacing: 8,

                  children: [
                    _CareChip(
                      icon: Icons.water_drop_outlined,

                      label: 'Riego: $_water',
                    ),

                    _CareChip(
                      icon: Icons.wb_sunny_outlined,

                      label: 'Luz: $_light',
                    ),

                    _CareChip(
                      icon: Icons.spa_outlined,

                      label: 'Cuidado: $_care',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          _InfoCard(
            icon: Icons.verified_outlined,

            title: 'Estado de la publicación',

            description:
                'Estado actual: ${plant.estadoPlanta.isEmpty ? 'No indicado' : plant.estadoPlanta}.',
          ),

          _InfoCard(
            icon: Icons.privacy_tip_outlined,

            title: 'Privacidad protegida',

            description: 'La información mostrada corresponde a los datos públicos de esta publicación.',
          ),

          const _StatusLegend(),

          if (_submittedRequest != null)
            Align(
              alignment: Alignment.center,

              child: OutlinedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),

                label: const Text('Mensajes'),

                onPressed: () => _openChatPlaceholder(_submittedRequest!),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _sectionTitle(IconData icon, String title) => Row(
    children: [
      Icon(icon, color: AppColors.accent, size: 20),

      const SizedBox(width: 8),

      Text(
        title,

        style: const TextStyle(
          fontSize: 19,

          fontWeight: FontWeight.w800,

          color: AppColors.primary,
        ),
      ),
    ],
  );

  Future<void> _requestAdoptionRemote() async {
    if (_isOwner || !_isAvailable || _requestSent) return;

    final reason = await showModalBottomSheet<String>(
      context: context,

      isScrollControlled: true,

      showDragHandle: true,

      builder: (_) => _RequestSheetDesign(plant: plant),
    );

    if (!mounted || reason == null || reason.trim().isEmpty) return;

    final controller = context.read<AdoptionRequestController>();

    final request = await controller.create(
      plantId: plant.idPlanta,

      reason: reason.trim(),
    );

    if (!mounted) return;

    if (request == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black87,

          content: Text(controller.error ?? 'No se pudo enviar la solicitud.'),
        ),
      );

      return;
    }

    setState(() {
      _requestSent = true;

      _submittedRequest = request;
    });

    await Navigator.pushReplacement(
      context,

      MaterialPageRoute(
        builder: (_) => AdoptionSuccessView(plantName: plant.nombre),
      ),
    );

    return;

    /* await showDialog<void>(

      context: context,

      builder: (context) => AlertDialog(

        icon: const Icon(Icons.check_circle, color: AppColors.accent, size: 48),

        title: const Text('¡Solicitud enviada!'),

        content: const Text('El donante recibió tu motivo de adopción.'),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(context),

            child: const Text('Entendido'),

          ),

        ],

      ),

    ); */
  }

  void _openChatPlaceholder(AdoptionRequest request) {
    // TODO: navegar al chat con request_id, plant_id y datos básicos del otro usuario.

    // request.id, request.plantId, request.adopterName y request.adopterEmail están disponibles.
  }
}

class _RequestSheet extends StatefulWidget {
  const _RequestSheet();

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,

      0,

      20,

      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),

    child: Column(
      mainAxisSize: MainAxisSize.min,

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          'Solicitar adopción',

          style: TextStyle(
            fontSize: 20,

            fontWeight: FontWeight.w800,

            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Cuéntale al donante por qué te gustaría darle un hogar a esta planta.',

          style: TextStyle(color: AppColors.textSecondary),
        ),

        const SizedBox(height: 16),

        TextField(
          controller: _controller,

          maxLength: 500,

          maxLines: 5,

          autofocus: true,

          decoration: const InputDecoration(
            hintText: 'Escribe tu motivo de adopción...',
          ),
        ),

        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,

          height: 48,

          child: FilledButton(
            onPressed: () => Navigator.pop(context, _controller.text),

            child: const Text('Confirmar solicitud'),
          ),
        ),

        const SizedBox(height: 8),
      ],
    ),
  );
}

/* class _RequestSheetV2 extends StatefulWidget {

  final PlantModel plant;

  const _RequestSheetV2({required this.plant});

  @override State<_RequestSheetV2> createState() => _RequestSheetV2State();

}



class _RequestSheetV2State extends State<_RequestSheetV2> {

  final _controller = TextEditingController();

  @override void dispose() { _controller.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) => Material(color: AppColors.background, child: SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 16), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

    Row(children: [IconButton(icon: const Icon(Icons.close, color: AppColors.primary), onPressed: () => Navigator.pop(context)), const Expanded(child: Center(child: Text('Solicitar adopción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)))), const CircleAvatar(radius: 18, backgroundColor: AppColors.primary, child: Icon(Icons.spa_outlined, color: Colors.white, size: 20))]),

    const SizedBox(height: 12),

    Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Row(children: [ClipOval(child: SizedBox(width: 54, height: 54, child: PlantImage(url: widget.plant.fotografiaUrl))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFDCE9DF), borderRadius: BorderRadius.circular(12)), child: const Text('Disponible', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary))), const SizedBox(height: 5), Text(widget.plant.nombre, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)), Text('${widget.plant.categoria?.nombre ?? 'Planta'}  ·  ${widget.plant.estadoSalud.isEmpty ? 'Rescate comunitario' : widget.plant.estadoSalud}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))]))]),

    const SizedBox(height: 22), const Text('¿Por qué deseas adoptar esta planta? *', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)), const SizedBox(height: 6), const Text('Cuéntale al donante cómo la cuidarías.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)), const SizedBox(height: 10),

    TextField(controller: _controller, maxLength: 500, maxLines: 5, decoration: const InputDecoration(hintText: 'Escribe tu mensaje aquí...', fillColor: Color(0xFFF0EFEA), filled: true, border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(14)))),),

    const SizedBox(height: 12), Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFEEEBE2), borderRadius: BorderRadius.circular(16)), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.lightbulb_outline, color: AppColors.accent), SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Consejo de adopción', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)), SizedBox(height: 4), Text('Menciona si tienes buena luz natural o experiencia previa con plantas tropicales.', style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textSecondary))]))]),

    const SizedBox(height: 12), const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.shield_outlined, size: 18, color: AppColors.textDisabled), SizedBox(width: 8), Expanded(child: Text('Tu solicitud será evaluada directamente por el donante. No compartiremos datos sensibles.', style: TextStyle(fontSize: 11, height: 1.4, color: AppColors.textSecondary)))]), const SizedBox(height: 18),

    SizedBox(width: double.infinity, height: 50, child: FilledButton.icon(onPressed: () => Navigator.pop(context, _controller.text), icon: const Icon(Icons.front_hand_outlined), label: const Text('Enviar solicitud', style: TextStyle(fontWeight: FontWeight.w800)))), Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)))),

  ]))))))); */

class _RequestSheetDesign extends StatefulWidget {
  final PlantModel plant;

  const _RequestSheetDesign({required this.plant});

  @override
  State<_RequestSheetDesign> createState() => _RequestSheetDesignState();
}

class _RequestSheetDesignState extends State<_RequestSheetDesign> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;

    return Material(
      color: AppColors.background,

      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,

            0,

            20,

            MediaQuery.viewInsetsOf(context).bottom + 16,
          ),

          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.primary),

                      onPressed: () => Navigator.pop(context),
                    ),

                    const Expanded(
                      child: Center(
                        child: Text(
                          'Solicitar adopción',

                          style: TextStyle(
                            fontSize: 18,

                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const CircleAvatar(
                      radius: 18,

                      backgroundColor: AppColors.primary,

                      child: Icon(
                        Icons.spa_outlined,

                        color: Colors.white,

                        size: 20,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(14),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: Row(
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: 54,

                          height: 54,

                          child: PlantImage(url: plant.fotografiaUrl),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            const _AvailableBadge(),

                            const SizedBox(height: 5),

                            Text(
                              plant.nombre,

                              style: const TextStyle(
                                fontWeight: FontWeight.w800,

                                color: AppColors.primary,
                              ),
                            ),

                            Text(
                              plant.categoria?.nombre ?? 'Planta',

                              style: const TextStyle(
                                fontSize: 11,

                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  '¿Por qué deseas adoptar esta planta? *',

                  style: TextStyle(
                    fontWeight: FontWeight.w800,

                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Cuéntale al donante cómo la cuidarías.',

                  style: TextStyle(
                    fontSize: 12,

                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: _controller,

                  maxLength: 500,
                  maxLengthEnforcement: MaxLengthEnforcement.none,
                  onChanged: (_) => setState(() {}),

                  maxLines: 5,

                  decoration: InputDecoration(
                    errorText: _controller.text.runes.length > 500
                        ? 'Máximo 500 caracteres.'
                        : null,
                    hintText: 'Escribe tu mensaje aquí...',

                    fillColor: Color(0xFFF0EFEA),

                    filled: true,

                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,

                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                const _AdviceBox(),

                const SizedBox(height: 12),

                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Icon(
                      Icons.shield_outlined,

                      size: 18,

                      color: AppColors.textDisabled,
                    ),

                    SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        'Tu solicitud será evaluada directamente por el donante. No compartiremos datos sensibles.',

                        style: TextStyle(
                          fontSize: 11,

                          height: 1.4,

                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,

                  height: 50,

                  child: FilledButton.icon(
                    onPressed:
                        _controller.text.trim().isEmpty ||
                            _controller.text.runes.length > 500
                        ? null
                        : () => Navigator.pop(context, _controller.text.trim()),

                    icon: const Icon(Icons.front_hand_outlined),

                    label: const Text(
                      'Enviar solicitud',

                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),

                    child: const Text(
                      'Cancelar',

                      style: TextStyle(
                        color: AppColors.primary,

                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailableBadge extends StatelessWidget {
  const _AvailableBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

    decoration: BoxDecoration(
      color: const Color(0xFFDCE9DF),

      borderRadius: BorderRadius.circular(12),
    ),

    child: const Text(
      'Disponible',

      style: TextStyle(
        fontSize: 10,

        fontWeight: FontWeight.w700,

        color: AppColors.primary,
      ),
    ),
  );
}

class _AdviceBox extends StatelessWidget {
  const _AdviceBox();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),

    decoration: BoxDecoration(
      color: const Color(0xFFEEEBE2),

      borderRadius: BorderRadius.circular(16),
    ),

    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Icon(Icons.lightbulb_outline, color: AppColors.accent),

        SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                'Consejo de adopción',

                style: TextStyle(
                  fontWeight: FontWeight.w800,

                  color: AppColors.primary,
                ),
              ),

              SizedBox(height: 4),

              Text(
                'Menciona si tienes buena luz natural o experiencia previa con plantas tropicales.',

                style: TextStyle(
                  fontSize: 12,

                  height: 1.4,

                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Gallery extends StatelessWidget {
  final PlantModel plant;

  final bool favorite;

  final VoidCallback onFavorite;

  const _Gallery({
    required this.plant,

    required this.favorite,

    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(28),

        child: SizedBox(
          height: 285,

          width: double.infinity,

          child: PlantImage(url: plant.fotografiaUrl),
        ),
      ),

      Positioned(
        top: 16,

        left: 16,

        child: _StatusChip(
          label: plant.estadoPlanta.isEmpty
              ? 'Estado no indicado'
              : plant.estadoPlanta,
        ),
      ),

      Positioned(
        top: 12,

        right: 12,

        child: CircleAvatar(
          backgroundColor: Colors.white,

          child: IconButton(
            icon: Icon(
              favorite ? Icons.favorite : Icons.favorite_border,

              color: favorite ? Colors.redAccent : AppColors.primary,
            ),

            onPressed: onFavorite,
          ),
        ),
      ),
    ],
  );
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),

    decoration: BoxDecoration(
      color: AppColors.primary,

      borderRadius: BorderRadius.circular(20),
    ),

    child: Text(
      label,

      style: const TextStyle(
        color: Colors.white,

        fontSize: 11,

        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;

  final String title, value;

  final Color valueColor;

  const _FeatureTile({
    required this.icon,

    required this.title,

    required this.value,

    this.valueColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),

    decoration: BoxDecoration(
      color: AppColors.fieldBackground,

      borderRadius: BorderRadius.circular(14),
    ),

    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.accent),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: const TextStyle(
                  fontSize: 10,

                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  fontSize: 12,

                  fontWeight: FontWeight.w800,

                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SoftPanel extends StatelessWidget {
  final Widget child;

  const _SoftPanel({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,

    padding: const EdgeInsets.all(16),

    decoration: BoxDecoration(
      color: Colors.white,

      borderRadius: BorderRadius.circular(18),

      border: Border.all(color: AppColors.border),
    ),

    child: child,
  );
}

class _CareChip extends StatelessWidget {
  final IconData icon;

  final String label;

  const _CareChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),

    decoration: BoxDecoration(
      color: AppColors.fieldBackground,

      borderRadius: BorderRadius.circular(10),
    ),

    child: Row(
      mainAxisSize: MainAxisSize.min,

      children: [
        Icon(icon, size: 15, color: AppColors.accent),

        const SizedBox(width: 5),

        Text(
          label,

          style: const TextStyle(
            fontSize: 10,

            fontWeight: FontWeight.w700,

            color: AppColors.primary,
          ),
        ),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final IconData icon;

  final String title, description;

  const _InfoCard({
    required this.icon,

    required this.title,

    required this.description,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),

    padding: const EdgeInsets.all(15),

    decoration: BoxDecoration(
      color: Colors.white,

      borderRadius: BorderRadius.circular(17),

      border: Border.all(color: AppColors.border),
    ),

    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        CircleAvatar(
          radius: 20,

          backgroundColor: AppColors.fieldBackground,

          child: Icon(icon, color: AppColors.accent, size: 21),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: const TextStyle(
                  fontWeight: FontWeight.w800,

                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                description,

                style: const TextStyle(
                  fontSize: 12,

                  height: 1.4,

                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StatusLegend extends StatelessWidget {
  const _StatusLegend();

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Leyenda de estados',

            style: TextStyle(
              fontWeight: FontWeight.w800,

              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 10),

          const _LegendRow(
            color: AppColors.primary,

            label: 'Disponible',

            text: 'La API permite solicitar adopción.',
          ),

          const _LegendRow(
            color: Colors.grey,

            label: 'Solicitud en revisión',

            text: 'El estado ya no permite nuevas solicitudes.',
          ),

          const _LegendRow(
            color: Colors.black45,

            label: 'Adoptada',

            text: 'La publicación no está disponible.',
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;

  final String label, text;

  const _LegendRow({
    required this.color,

    required this.label,

    required this.text,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),

    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Icon(Icons.circle, color: color, size: 10),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            '$label: $text',

            style: const TextStyle(
              fontSize: 11,

              height: 1.35,

              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RequestBar extends StatelessWidget {
  final bool enabled;

  final String label;

  final VoidCallback onPressed;

  const _RequestBar({
    required this.enabled,

    required this.label,

    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      color: Colors.white,

      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),

      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          SizedBox(
            width: double.infinity,

            height: 52,

            child: FilledButton(
              onPressed: enabled ? onPressed : null,

              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,

                disabledBackgroundColor: Colors.grey.shade400,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),

              child: Text(
                label,

                style: const TextStyle(
                  fontSize: 16,

                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Adopción comunitaria gratuita  ·  Sin intermediarios comerciales',

            textAlign: TextAlign.center,

            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}
