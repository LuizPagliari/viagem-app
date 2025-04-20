import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/destination_provider.dart';
import '../models/destination_model.dart';
import 'destination_detail_screen.dart';
import 'destination_form_screen.dart';
import 'maps_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Carrega os destinos quando a tela é inicializada
    Future.microtask(
      () => Provider.of<DestinationProvider>(context, listen: false).loadDestinations(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planejamento de Viagem'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MapsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<DestinationProvider>(
        builder: (context, destinationProvider, child) {
          if (destinationProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final destinations = destinationProvider.destinations;

          if (destinations.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum destino adicionado.\nClique no botão + para adicionar um destino.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              final destination = destinations[index];
              return _buildDestinationCard(context, destination);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const DestinationFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDestinationCard(BuildContext context, Destination destination) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          destination.isVisited ? Icons.check_circle : Icons.place,
          color: destination.isVisited ? Colors.green : Colors.red,
        ),
        title: Text(destination.name),
        subtitle: Text(
          destination.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                destination.isVisited ? Icons.unpublished : Icons.check,
                color: destination.isVisited ? Colors.grey : Colors.green,
              ),
              onPressed: () {
                Provider.of<DestinationProvider>(context, listen: false)
                    .toggleVisited(destination.id);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmationDialog(context, destination);
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DestinationDetailScreen(destination: destination),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, Destination destination) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: Text('Deseja realmente excluir o destino ${destination.name}?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Excluir'),
              onPressed: () {
                Provider.of<DestinationProvider>(context, listen: false)
                    .removeDestination(destination.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}