import 'package:flutter/material.dart';
import '../models/itinerary_model.dart';
import '../models/trip_day_model.dart';
import '../services/itinerary_service.dart';
import 'destination_provider.dart';

class ItineraryProvider extends ChangeNotifier {
  final ItineraryService _itineraryService = ItineraryService();
  final DestinationProvider _destinationProvider;
  List<Itinerary> _itineraries = [];
  bool _isLoading = false;
  
  // Itinerário atualmente selecionado para edição
  Itinerary? _currentItinerary;

  ItineraryProvider(this._destinationProvider) {
    loadItineraries();
  }

  // Getters
  List<Itinerary> get itineraries => _itineraries;
  bool get isLoading => _isLoading;
  Itinerary? get currentItinerary => _currentItinerary;

  // Carregar itinerários do armazenamento
  Future<void> loadItineraries() async {
    _isLoading = true;
    notifyListeners();
    
    _itineraries = await _itineraryService.getItineraries();
    
    _isLoading = false;
    notifyListeners();
  }

  // Criar um novo itinerário
  Future<void> createItinerary({
    required String name, 
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final newItinerary = Itinerary(
      name: name,
      description: description,
      startDate: startDate,
      endDate: endDate,
    );
    
    await _itineraryService.saveItinerary(newItinerary);
    _itineraries.add(newItinerary);
    _currentItinerary = newItinerary;
    
    notifyListeners();
  }

  // Atualizar um itinerário existente
  Future<void> updateItinerary(Itinerary itinerary) async {
    await _itineraryService.saveItinerary(itinerary);
    
    final index = _itineraries.indexWhere((item) => item.id == itinerary.id);
    if (index >= 0) {
      _itineraries[index] = itinerary;
    } else {
      _itineraries.add(itinerary);
    }
    
    notifyListeners();
  }

  // Excluir um itinerário
  Future<void> deleteItinerary(String itineraryId) async {
    await _itineraryService.deleteItinerary(itineraryId);
    _itineraries.removeWhere((itinerary) => itinerary.id == itineraryId);
    
    if (_currentItinerary?.id == itineraryId) {
      _currentItinerary = null;
    }
    
    notifyListeners();
  }

  // Definir o itinerário atual
  void setCurrentItinerary(String? itineraryId) {
    if (itineraryId == null) {
      _currentItinerary = null;
    } else {
      _currentItinerary = _itineraries.firstWhere(
        (itinerary) => itinerary.id == itineraryId,
        orElse: () => _currentItinerary!,
      );
    }
    notifyListeners();
  }

  // Adicionar um dia ao itinerário atual
  Future<void> addDayToItinerary({
    required DateTime date,
    List<String>? destinationIds,
    String? notes,
  }) async {
    if (_currentItinerary == null) return;

    final newDay = TripDay(
      date: date,
      destinationIds: destinationIds,
      notes: notes,
    );

    _currentItinerary!.addDay(newDay);
    await updateItinerary(_currentItinerary!);
  }

  // Remover um dia do itinerário atual
  Future<void> removeDayFromItinerary(String dayId) async {
    if (_currentItinerary == null) return;

    _currentItinerary!.removeDay(dayId);
    await updateItinerary(_currentItinerary!);
  }

  // Adicionar um destino a um dia específico
  Future<void> addDestinationToDay({required String dayId, required String destinationId}) async {
    if (_currentItinerary == null) return;

    final dayIndex = _currentItinerary!.days.indexWhere((day) => day.id == dayId);
    if (dayIndex < 0) return;

    _currentItinerary!.days[dayIndex].addDestination(destinationId);
    await updateItinerary(_currentItinerary!);
  }

  // Remover um destino de um dia específico
  Future<void> removeDestinationFromDay({required String dayId, required String destinationId}) async {
    if (_currentItinerary == null) return;

    final dayIndex = _currentItinerary!.days.indexWhere((day) => day.id == dayId);
    if (dayIndex < 0) return;

    _currentItinerary!.days[dayIndex].removeDestination(destinationId);
    await updateItinerary(_currentItinerary!);
  }

  // Atualizar as notas de um dia
  Future<void> updateDayNotes({required String dayId, required String? notes}) async {
    if (_currentItinerary == null) return;

    final dayIndex = _currentItinerary!.days.indexWhere((day) => day.id == dayId);
    if (dayIndex < 0) return;

    _currentItinerary!.days[dayIndex].notes = notes;
    await updateItinerary(_currentItinerary!);
  }
}