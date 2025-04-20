import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/destination_provider.dart';
import '../components/map_component.dart';
import '../services/geo_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DestinationFormScreen extends StatefulWidget {
  const DestinationFormScreen({super.key});

  @override
  State<DestinationFormScreen> createState() => _DestinationFormScreenState();
}

class _DestinationFormScreenState extends State<DestinationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  final GeoService _geoService = GeoService();
  
  // Lista de categorias disponíveis
  final List<String> _categories = [
    'Praia', 
    'Montanha', 
    'Cidade', 
    'Museu', 
    'Parque', 
    'Restaurante', 
    'Hotel', 
    'Monumento',
    'Outros'
  ];
  
  String _selectedCategory = 'Outros';

  // Iniciar com visão mundial (zoom menor)
  double _latitude = 0.0; // Centro do mapa (equador)
  double _longitude = 0.0; // Centro do mapa (meridiano de Greenwich)

  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  bool _isMapReady = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  String? _selectedAddress;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      _isMapReady = true;
    });
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;

      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          infoWindow: const InfoWindow(title: 'Local selecionado'),
        ),
      };

      // Tenta obter o endereço a partir das coordenadas
      _getAddressFromCoordinates();
    });
  }

  Future<void> _getAddressFromCoordinates() async {
    final address = await _geoService.getAddressFromCoordinates(_latitude, _longitude);
    if (address != null && mounted) {
      setState(() {
        _selectedAddress = address;

        // Se o nome do destino estiver vazio, usar parte do endereço como sugestão
        if (_nameController.text.isEmpty && address.isNotEmpty) {
          List<String> parts = address.split(',');
          if (parts.isNotEmpty) {
            _nameController.text = parts.first.trim();
          }
        }
      });
    }
  }

  // Para web, temos uma versão simplificada
  void _onWebMapTap() {
    if (kIsWeb) {
      // No modo web, abrimos um diálogo para pesquisar locais ou digitar coordenadas
      _showLocationSearchDialog();
    }
  }

  void _showLocationSearchDialog() {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Encontrar local'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do local ou endereço',
                    hintText: 'Ex: Praia de Copacabana, Rio de Janeiro',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (value) async {
                    if (value.isNotEmpty) {
                      setStateDialog(() => _isSearching = true);
                      final coords = await _geoService.getCoordinatesFromAddress(value);
                      if (coords != null && mounted) {
                        setState(() {
                          _latitude = coords.latitude;
                          _longitude = coords.longitude;
                          _markers = {
                            Marker(
                              markerId: const MarkerId('selected_location'),
                              position: coords,
                            )
                          };
                        });
                        _getAddressFromCoordinates();
                        Navigator.of(ctx).pop();
                      } else {
                        setStateDialog(() => _isSearching = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Local não encontrado')),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('OU insira as coordenadas manualmente:'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Latitude'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        controller: TextEditingController(text: _latitude.toString()),
                        onChanged: (value) {
                          try {
                            _latitude = double.parse(value);
                          } catch (_) {}
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Longitude'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        controller: TextEditingController(text: _longitude.toString()),
                        onChanged: (value) {
                          try {
                            _longitude = double.parse(value);
                          } catch (_) {}
                        },
                      ),
                    ),
                  ],
                ),
                if (_isSearching)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    child: const CircularProgressIndicator(),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _markers = {
                      Marker(
                        markerId: const MarkerId('selected_location'),
                        position: LatLng(_latitude, _longitude),
                        infoWindow: const InfoWindow(title: 'Local selecionado'),
                      ),
                    };
                  });
                  _getAddressFromCoordinates();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Confirmar'),
              ),
            ],
          );
        }
      ),
    );
  }

  // Busca lugares baseado no texto digitado
  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _geoService.searchPlaces(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  // Seleciona um lugar da lista de resultados
  void _selectPlace(Map<String, dynamic> place) {
    final lat = place['latitude'] as double;
    final lng = place['longitude'] as double;
    final address = place['address'] as String;

    setState(() {
      _latitude = lat;
      _longitude = lng;
      _selectedAddress = address;
      _searchResults = [];
      _searchController.text = '';

      // Adiciona um marcador no mapa
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: place['name'], snippet: address),
        ),
      };

      // Se o nome do destino estiver vazio, usa o nome do local como sugestão
      if (_nameController.text.isEmpty) {
        _nameController.text = place['name'];
      }
    });

    // Centraliza o mapa na localização selecionada
    if (_mapController != null && !kIsWeb) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15),
      );
    }
  }

  void _saveDestination() {
    if (_formKey.currentState!.validate() && (_markers.isNotEmpty || kIsWeb)) {
      Provider.of<DestinationProvider>(context, listen: false).addDestination(
        name: _nameController.text,
        description: _descriptionController.text,
        latitude: _latitude,
        longitude: _longitude,
        category: _selectedCategory, // Adicionada a categoria
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Destino adicionado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } else if (_markers.isEmpty && !kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma localização no mapa'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Destino'),
      ),
      body: Column(
        children: [
          // Informações do destino em um painel expansível
          ExpansionTile(
            title: const Text('Informações do Destino'),
            initiallyExpanded: true,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do destino',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite o nome do destino';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite uma descrição';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Dropdown para selecionar categoria
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedCategory,
                        items: _categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Barra de pesquisa acima do mapa
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                if (!kIsWeb) // Campo de busca não exibido na web
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Buscar lugar',
                          hintText: 'Digite um endereço ou ponto de interesse',
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchResults = [];
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          _searchPlaces(value);
                        },
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _searchResults.isEmpty ? 0 : 200,
                        child: _isSearching
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final place = _searchResults[index];
                                  return ListTile(
                                    title: Text(place['name']),
                                    subtitle: Text(
                                      place['address'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () => _selectPlace(place),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                Text(
                  kIsWeb
                      ? 'Clique no mapa para buscar um local:'
                      : 'Navegue e toque no mapa para selecionar um local:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Mapa ocupando o espaço restante da tela
          Expanded(
            child: GestureDetector(
              onTap: kIsWeb ? _onWebMapTap : null,
              child: MapComponent(
                initialPosition: LatLng(_latitude, _longitude),
                initialZoom: 2, // Zoom menor para mostrar mais do mundo
                markers: _markers,
                onMapCreated: _onMapCreated,
                onTap: _onMapTap,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                mapType: MapType.normal,
              ),
            ),
          ),

          // Painel de informações do local selecionado
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exibe o endereço selecionado, se houver
                if (_selectedAddress != null && _selectedAddress!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Endereço: $_selectedAddress',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                Text(
                  'Coordenadas selecionadas:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _markers.isEmpty && !kIsWeb ? Colors.red : Colors.black,
                  ),
                ),
                Text(
                  _markers.isEmpty && !kIsWeb
                      ? 'Nenhuma localização selecionada'
                      : 'Latitude: $_latitude, Longitude: $_longitude',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveDestination,
                    child: const Text('Salvar Destino'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}