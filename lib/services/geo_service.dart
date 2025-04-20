import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class GeoService {
  /// Converte um endereço em coordenadas de latitude e longitude
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    if (address.trim().isEmpty) return null;
    
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
      return null;
    } catch (e) {
      print('Erro ao converter endereço para coordenadas: $e');
      return null;
    }
  }

  /// Converte coordenadas de latitude e longitude em um endereço
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return _formatAddress(place);
      }
      return null;
    } catch (e) {
      print('Erro ao converter coordenadas para endereço: $e');
      return null;
    }
  }

  /// Busca por sugestões de endereços baseado em um termo de busca
  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];
    
    try {
      List<Location> locations = await locationFromAddress(query);
      List<Map<String, dynamic>> results = [];
      
      for (var location in locations) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude, 
          location.longitude
        );
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          String address = _formatAddress(place);
          String name = place.name?.isNotEmpty == true 
              ? place.name! 
              : (place.street?.isNotEmpty == true 
                  ? place.street! 
                  : 'Local sem nome');
          
          results.add({
            'name': name,
            'address': address,
            'latitude': location.latitude,
            'longitude': location.longitude,
          });
        }
      }
      
      return results;
    } catch (e) {
      print('Erro ao buscar locais: $e');
      return [];
    }
  }

  /// Formata um objeto Placemark em uma string de endereço legível
  String _formatAddress(Placemark place) {
    List<String> addressParts = [
      place.street ?? '',
      place.subLocality ?? '',
      place.locality ?? '',
      place.administrativeArea ?? '',
      place.postalCode ?? '',
      place.country ?? '',
    ];

    // Remove partes vazias e junta com vírgula
    return addressParts
        .where((part) => part.isNotEmpty)
        .join(', ');
  }
}