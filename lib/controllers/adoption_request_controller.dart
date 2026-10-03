import 'package:flutter/foundation.dart';
import 'package:flutter_app/models/adoption_request_model.dart';
import 'package:flutter_app/services/adoption_request_service.dart';

class AdoptionRequestController extends ChangeNotifier {
  final AdoptionRequestService _service;
  AdoptionRequestController({AdoptionRequestService? service})
    : _service = service ?? AdoptionRequestService();

  List<AdoptionRequest> _received = [];
  List<AdoptionRequest> _mine = [];
  bool _isLoading = false;
  String? _error;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AdoptionRequest> get receivedRequests => List.unmodifiable(_received);
  List<AdoptionRequest> get myRequests => List.unmodifiable(_mine);

  Future<AdoptionRequest?> create({
    required int plantId,
    required String reason,
  }) async {
    try {
      _error = null;
      final request = await _service.create(plantId: plantId, reason: reason);
      _mine = [request, ..._mine];
      notifyListeners();
      return request;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> loadReceived() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _received = await _service.received();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loadMine() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _mine = await _service.mine();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
