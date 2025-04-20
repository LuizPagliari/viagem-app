import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/itinerary_model.dart';
import '../models/trip_day_model.dart';

class ItineraryService {
  static const String _itinerariesKey = 'itineraries';

  // Obter todos os itinerários salvos
  Future<List<Itinerary>> getItineraries() async {
    final prefs = await SharedPreferences.getInstance();
    final itinerariesJson = prefs.getStringList(_itinerariesKey) ?? [];
    
    return itinerariesJson.map((jsonStr) {
      final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
      return Itinerary.fromJson(jsonMap);
    }).toList();
  }

  // Salvar todos os itinerários
  Future<void> saveItineraries(List<Itinerary> itineraries) async {
    final prefs = await SharedPreferences.getInstance();
    final itinerariesJson = itineraries
        .map((itinerary) => json.encode(itinerary.toJson()))
        .toList();
    
    await prefs.setStringList(_itinerariesKey, itinerariesJson);
  }

  // Adicionar ou atualizar um itinerário
  Future<void> saveItinerary(Itinerary itinerary) async {
    final itineraries = await getItineraries();
    final index = itineraries.indexWhere((item) => item.id == itinerary.id);
    
    if (index >= 0) {
      // Atualizar itinerário existente
      itineraries[index] = itinerary;
    } else {
      // Adicionar novo itinerário
      itineraries.add(itinerary);
    }
    
    await saveItineraries(itineraries);
  }

  // Remover um itinerário
  Future<void> deleteItinerary(String itineraryId) async {
    final itineraries = await getItineraries();
    itineraries.removeWhere((itinerary) => itinerary.id == itineraryId);
    await saveItineraries(itineraries);
  }

  // Obter um itinerário específico
  Future<Itinerary?> getItinerary(String itineraryId) async {
    final itineraries = await getItineraries();
    try {
      return itineraries.firstWhere((itinerary) => itinerary.id == itineraryId);
    } catch (e) {
      return null;
    }
  }
}