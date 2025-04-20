import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/itinerary_provider.dart';
import '../models/itinerary_model.dart';
import 'itinerary_form_screen.dart';
import 'itinerary_detail_screen.dart';
import 'package:intl/intl.dart';

class ItinerariesScreen extends StatefulWidget {
  const ItinerariesScreen({super.key});

  @override
  State<ItinerariesScreen> createState() => _ItinerariesScreenState();
}

class _ItinerariesScreenState extends State<ItinerariesScreen> {
  @override
  void initState() {
    super.initState();
    // Carrega os itinerários ao iniciar
    Future.microtask(
      () => Provider.of<ItineraryProvider>(context, listen: false).loadItineraries(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ItineraryProvider>(
      builder: (context, itineraryProvider, child) {
        if (itineraryProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final itineraries = itineraryProvider.itineraries;

        if (itineraries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Nenhum itinerário criado.\nCrie um novo roteiro de viagem.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Criar Itinerário'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ItineraryFormScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: itineraries.length,
          itemBuilder: (context, index) {
            final itinerary = itineraries[index];
            return _buildItineraryCard(context, itinerary);
          },
        );
      },
    );
  }

  Widget _buildItineraryCard(BuildContext context, Itinerary itinerary) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    final String dateRange = itinerary.startDate != null && itinerary.endDate != null
        ? '${dateFormat.format(itinerary.startDate!)} - ${dateFormat.format(itinerary.endDate!)}'
        : 'Datas não definidas';
        
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
          radius: 30,
          child: const Icon(Icons.map),
        ),
        title: Text(
          itinerary.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              itinerary.description ?? 'Sem descrição',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  dateRange,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.place, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  '${itinerary.days.fold<int>(0, (sum, day) => sum + day.destinationIds.length)} destinos',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ItineraryFormScreen(itinerary: itinerary),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDeleteItinerary(context, itinerary),
            ),
          ],
        ),
        onTap: () {
          // Selecionar o itinerário atual e navegar para os detalhes
          Provider.of<ItineraryProvider>(context, listen: false)
              .setCurrentItinerary(itinerary.id);
              
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ItineraryDetailScreen(itinerary: itinerary),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteItinerary(BuildContext context, Itinerary itinerary) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Excluir ${itinerary.name}?'),
          content: const Text('Esta ação não pode ser desfeita. Todos os dias e planejamentos deste itinerário serão excluídos.'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Provider.of<ItineraryProvider>(context, listen: false)
                    .deleteItinerary(itinerary.id);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}