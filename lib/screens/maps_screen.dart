import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/destination_provider.dart';
import '../models/destination_model.dart';
import '../components/map_component.dart';
import 'destination_detail_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    await Provider.of<DestinationProvider>(context, listen: false).loadDestinations();
    _setMarkers();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _setMarkers();
  }

  void _setMarkers() {
    if (!mounted) return;
    
    final destinations = Provider.of<DestinationProvider>(context, listen: false).destinations;
    setState(() {
      _markers = destinations.map((destination) {
        return Marker(
          markerId: MarkerId(destination.id),
          position: LatLng(destination.latitude, destination.longitude),
          infoWindow: InfoWindow(
            title: destination.name,
            snippet: destination.description,
            onTap: () => _openDestinationDetail(destination),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            destination.isVisited ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
        );
      }).toSet();
    });
  }

  void _openDestinationDetail(Destination destination) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DestinationDetailScreen(destination: destination),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Destinos'),
      ),
      body: Consumer<DestinationProvider>(
        builder: (context, destinationProvider, child) {
          final destinations = destinationProvider.destinations;

          // Define a posição inicial do mapa
          final initialPosition = destinations.isNotEmpty
              ? LatLng(destinations.first.latitude, destinations.first.longitude)
              : const LatLng(-15.7801, -47.9292); // Brasil (Brasília) como padrão

          if (destinationProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (destinations.isEmpty) {
            return const Center(
              child: Text('Adicione destinos para visualizá-los no mapa.'),
            );
          }

          return MapComponent(
            initialPosition: initialPosition,
            initialZoom: 5,
            markers: _markers,
            onMapCreated: _onMapCreated,
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          );
        },
      ),
      floatingActionButton: kIsWeb 
          ? null // No web, não mostramos o botão
          : FloatingActionButton(
              onPressed: () {
                if (_mapController != null && _markers.isNotEmpty) {
                  final bounds = _calculateBounds();
                  _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
                }
              },
              child: const Icon(Icons.center_focus_strong),
            ),
    );
  }

  LatLngBounds _calculateBounds() {
    final destinations = Provider.of<DestinationProvider>(context, listen: false).destinations;
    
    // Se não houver destinos, retorne um limite padrão para o Brasil
    if (destinations.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(-33.7683, -73.9910),
        northeast: const LatLng(5.2719, -34.7299),
      );
    }

    double minLat = destinations.first.latitude;
    double maxLat = destinations.first.latitude;
    double minLng = destinations.first.longitude;
    double maxLng = destinations.first.longitude;

    for (final destination in destinations) {
      if (destination.latitude < minLat) minLat = destination.latitude;
      if (destination.latitude > maxLat) maxLat = destination.latitude;
      if (destination.longitude < minLng) minLng = destination.longitude;
      if (destination.longitude > maxLng) maxLng = destination.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}