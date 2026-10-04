import 'package:flutter/foundation.dart';
import 'package:flutter_app/core/constants/app_routes.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';

/// Respaldo únicamente mientras Android abre la cámara o la galería.
/// No contiene contraseñas ni tokens y pertenece a una sola cuenta.
class PendingPlantDraft {
  static Box? _box;
  static Map? get value => _box?.get('draft') as Map?;
  static String initialRoute = AppRoutes.login;

  static Future<void> initialize({ImagePicker? picker}) async {
    _box = await Hive.openBox('pending_plant_capture');
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final lost = await (picker ?? ImagePicker()).retrieveLostData();
        await recoverFiles(lost.files ?? []);
        if (lost.exception != null && value != null) {
          await save({
            ...value!,
            'error': 'No se pudo recuperar la foto. Inténtalo otra vez.',
          });
        }
      } catch (_) {
        if (value != null) {
          await save({
            ...value!,
            'error': 'No se pudo recuperar la foto. Inténtalo otra vez.',
          });
        }
      }
    }
  }

  static Future<void> save(Map draft) async {
    await _box!.put('draft', draft);
    await _box!.flush();
  }

  static Future<void> clear() async => _box?.delete('draft');

  static String get pendingRoute {
    final id = value?['plantId'];
    return id == null ? AppRoutes.publishPlant : '/editar-planta/$id';
  }

  static String routeForUser(int? userId) =>
      userId != null && value?['ownerId'] == userId
      ? pendingRoute
      : AppRoutes.home;

  static Future<void> recoverFiles(List<XFile> files) async {
    final draft = value;
    if (draft == null || files.isEmpty) return;
    final photos = List<Map>.from(draft['photos'] ?? []);
    final count = photos.length + (draft['kept'] as List).length;
    if (count + files.length > 5) {
      await save({
        ...draft,
        'error': 'Puedes tener hasta cinco fotos. Selecciona menos imágenes.',
      });
      return;
    }
    final recovered = <Map>[];
    for (final file in files) {
      if (await file.length() > 8 * 1024 * 1024) {
        await save({
          ...draft,
          'error': 'Cada fotografía debe pesar como máximo 8 MB.',
        });
        return;
      }
      recovered.add({'bytes': await file.readAsBytes(), 'name': file.name});
    }
    await save({
      ...draft,
      'photos': [...photos, ...recovered],
    });
  }
}
