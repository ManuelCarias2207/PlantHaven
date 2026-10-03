import 'package:flutter/foundation.dart';
import 'package:flutter_app/models/plant_model.dart';
import 'package:flutter_app/services/plant_service.dart';

enum PlantState { initial, loading, ready, error }

class PlantController extends ChangeNotifier {
  final PlantService _plantService;

  PlantController({PlantService? plantService})
    : _plantService = plantService ?? PlantService();

  PlantState _state = PlantState.initial;
  String? _errorMessage;
  List<PlantModel> _plants = [];
  List<PlantModel> _myPlants = [];
  List<PlantCategory> _categories = [];

  PlantState get state => _state;
  String? get errorMessage => _errorMessage;
  List<PlantModel> get plants => List.unmodifiable(_plants);
  List<PlantModel> get myPlants => List.unmodifiable(_myPlants);
  List<PlantCategory> get categories => List.unmodifiable(_categories);
  bool get isLoading => _state == PlantState.loading;

  Future<bool> loadCategories() async {
    _setLoading();
    try {
      final remoteCategories = await _plantService.GetCategories();
      _categories = remoteCategories;
      _setReady();
      return true;
    } catch (e) {
      debugPrint('[PlantController] Error cargando categorías: $e');
      _categories = [];
      _setFailure(e);
      return false;
    }
  }

  Future<bool> loadCatalog() async {
    _setLoading();
    try {
      _plants = await _plantService.GetCatalog();
      _setReady();
      return true;
    } catch (e) {
      _setFailure(e);
      return false;
    }
  }

  Future<bool> loadMyPlants({
    String busqueda = '',
    String? estado,
    bool? retirada,
    int pagina = 1,
  }) async {
    _myPlants = [];
    _setLoading();
    try {
      _myPlants = await _plantService.GetMyPlants(
        busqueda: busqueda,
        estado: estado,
        retirada: retirada,
        pagina: pagina,
      );
      _setReady();
      return true;
    } catch (e) {
      _setFailure(e);
      return false;
    }
  }

  Future<PlantModel?> loadMyPlant(int id) async {
    try {
      return await _plantService.GetMyPlant(id);
    } catch (e) {
      _setFailure(e);
      return null;
    }
  }

  Future<PlantModel?> createPlant(
    PlantRequest request, {
    List<int>? imageBytes,
    String? imageName,
  }) async {
    _setLoading();
    try {
      final plant = await _plantService.CreatePlant(
        request,
        imageBytes: imageBytes,
        imageName: imageName,
      );
      _myPlants = [plant, ..._myPlants];
      await _refreshCatalogAfterMutation();
      _setReady();
      return plant;
    } catch (e, stackTrace) {
      debugPrint('[PlantController] Error publicando planta: $e');
      debugPrint('$stackTrace');
      _setFailure(e);
      return null;
    }
  }

  Future<PlantModel?> updatePlant(
    int id,
    PlantRequest request, {
    List<int>? imageBytes,
    String? imageName,
  }) async {
    _setLoading();
    try {
      final plant = await _plantService.UpdatePlant(
        id,
        request,
        imageBytes: imageBytes,
        imageName: imageName,
      );
      _myPlants = _myPlants
          .map((item) => item.idPlanta == id ? plant : item)
          .toList();
      await _refreshCatalogAfterMutation();
      _setReady();
      return plant;
    } catch (e) {
      _setFailure(e);
      return null;
    }
  }

  Future<bool> deletePlant(PlantModel plant) async {
    _setLoading();
    try {
      await _plantService.DeletePlant(plant.idPlanta);
      _myPlants = _myPlants.map((item) {
        if (item.idPlanta != plant.idPlanta) return item;
        return PlantModel(
          idPlanta: item.idPlanta,
          nombre: item.nombre,
          tamano: item.tamano,
          nivelCuidado: item.nivelCuidado,
          estadoSalud: item.estadoSalud,
          necesidadLuz: item.necesidadLuz,
          necesidadAgua: item.necesidadAgua,
          descripcion: item.descripcion,
          ubicacion: item.ubicacion,
          estadoPlanta: item.estadoPlanta,
          fechaPublicacion: item.fechaPublicacion,
          visible: false,
          eliminada: true,
          idUsuario: item.idUsuario,
          idCategoria: item.idCategoria,
          fotografiaUrl: item.fotografiaUrl,
          puedeSolicitar: false,
          categoria: item.categoria,
        );
      }).toList();
      await _refreshCatalogAfterMutation();
      _setReady();
      return true;
    } catch (e) {
      _setFailure(e);
      return false;
    }
  }

  String friendlyError() {
    final error = _errorMessage ?? 'No se pudo completar la operacion.';
    if (error.contains('HTTP 409') || error.contains('HTTP 400')) {
      return 'La planta cambio de estado. Actualiza la lista e intenta de nuevo.';
    }
    if (error.contains('HTTP 422')) {
      return 'Revisa los datos de la planta e intenta de nuevo.';
    }
    return error;
  }

  void _setLoading() {
    _state = PlantState.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setReady() {
    _state = PlantState.ready;
    _errorMessage = null;
    notifyListeners();
  }

  void _setFailure(Object error) {
    _state = PlantState.error;
    _errorMessage = error.toString();
    notifyListeners();
  }

  Future<void> _refreshCatalogAfterMutation() async {
    try {
      _plants = await _plantService.GetCatalog();
    } catch (e) {
      debugPrint('[PlantController] No se pudo actualizar el catálogo: $e');
    }
  }
}
