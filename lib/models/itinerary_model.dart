import 'package:uuid/uuid.dart';
import 'trip_day_model.dart';

class Itinerary {
  final String id;
  String name;
  String? description;
  DateTime? startDate;
  DateTime? endDate;
  final List<TripDay> days;

  Itinerary({
    String? id,
    required this.name,
    this.description,
    this.startDate,
    this.endDate,
    List<TripDay>? days,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.days = days ?? [];

  // Adiciona um novo dia ao itinerário
  void addDay(TripDay day) {
    // Verifica se já existe um dia com essa data
    final existingDayIndex = days.indexWhere((d) => 
      d.date.year == day.date.year && 
      d.date.month == day.date.month && 
      d.date.day == day.date.day
    );
    
    if (existingDayIndex >= 0) {
      // Substitui o dia existente
      days[existingDayIndex] = day;
    } else {
      // Adiciona um novo dia e ordena a lista por data
      days.add(day);
      days.sort((a, b) => a.date.compareTo(b.date));
    }
    
    // Atualiza as datas de início e fim com base nos dias existentes
    _updateDateRange();
  }

  // Remove um dia do itinerário
  void removeDay(String dayId) {
    days.removeWhere((day) => day.id == dayId);
    _updateDateRange();
  }

  // Atualiza as datas de início e fim com base nos dias existentes
  void _updateDateRange() {
    if (days.isEmpty) {
      startDate = null;
      endDate = null;
      return;
    }
    
    // Ordena os dias por data
    days.sort((a, b) => a.date.compareTo(b.date));
    startDate = days.first.date;
    endDate = days.last.date;
  }

  // Retorna os dias ordenados por data
  List<TripDay> get sortedDays {
    final sortedList = [...days];
    sortedList.sort((a, b) => a.date.compareTo(b.date));
    return sortedList;
  }

  // Obter um dia por data
  TripDay? getDayByDate(DateTime date) {
    return days.firstWhere(
      (day) => 
        day.date.year == date.year && 
        day.date.month == date.month && 
        day.date.day == date.day,
      orElse: () => TripDay(date: date),
    );
  }

  // Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'days': days.map((day) => day.toJson()).toList(),
    };
  }

  // Criar a partir de JSON
  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      days: json['days'] != null 
          ? List<TripDay>.from(json['days'].map((dayJson) => TripDay.fromJson(dayJson)))
          : [],
    );
  }
}