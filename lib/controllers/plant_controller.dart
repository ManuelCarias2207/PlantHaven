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

  PlantState get state => _state;
  String? get errorMessage => _errorMessage;
  List<PlantModel> get plants => List.unmodifiable(_plants);
  List<PlantModel> get myPlants => List.unmodifiable(_myPlants);
  bool get isLoading => _state == PlantState.loading;

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

  Future<bool> loadMyPlants() async {
    _setLoading();
    try {
      _myPlants = await _plantService.GetMyPlants();
      _setReady();
      return true;
    } catch (e) {
      _setFailure(e);
      return false;
    }
  }

  Future<PlantModel?> createPlant(PlantRequest request) async {
    _setLoading();
    try {
      final plant = await _plantService.CreatePlant(request);
      _myPlants = [plant, ..._myPlants];
      await loadCatalog();
      return plant;
    } catch (e) {
      _setFailure(e);
      return null;
    }
  }

  Future<PlantModel?> updatePlant(int id, PlantRequest request) async {
    _setLoading();
    try {
      final plant = await _plantService.UpdatePlant(id, request);
      _myPlants = _myPlants
          .map((item) => item.idPlanta == id ? plant : item)
          .toList();
      await loadCatalog();
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
          estadoPlanta: 'RETIRADA',
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
      await loadCatalog();
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
}
