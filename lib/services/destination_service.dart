import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/destination_model.dart';

class DestinationService {
  static const String _destinationsKey = 'destinations';

  // Buscar todos os destinos
  Future<List<Destination>> getDestinations() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? destinationsJson = prefs.getString(_destinationsKey);

    if (destinationsJson == null) {
      return [];
    }

    final List<dynamic> jsonList = jsonDecode(destinationsJson);
    return jsonList.map((json) => Destination.fromJson(json)).toList();
  }

  // Salvar todos os destinos
  Future<void> saveDestinations(List<Destination> destinations) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String destinationsJson = jsonEncode(
      destinations.map((destination) => destination.toJson()).toList(),
    );
    
    await prefs.setString(_destinationsKey, destinationsJson);
  }

  // Adicionar um destino
  Future<void> addDestination(Destination destination) async {
    final List<Destination> destinations = await getDestinations();
    destinations.add(destination);
    await saveDestinations(destinations);
  }

  // Remover um destino
  Future<void> removeDestination(String id) async {
    final List<Destination> destinations = await getDestinations();
    destinations.removeWhere((destination) => destination.id == id);
    await saveDestinations(destinations);
  }

  // Atualizar um destino
  Future<void> updateDestination(Destination updatedDestination) async {
    final List<Destination> destinations = await getDestinations();
    final int index = destinations.indexWhere((destination) => destination.id == updatedDestination.id);
    
    if (index != -1) {
      destinations[index] = updatedDestination;
      await saveDestinations(destinations);
    }
  }

  // Marcar como visitado/não visitado
  Future<void> toggleVisited(String id) async {
    final List<Destination> destinations = await getDestinations();
    final int index = destinations.indexWhere((destination) => destination.id == id);
    
    if (index != -1) {
      destinations[index].isVisited = !destinations[index].isVisited;
      await saveDestinations(destinations);
    }
  }
}