import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/destination_model.dart';
import '../providers/destination_provider.dart';
import '../components/map_component.dart';

class DestinationDetailScreen extends StatelessWidget {
  final Destination destination;

  const DestinationDetailScreen({super.key, required this.destination});

  // Selecionar um ícone baseado na categoria
  IconData _getCategoryIcon() {
    switch (destination.category) {
      case 'Praia':
        return Icons.beach_access;
      case 'Montanha':
        return Icons.landscape;
      case 'Cidade':
        return Icons.location_city;
      case 'Museu':
        return Icons.museum;
      case 'Parque':
        return Icons.park;
      case 'Restaurante':
        return Icons.restaurant;
      case 'Hotel':
        return Icons.hotel;
      case 'Monumento':
        return Icons.account_balance;
      default:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryIcon = _getCategoryIcon();
    
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
            // Cabeçalho com informações principais
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: destination.isVisited ? Colors.green.shade100 : Colors.blue.shade100,
                    child: Icon(
                      categoryIcon,
                      size: 30,
                      color: destination.isVisited ? Colors.green : Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                destination.category,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              destination.isVisited ? Icons.check_circle : Icons.pending_actions,
                              color: destination.isVisited ? Colors.green : Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              destination.isVisited ? 'Visitado' : 'Não visitado',
                              style: TextStyle(
                                fontSize: 14,
                                color: destination.isVisited ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Mapa
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
            
            // Descrição e informações adicionais
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card para descrição
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.description, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Sobre este destino',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            destination.description,
                            style: const TextStyle(fontSize: 16, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Card para coordenadas
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.location_on, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Localização',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.my_location, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  // Botão para marcar visita
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: destination.isVisited ? Colors.grey : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Provider.of<DestinationProvider>(context, listen: false)
                            .toggleVisited(destination.id);
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        destination.isVisited ? Icons.unpublished : Icons.check_circle,
                      ),
                      label: Text(
                        destination.isVisited ? 'Marcar como não visitado' : 'Marcar como visitado',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
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