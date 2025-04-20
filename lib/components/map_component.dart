import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class MapComponent extends StatelessWidget {
  final Set<Marker> markers;
  final LatLng initialPosition;
  final double initialZoom;
  final void Function(GoogleMapController)? onMapCreated;
  final void Function(LatLng)? onTap;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final bool liteModeEnabled;
  final MapType mapType;

  const MapComponent({
    super.key,
    required this.markers,
    required this.initialPosition,
    this.initialZoom = 13.0,
    this.onMapCreated,
    this.onTap,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = true,
    this.liteModeEnabled = false,
    this.mapType = MapType.normal,
  });

  @override
  Widget build(BuildContext context) {
    // Se estivermos na web, exibir um placeholder em vez do GoogleMap
    if (kIsWeb) {
      return _buildWebPlaceholder(context);
    }
    
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: initialZoom,
          ),
          markers: markers,
          onMapCreated: onMapCreated,
          onTap: onTap,
          myLocationEnabled: myLocationEnabled,
          myLocationButtonEnabled: myLocationButtonEnabled,
          zoomControlsEnabled: zoomControlsEnabled,
          liteModeEnabled: liteModeEnabled,
          mapType: mapType,
          compassEnabled: true,
          rotateGesturesEnabled: true,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          tiltGesturesEnabled: true,
          mapToolbarEnabled: true,
        ),
        if (markers.isEmpty) 
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Container(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Toque no mapa para marcar um destino',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWebPlaceholder(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          // Se for clicado no modo web, simula um toque no centro
          onTap!(initialPosition);
        }
      },
      child: Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map,
                size: 64,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                markers.isEmpty
                    ? 'Toque aqui para selecionar uma localização'
                    : 'Localização selecionada',
                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
              ),
              if (markers.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Lat: ${initialPosition.latitude.toStringAsFixed(6)}, Lng: ${initialPosition.longitude.toStringAsFixed(6)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}