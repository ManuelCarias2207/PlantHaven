import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/controllers/plant_controller.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_routes.dart';
import 'package:flutter_app/core/utils/validators.dart';
import 'package:flutter_app/models/plant_model.dart';
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
  final _picker = ImagePicker();

  int? _categoryId;
  String? _size;
  String? _health;
  XFile? _selectedImage;
  PlantModel? _editingPlant;
  bool _preparing = true;

  bool get _isEditing => widget.plantId != null;
  bool get _canEdit =>
      _editingPlant != null &&
      _editingPlant!.estadoPlanta.toUpperCase() == 'DISPONIBLE' &&
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
      await plants.loadMyPlants();
      final matches = plants.myPlants
          .where((item) => item.idPlanta == widget.plantId)
          .toList();
      _editingPlant = matches.isEmpty ? null : matches.first;
      if (_editingPlant != null) _fillForm(_editingPlant!);
    }
    if (mounted) setState(() => _preparing = false);
  }

  void _fillForm(PlantModel plant) {
    _nameController.text = plant.nombre;
    _careController.text = plant.nivelCuidado;
    _locationController.text = plant.ubicacion;
    _descriptionController.text = plant.descripcion ?? '';
    _categoryId = plant.idCategoria;
    _size = plant.tamano;
    _health = plant.estadoSalud;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _careController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
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
    final image = await _picker.pickImage(source: source, imageQuality: 85);
    if (mounted && image != null) setState(() => _selectedImage = image);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null || _size == null || _health == null) {
      _showError('Completa los selectores obligatorios.');
      return;
    }
    if (!_isEditing && _selectedImage == null) {
      _showError('Agrega una foto principal para continuar.');
      return;
    }
    if (_isEditing && !_canEdit) {
      _showError('Solo puedes editar plantas disponibles.');
      return;
    }
    if (_isEditing &&
        _selectedImage == null &&
        (_editingPlant?.fotografiaUrl?.isEmpty ?? true)) {
      _showError('La publicación debe conservar al menos una fotografía.');
      return;
    }

    final request = PlantRequest(
      nombre: _nameController.text.trim(),
      tamano: _size!,
      nivelCuidado: _careController.text.trim(),
      estadoSalud: _health!,
      necesidadLuz: 'Media',
      necesidadAgua: 'Medio',
      ubicacion: _locationController.text.trim(),
      idCategoria: _categoryId!,
      descripcion: _descriptionController.text.trim(),
    );
    final plants = context.read<PlantController>();
    final imageBytes = _selectedImage == null
        ? null
        : await _selectedImage!.readAsBytes();
    final result = _isEditing
        ? await plants.updatePlant(
            widget.plantId!,
            request,
            imageBytes: imageBytes,
            imageName: _selectedImage?.name,
          )
        : await plants.createPlant(
            request,
            imageBytes: imageBytes,
            imageName: _selectedImage?.name,
          );
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
              maxLength: 40,
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
              validator: Validators.required,
              decoration: const InputDecoration(
                hintText: 'Ej. Luz indirecta y riego semanal',
                prefixIcon: Icon(Icons.spa_outlined),
              ),
            ),
            const SizedBox(height: 22),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Foto principal',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            _badge('REQUERIDA'),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 190,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.fieldBackground,
            borderRadius: BorderRadius.circular(18),
          ),
          child: _selectedImage == null
              ? InkWell(
                  onTap: _chooseImage,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 42,
                        color: AppColors.accent,
                      ),
                      SizedBox(height: 8),
                      Text('Agrega una foto clara de tu planta'),
                    ],
                  ),
                )
              : FutureBuilder<Uint8List>(
                  future: _selectedImage!.readAsBytes(),
                  builder: (_, snapshot) => snapshot.hasData
                      ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                      : const Center(child: CircularProgressIndicator()),
                ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _chooseImage,
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(
                _selectedImage == null ? 'Cargar foto' : 'Cambiar foto',
              ),
            ),
            if (_selectedImage != null)
              IconButton(
                tooltip: 'Eliminar foto',
                onPressed: () => setState(() => _selectedImage = null),
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Usa luz natural y evita fotos oscuras o borrosas.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
