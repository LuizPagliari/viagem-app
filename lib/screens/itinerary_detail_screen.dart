import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/itinerary_model.dart';
import '../models/destination_model.dart';
import '../models/trip_day_model.dart';
import '../providers/itinerary_provider.dart';
import '../providers/destination_provider.dart';
import 'itinerary_day_edit_screen.dart';
import 'itinerary_form_screen.dart';
import 'destination_detail_screen.dart';

class ItineraryDetailScreen extends StatefulWidget {
  final Itinerary itinerary;

  const ItineraryDetailScreen({super.key, required this.itinerary});

  @override
  State<ItineraryDetailScreen> createState() => _ItineraryDetailScreenState();
}

class _ItineraryDetailScreenState extends State<ItineraryDetailScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<TripDay>> _events = {};

  @override
  void initState() {
    super.initState();
    
    // Definir o dia selecionado como a data de início do itinerário, se houver
    if (widget.itinerary.startDate != null) {
      _focusedDay = widget.itinerary.startDate!;
    }
    
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  // Carregar eventos (dias do itinerário) no formato que o calendário espera
  void _loadEvents() {
    _events = {};
    
    for (final day in widget.itinerary.days) {
      // Cria uma chave de data sem horário para o calendário
      final eventDate = DateTime.utc(
        day.date.year, 
        day.date.month, 
        day.date.day,
      );
      
      if (!_events.containsKey(eventDate)) {
        _events[eventDate] = [];
      }
      
      _events[eventDate]!.add(day);
    }
  }

  // Obter a lista de dias para a data selecionada
  List<TripDay> _getEventsForDay(DateTime day) {
    final eventDate = DateTime.utc(day.year, day.month, day.day);
    return _events[eventDate] ?? [];
  }

  // Verificar se um dia tem destinos planejados
  bool _hasEventForDay(DateTime day) {
    final eventDate = DateTime.utc(day.year, day.month, day.day);
    return _events.containsKey(eventDate) && _events[eventDate]!.isNotEmpty && 
           _events[eventDate]!.any((tripDay) => tripDay.destinationIds.isNotEmpty);
  }

  // Abrir a tela para editar um dia do itinerário
  void _openDayEdit(BuildContext context, TripDay? day) {
    // Se não tiver um dia para a data selecionada, cria um novo
    final selectedTripDay = day ?? TripDay(date: _selectedDay!);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItineraryDayEditScreen(
          itinerary: widget.itinerary,
          tripDay: selectedTripDay,
        ),
      ),
    ).then((_) {
      // Recarregar o itinerário atualizado
      _refreshItinerary();
    });
  }

  // Recarregar o itinerário atual
  Future<void> _refreshItinerary() async {
    final itineraryProvider = Provider.of<ItineraryProvider>(context, listen: false);
    await itineraryProvider.loadItineraries();

    // Obter o itinerário atualizado
    final updatedItineraries = itineraryProvider.itineraries;
    final updatedItinerary = updatedItineraries.firstWhere(
      (it) => it.id == widget.itinerary.id,
      orElse: () => widget.itinerary,
    );

    // Atualizar a UI
    setState(() {
      _loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itinerary.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar itinerário',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ItineraryFormScreen(
                    itinerary: widget.itinerary,
                  ),
                ),
              ).then((_) => _refreshItinerary());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Cabeçalho com datas e informações
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.itinerary.description != null && 
                    widget.itinerary.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      widget.itinerary.description!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                Row(
                  children: [
                    const Icon(Icons.date_range, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _formatDateRange(widget.itinerary),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.itinerary.days.length} ${widget.itinerary.days.length == 1 ? 'dia' : 'dias'} planejados',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Calendário
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              // Se clicar em um dia que já tem eventos, exibe os destinos
              final events = _getEventsForDay(selectedDay);
              if (events.isNotEmpty) {
                final tripDay = events.first;
                if (tripDay.destinationIds.isNotEmpty) {
                  _openDayEdit(context, tripDay);
                } else {
                  _openDayEdit(context, tripDay);
                }
              } else {
                // Se clicar em um dia sem eventos, pergunta se quer adicionar destinos para esse dia
                _askToAddDestinations(selectedDay);
              }
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              markerDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (!_hasEventForDay(day)) {
                  return null;
                }

                return Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.shade400,
                    ),
                    width: 8,
                    height: 8,
                  ),
                );
              },
            ),
          ),

          const Divider(),

          // Lista de destinos para o dia selecionado
          Expanded(
            child: _buildSelectedDayContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedDay != null) {
            final existingEvents = _getEventsForDay(_selectedDay!);
            if (existingEvents.isNotEmpty) {
              _openDayEdit(context, existingEvents.first);
            } else {
              _openDayEdit(context, TripDay(date: _selectedDay!));
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Selecione um dia primeiro')),
            );
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Adicionar destinos a este dia',
      ),
    );
  }

  // Formatar período do itinerário
  String _formatDateRange(Itinerary itinerary) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    if (itinerary.startDate != null && itinerary.endDate != null) {
      return '${dateFormat.format(itinerary.startDate!)} - ${dateFormat.format(itinerary.endDate!)}';
    } else if (itinerary.startDate != null) {
      return 'A partir de ${dateFormat.format(itinerary.startDate!)}';
    } else if (itinerary.endDate != null) {
      return 'Até ${dateFormat.format(itinerary.endDate!)}';
    } else {
      return 'Datas não definidas';
    }
  }

  // Exibir conteúdo para o dia selecionado
  Widget _buildSelectedDayContent() {
    if (_selectedDay == null) {
      return const Center(
        child: Text('Selecione um dia no calendário para ver os destinos planejados'),
      );
    }

    final eventsForDay = _getEventsForDay(_selectedDay!);
    if (eventsForDay.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Nenhum destino planejado para este dia.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _openDayEdit(context, TripDay(date: _selectedDay!)),
              child: const Text('Adicionar destinos'),
            ),
          ],
        ),
      );
    }

    final tripDay = eventsForDay.first;
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'pt_BR');
    final formattedDate = dateFormat.format(_selectedDay!);
    
    return Consumer<DestinationProvider>(
      builder: (context, destinationProvider, child) {
        // Corrigido: Agora usando firstWhereOrNull para lidar corretamente com destinos não encontrados
        final destinations = tripDay.destinationIds
            .map((id) {
              try {
                return destinationProvider.destinations
                    .firstWhere((d) => d.id == id);
              } catch (e) {
                // Se o destino não for encontrado, retorna null
                return null;
              }
            })
            .where((d) => d != null)
            .cast<Destination>() // Convertendo para Lista<Destination> após filtrar os nulls
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título do dia
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _openDayEdit(context, tripDay),
                    tooltip: 'Editar este dia',
                  ),
                ],
              ),
            ),

            // Notas do dia
            if (tripDay.notes != null && tripDay.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  color: Colors.yellow[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.note, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(tripDay.notes!)),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            if (destinations.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('Nenhum destino planejado para este dia')),
              ),

            // Lista de destinos do dia
            Expanded(
              child: ListView.builder(
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  final destination = destinations[index];
                  if (destination == null) return const SizedBox.shrink();
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(destination.name),
                      subtitle: Text(destination.category),
                      trailing: Icon(
                        destination.isVisited ? Icons.check_circle : Icons.place,
                        color: destination.isVisited ? Colors.green : Colors.red,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DestinationDetailScreen(
                              destination: destination,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Perguntar se o usuário quer adicionar destinos para um dia
  void _askToAddDestinations(DateTime day) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Planejar dia ${DateFormat('dd/MM/yyyy').format(day)}'),
        content: const Text('Deseja adicionar destinos para este dia?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openDayEdit(context, TripDay(date: day));
            },
            child: const Text('Adicionar Destinos'),
          ),
        ],
      ),
    );
  }
}