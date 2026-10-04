import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/controllers/plant_controller.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_routes.dart';
import 'package:flutter_app/core/utils/validators.dart';
import 'package:flutter_app/models/plant_model.dart';
import 'package:flutter_app/services/pending_plant_draft.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class PlantFormView extends StatefulWidget {
  final int? plantId;

  const PlantFormView({super.key, this.plantId});

  @override
  State<PlantFormView> createState() => _PlantFormViewState();
}

class _PlantFormViewState extends State<PlantFormView> {
  static const _sizes = [
    (value: 'Pequeno', label: 'Pequeña', detail: 'Hasta 30 cm'),
    (value: 'Mediano', label: 'Mediana', detail: '30 cm a 1 m'),
    (value: 'Grande', label: 'Grande', detail: 'Más de 1 m'),
  ];
  static const _healthStates = [
    'Excelente',
    'Bueno',
    'Requiere cuidados (Rescate)',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _careController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lightController = TextEditingController();
  final _waterController = TextEditingController();
  final _picker = ImagePicker();

  int? _categoryId;
  String? _size;
  String? _health;
  final List<({List<int> bytes, String name})> _selectedImages = [];
  final List<String> _keptPhotos = [];
  bool _picking = false;
  int get _photoCount => _selectedImages.length + _keptPhotos.length;
  PlantModel? _editingPlant;
  bool _preparing = true;

  bool get _isEditing => widget.plantId != null;
  bool get _canEdit =>
      _editingPlant != null &&
      _editingPlant!.estadoPlanta.toUpperCase() == 'DISPONIBLE' &&
      _editingPlant!.visible &&
      !_editingPlant!.eliminada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    final auth = context.read<AuthController>();
    final plants = context.read<PlantController>();
    if (!await auth.ensureAuthenticated()) {
      if (mounted) context.go(AppRoutes.login);
      return;
    }

    await plants.loadCategories();

    if (_isEditing) {
      _editingPlant = await plants.loadMyPlant(widget.plantId!);
      if (_editingPlant != null) _fillForm(_editingPlant!);
    }
    final draft = PendingPlantDraft.value;
    if (draft != null &&
        draft['ownerId'] == auth.currentUser?.idUsuario &&
        draft['plantId'] == widget.plantId) {
      _nameController.text = draft['name'];
      _careController.text = draft['care'];
      _locationController.text = draft['location'];
      _descriptionController.text = draft['description'];
      _lightController.text = draft['light'];
      _waterController.text = draft['water'];
      _categoryId = draft['category'];
      _size = draft['size'];
      _health = draft['health'];
      _keptPhotos
        ..clear()
        ..addAll(List<String>.from(draft['kept']));
      _selectedImages.addAll(
        (draft['photos'] as List).map(
          (p) => (bytes: List<int>.from(p['bytes']), name: p['name'] as String),
        ),
      );
      if (mounted && draft['error'] != null) _showError(draft['error']);
      await PendingPlantDraft.clear();
    }
    if (mounted) setState(() => _preparing = false);
  }

