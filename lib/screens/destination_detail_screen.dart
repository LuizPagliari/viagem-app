import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/destination_model.dart';
import '../providers/destination_provider.dart';
import '../components/map_component.dart';

class DestinationDetailScreen extends StatelessWidget {
  final Destination destination;

  const DestinationDetailScreen({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(destination.name),
        actions: [
          IconButton(
            icon: Icon(
              destination.isVisited ? Icons.unpublished : Icons.check,
              color: destination.isVisited ? Colors.grey : Colors.green,
            ),
            onPressed: () {
              Provider.of<DestinationProvider>(context, listen: false)
                  .toggleVisited(destination.id);
              Navigator.of(context).pop();
            },
            tooltip: destination.isVisited ? 'Marcar como não visitado' : 'Marcar como visitado',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              _showDeleteConfirmationDialog(context);
            },
            tooltip: 'Excluir destino',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: MapComponent(
                initialPosition: LatLng(destination.latitude, destination.longitude),
                initialZoom: 13,
                markers: {
                  Marker(
                    markerId: MarkerId(destination.id),
                    position: LatLng(destination.latitude, destination.longitude),
                    infoWindow: InfoWindow(title: destination.name),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      destination.isVisited
                          ? BitmapDescriptor.hueGreen
                          : BitmapDescriptor.hueRed,
                    ),
                  ),
                },
                liteModeEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        destination.isVisited ? Icons.check_circle : Icons.place,
                        color: destination.isVisited ? Colors.green : Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        destination.isVisited ? 'Visitado' : 'Não visitado',
                        style: TextStyle(
                          color: destination.isVisited ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Descrição:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    destination.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Coordenadas:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Latitude: ${destination.latitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Longitude: ${destination.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
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
                Navigator.of(context).pop(); // Fecha o diálogo
                Navigator.of(context).pop(); // Volta para a tela anterior
              },
            ),
          ],
        );
      },
    );
  }
}