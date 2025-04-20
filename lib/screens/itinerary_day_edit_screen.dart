import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/itinerary_model.dart';
import '../models/trip_day_model.dart';
import '../models/destination_model.dart';
import '../providers/destination_provider.dart';
import '../providers/itinerary_provider.dart';

class ItineraryDayEditScreen extends StatefulWidget {
  final Itinerary itinerary;
  final TripDay tripDay;

  const ItineraryDayEditScreen({
    super.key,
    required this.itinerary,
    required this.tripDay,
  });

  @override
  State<ItineraryDayEditScreen> createState() => _ItineraryDayEditScreenState();
}

class _ItineraryDayEditScreenState extends State<ItineraryDayEditScreen> {
  final _notesController = TextEditingController();
  final Set<String> _selectedDestinationIds = {};
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar com as notas existentes, se houver
    _notesController.text = widget.tripDay.notes ?? '';
    
    // Inicializar os destinos selecionados
    _selectedDestinationIds.addAll(widget.tripDay.destinationIds);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Salvar as alterações
  Future<void> _saveDay() async {
    final itineraryProvider = Provider.of<ItineraryProvider>(context, listen: false);
    
    // Criar ou atualizar o TripDay
    final updatedDay = TripDay(
      id: widget.tripDay.id,
      date: widget.tripDay.date,
      destinationIds: _selectedDestinationIds.toList(),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );
    
    // Atualizar o itinerário
    final updatedItinerary = Itinerary(
      id: widget.itinerary.id,
      name: widget.itinerary.name,
      description: widget.itinerary.description,
      startDate: widget.itinerary.startDate,
      endDate: widget.itinerary.endDate,
      days: [...widget.itinerary.days.where((day) => day.id != updatedDay.id), updatedDay],
    );
    
    await itineraryProvider.updateItinerary(updatedItinerary);
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // Exibir diálogo para confirmar a exclusão do dia
  Future<void> _confirmDeleteDay() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja excluir o planejamento para o dia ${DateFormat('dd/MM/yyyy').format(widget.tripDay.date)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Se o usuário confirmou, remover o dia do itinerário
      final updatedItinerary = Itinerary(
        id: widget.itinerary.id,
        name: widget.itinerary.name,
        description: widget.itinerary.description,
        startDate: widget.itinerary.startDate,
        endDate: widget.itinerary.endDate,
        days: widget.itinerary.days.where((day) => day.id != widget.tripDay.id).toList(),
      );
      
      await Provider.of<ItineraryProvider>(context, listen: false)
          .updateItinerary(updatedItinerary);
          
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'pt_BR');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Planejamento para ${DateFormat('dd/MM').format(widget.tripDay.date)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDeleteDay,
            tooltip: 'Excluir dia',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com a data
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(widget.tripDay.date),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.itinerary.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Campo para notas
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notas para este dia:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: 'Adicione notas sobre este dia (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),

          // Lista de destinos disponíveis
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Selecione os destinos para este dia:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          
          Expanded(
            child: Consumer<DestinationProvider>(
              builder: (context, destinationProvider, child) {
                final destinations = destinationProvider.destinations;
                
                if (destinations.isEmpty) {
                  return const Center(
                    child: Text('Nenhum destino cadastrado'),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: destinations.length,
                  itemBuilder: (context, index) {
                    final destination = destinations[index];
                    final isSelected = _selectedDestinationIds.contains(destination.id);
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8, 
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected 
                              ? Theme.of(context).primaryColor 
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected 
                              ? Theme.of(context).primaryColor.withOpacity(0.2)
                              : Colors.grey.shade200,
                          child: isSelected 
                              ? const Icon(Icons.check, color: Colors.blue)
                              : Text('${index + 1}'),
                        ),
                        title: Text(
                          destination.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(destination.category),
                        trailing: Icon(
                          isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedDestinationIds.remove(destination.id);
                            } else {
                              _selectedDestinationIds.add(destination.id);
                            }
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedDestinationIds.length} destinos selecionados',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: _saveDay,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24, 
                    vertical: 12,
                  ),
                ),
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}