import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/destination_model.dart';
import '../services/destination_service.dart';

class DestinationProvider extends ChangeNotifier {
  final DestinationService _destinationService = DestinationService();
  List<Destination> _destinations = [];
  bool _isLoading = false;

  List<Destination> get destinations => _destinations;
  bool get isLoading => _isLoading;

  // Getter para obter destinos por categoria
  Map<String, List<Destination>> get destinationsByCategory {
    final Map<String, List<Destination>> result = {};
    
    for (final destination in _destinations) {
      if (!result.containsKey(destination.category)) {
        result[destination.category] = [];
      }
      result[destination.category]!.add(destination);
    }
    
    return result;
  }

  DestinationProvider() {
    loadDestinations();
  }

  // Carregar destinos do armazenamento local
  Future<void> loadDestinations() async {
    _isLoading = true;
    notifyListeners();
    
    _destinations = await _destinationService.getDestinations();
    
    _isLoading = false;
    notifyListeners();
  }

  // Adicionar um novo destino
  Future<void> addDestination({
    required String name,
    required String description,
    required double latitude,
    required double longitude,
    String category = 'Outros', // Parâmetro de categoria adicionado
  }) async {
    final destination = Destination(
      id: const Uuid().v4(),
      name: name,
      description: description,
      latitude: latitude,
      longitude: longitude,
      category: category, // Categoria passada para o modelo
    );

    await _destinationService.addDestination(destination);
    _destinations.add(destination);
    notifyListeners();
  }

  // Remover um destino
  Future<void> removeDestination(String id) async {
    await _destinationService.removeDestination(id);
    _destinations.removeWhere((destination) => destination.id == id);
    notifyListeners();
  }

  // Marcar como visitado/não visitado
  Future<void> toggleVisited(String id) async {
    await _destinationService.toggleVisited(id);
    final index = _destinations.indexWhere((destination) => destination.id == id);
    if (index != -1) {
      _destinations[index].isVisited = !_destinations[index].isVisited;
      notifyListeners();
    }
  }
  
  // Filtra destinos por categoria
  List<Destination> getDestinationsByCategory(String category) {
    if (category == 'Todos') {
      return _destinations;
    }
    return _destinations.where((dest) => dest.category == category).toList();
  }
}