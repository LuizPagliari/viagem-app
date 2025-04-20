import 'package:uuid/uuid.dart';

class TripDay {
  final String id;
  final DateTime date;
  final List<String> destinationIds; // IDs dos destinos para este dia
  String? notes; // Notas opcionais para este dia

  TripDay({
    String? id,
    required this.date,
    List<String>? destinationIds,
    this.notes,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.destinationIds = destinationIds ?? [];

  // Adicionar um destino a este dia
  void addDestination(String destinationId) {
    if (!destinationIds.contains(destinationId)) {
      destinationIds.add(destinationId);
    }
  }

  // Remover um destino deste dia
  void removeDestination(String destinationId) {
    destinationIds.remove(destinationId);
  }

  // Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'destinationIds': destinationIds,
      'notes': notes,
    };
  }

  // Criar a partir de JSON
  factory TripDay.fromJson(Map<String, dynamic> json) {
    return TripDay(
      id: json['id'],
      date: DateTime.parse(json['date']),
      destinationIds: List<String>.from(json['destinationIds'] ?? []),
      notes: json['notes'],
    );
  }
}