  void _fillForm(PlantModel plant) {
    _nameController.text = plant.nombre;
    _careController.text = plant.nivelCuidado;
    _locationController.text = plant.ubicacion;
    _descriptionController.text = plant.descripcion ?? '';
    _lightController.text = plant.necesidadLuz;
    _waterController.text = plant.necesidadAgua;
    _categoryId = plant.idCategoria;
    _size = plant.tamano;
    _health = plant.estadoSalud;
    _keptPhotos.addAll(
      plant.fotografias.isNotEmpty
          ? plant.fotografias
          : [if (plant.fotografiaUrl != null) plant.fotografiaUrl!],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _careController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _lightController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    if (_picking || _photoCount >= 5) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => context.pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar una foto'),
              onTap: () => context.pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    if (!mounted) return;
    setState(() => _picking = true);
    try {
      final userId = context.read<AuthController>().currentUser?.idUsuario;
      if (userId == null) {
        _showError(
          'No se pudo verificar tu cuenta. Vuelve a abrir la publicación.',
        );
        return;
      }
      await PendingPlantDraft.save({
        'ownerId': userId,
        'plantId': widget.plantId,
        'name': _nameController.text,
        'care': _careController.text,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'light': _lightController.text,
        'water': _waterController.text,
        'category': _categoryId,
        'size': _size,
        'health': _health,
        'kept': List.of(_keptPhotos),
        'photos': _selectedImages
            .map((p) => {'bytes': p.bytes, 'name': p.name})
            .toList(),
      });
      final List<XFile> images;
      if (source == ImageSource.gallery) {
        images = await _picker.pickMultiImage(
          imageQuality: 85,
          maxWidth: 2000,
          maxHeight: 2000,
        );
      } else {
        final image = await _picker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 2000,
          maxHeight: 2000,
        );
        images = [?image];
      }
      if (!mounted) return;
      if (images.length + _photoCount > 5) {
        _showError(
          'Puedes tener hasta cinco fotos. Selecciona menos imágenes.',
        );
        return;
      }
      final selected = <({List<int> bytes, String name})>[];
      for (final image in images) {
        if (await image.length() > 8 * 1024 * 1024) {
          if (mounted) {
            _showError('Cada fotografía debe pesar como máximo 8 MB.');
          }
          return;
        }
        selected.add((bytes: await image.readAsBytes(), name: image.name));
      }
      if (mounted) setState(() => _selectedImages.addAll(selected));
    } catch (_) {
      if (mounted) {
        _showError(
          'No se pudieron abrir las fotos. Revisa los permisos de cámara o galería.',
        );
      }
    } finally {
      await PendingPlantDraft.clear();
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _submit() async {
    if (_picking || context.read<PlantController>().isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null || _size == null || _health == null) {
      _showError('Completa los selectores obligatorios.');
      return;
    }
    if (!_isEditing && _photoCount == 0) {
      _showError('Agrega una foto principal para continuar.');
      return;
    }
    if (_isEditing && !_canEdit) {
      _showError('Solo puedes editar plantas disponibles.');
      return;
    }
    if (_isEditing && _photoCount == 0) {
      _showError('La publicación debe conservar al menos una fotografía.');
      return;
    }

    final request = PlantRequest(
      nombre: _nameController.text.trim(),
      tamano: _size!,
      nivelCuidado: _careController.text.trim(),
      estadoSalud: _health!,
      necesidadLuz: _lightController.text.trim(),
      necesidadAgua: _waterController.text.trim(),
      ubicacion: _locationController.text.trim(),
      idCategoria: _categoryId!,
      descripcion: _descriptionController.text.trim(),
    );
    final plants = context.read<PlantController>();
    final result = _isEditing
        ? await plants.updatePlant(
            widget.plantId!,
            request,
            photos: List.of(_selectedImages),
            keepPhotos: List.of(_keptPhotos),
          )
        : await plants.createPlant(request, photos: List.of(_selectedImages));
    if (!mounted) return;
    if (result == null) {
      _showError(plants.friendlyError());
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? 'Publicación actualizada.'
              : 'Publicación inmediata: Disponible',
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) context.go(AppRoutes.home);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(backgroundColor: AppColors.error, content: Text(message)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final plants = context.watch<PlantController>();
    if (_preparing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌿', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              'PlantHaven · Publicar',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 10, 18, 12),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Cancelar',
              icon: const Icon(Icons.close),
              onPressed: () => context.go(AppRoutes.home),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: plants.isLoading ? null : _submit,
                  icon: plants.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(Icons.publish_outlined),
                  label: Text(
                    _isEditing ? 'Guardar cambios' : 'Publicar planta',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          children: [
            Row(
              children: [
                _badge('NUEVA ADOPCIÓN'),
                const Spacer(),
                const Text(
                  'Paso 1 de 1',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Publicar una planta',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Comparte una planta y ayuda a encontrarle un nuevo hogar.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            _photoSection(),
            const SizedBox(height: 26),
            _sectionLabel('Nombre de la planta *'),
            TextFormField(
              controller: _nameController,
              maxLength: 100,
              validator: Validators.required,
              decoration: const InputDecoration(
                hintText: 'Ej. Monstera deliciosa',
                prefixIcon: Icon(Icons.local_florist_outlined),
              ),
            ),
            const SizedBox(height: 22),
            _sectionLabel('Tipo de planta *'),
            if (plants.categories.isEmpty)
              const Text(
                'No se pudieron cargar las categorías desde el servidor.',
                style: TextStyle(color: AppColors.error, fontSize: 12),
              )
            else
              Wrap(
                spacing: 8,
                children: plants.categories
                    .map(
                      (item) => ChoiceChip(
                        label: Text(item.nombre),
                        selected: _categoryId == item.idCategoria,
                        onSelected: plants.isLoading
                            ? null
                            : (_) => setState(
                                () => _categoryId = item.idCategoria,
                              ),
                      ),
                    )
                    .toList(),
              ),
            if (_categoryId == null)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Selecciona un tipo de planta',
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 22),
            _sectionLabel('Tamaño aproximado *'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sizes
                  .map(
                    (item) => ChoiceChip(
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.label),
                          Text(
                            item.detail,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      selected: _size == item.value,
                      onSelected: plants.isLoading
                          ? null
                          : (_) => setState(() => _size = item.value),
                    ),
                  )
                  .toList(),
            ),
            if (_size == null)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Selecciona un tamaño',
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 22),
            _sectionLabel('Cuidados necesarios *'),
            TextFormField(
              controller: _careController,
              maxLength: 50,
              validator: Validators.required,
              decoration: const InputDecoration(
                hintText: 'Ej. Luz indirecta y riego semanal',
                prefixIcon: Icon(Icons.spa_outlined),
              ),
            ),
            const SizedBox(height: 22),
            _sectionLabel('Necesidad de luz *'),
            TextFormField(
              controller: _lightController,
              maxLength: 100,
              validator: Validators.required,
              decoration: const InputDecoration(hintText: 'Ej. Luz indirecta'),
            ),
            _sectionLabel('Necesidad de agua *'),
            TextFormField(
              controller: _waterController,
              maxLength: 100,
              validator: Validators.required,
              decoration: const InputDecoration(hintText: 'Ej. Riego semanal'),
            ),
            _sectionLabel('Estado de salud actual *'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _healthStates
                  .map(
                    (item) => ChoiceChip(
                      label: Text(item),
                      selected: _health == item,
                      onSelected: plants.isLoading
                          ? null
                          : (_) => setState(() => _health = item),
                    ),
                  )
                  .toList(),
            ),
            if (_health == null)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Selecciona el estado de salud',
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 22),
            _sectionLabel('Ubicación aproximada *'),
            TextFormField(
              controller: _locationController,
              maxLength: 255,
              validator: Validators.required,
              decoration: const InputDecoration(
                hintText: 'Ej. Santa Tecla',
                prefixIcon: Icon(Icons.near_me_outlined),
                suffixIcon: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'ZONA GENERAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            _sectionLabel('Historia o descripción adicional'),
            TextFormField(
              controller: _descriptionController,
              maxLength: 250,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Cuéntanos un poco más sobre esta planta...',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_outlined, color: AppColors.accent),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Publicación inmediata',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Chip(label: Text('Disponible')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.accent.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.accent,
      ),
    ),
  );

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
  );

  Widget _photoSection() {
    final busy = _picking || context.watch<PlantController>().isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fotografías ($_photoCount/5)',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (int i = 0; i < _keptPhotos.length; i++)
              _photoTile(
                Image.network(
                  _keptPhotos[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stack) =>
                      const Center(child: Icon(Icons.broken_image)),
                ),
                i,
                busy ? null : () => setState(() => _keptPhotos.removeAt(i)),
              ),
            for (int i = 0; i < _selectedImages.length; i++)
              _photoTile(
                Image.memory(
                  Uint8List.fromList(_selectedImages[i].bytes),
                  fit: BoxFit.cover,
                ),
                _keptPhotos.length + i,
                busy ? null : () => setState(() => _selectedImages.removeAt(i)),
              ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: busy || _photoCount >= 5 ? null : _chooseImage,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(_picking ? 'Leyendo fotos...' : 'Agregar fotos'),
        ),
        const Text(
          'De una a cinco fotos. La primera será la principal. Los cambios se aplican al guardar.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _photoTile(Widget image, int index, VoidCallback? remove) => SizedBox(
    width: 120,
    height: 130,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: image),
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(3),
            child: Text(index == 0 ? 'Principal' : 'Foto ${index + 1}'),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton.filled(
            tooltip: 'Quitar foto ${index + 1}',
            onPressed: remove,
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    ),
  );
}
