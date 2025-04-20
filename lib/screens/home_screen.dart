import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/destination_provider.dart';
import '../models/destination_model.dart';
import 'destination_detail_screen.dart';
import 'destination_form_screen.dart';
import 'maps_screen.dart';
import 'itineraries_screen.dart'; // Importando a tela de itinerários
import 'itinerary_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Todos';
  int _currentIndex = 0; // Para controle da navegação por abas
  
  // Lista de todas as categorias possíveis
  final List<String> _allCategories = [
    'Todos',
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
        title: Text(_currentIndex == 0 ? 'Destinos' : 'Itinerários de Viagem'),
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
      body: _currentIndex == 0 ? _buildDestinationsView() : const ItinerariesScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.place),
            label: 'Destinos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Itinerários',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentIndex == 0) {
            // Adicionar destino
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const DestinationFormScreen(),
              ),
            );
          } else {
            // Adicionar itinerário
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ItineraryFormScreen(),
              ),
            );
          }
        },
        tooltip: _currentIndex == 0 ? 'Adicionar destino' : 'Adicionar itinerário',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Extraímos a visualização de destinos para um método separado
  Widget _buildDestinationsView() {
    return Column(
      children: [
        // Filtro por categoria
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtrar por categoria:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _allCategories.length,
                  itemBuilder: (context, index) {
                    final category = _allCategories[index];
                    final isSelected = category == _selectedCategory;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
                        checkmarkColor: Theme.of(context).primaryColor,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Lista de destinos
        Expanded(
          child: Consumer<DestinationProvider>(
            builder: (context, destinationProvider, child) {
              if (destinationProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              // Filtramos os destinos pela categoria selecionada
              final destinations = _selectedCategory == 'Todos'
                  ? destinationProvider.destinations
                  : destinationProvider.getDestinationsByCategory(_selectedCategory);

              if (destinationProvider.destinations.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum destino adicionado.\nClique no botão + para adicionar um destino.',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (destinations.isEmpty) {
                return Center(
                  child: Text(
                    'Nenhum destino na categoria "$_selectedCategory".\nSelecione outra categoria ou adicione novos destinos.',
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
        ),
      ],
    );
  }

  Widget _buildDestinationCard(BuildContext context, Destination destination) {
    // Selecionar um ícone baseado na categoria
    IconData categoryIcon;
    switch (destination.category) {
      case 'Praia':
        categoryIcon = Icons.beach_access;
        break;
      case 'Montanha':
        categoryIcon = Icons.landscape;
        break;
      case 'Cidade':
        categoryIcon = Icons.location_city;
        break;
      case 'Museu':
        categoryIcon = Icons.museum;
        break;
      case 'Parque':
        categoryIcon = Icons.park;
        break;
      case 'Restaurante':
        categoryIcon = Icons.restaurant;
        break;
      case 'Hotel':
        categoryIcon = Icons.hotel;
        break;
      case 'Monumento':
        categoryIcon = Icons.account_balance;
        break;
      default:
        categoryIcon = Icons.place;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: destination.isVisited
            ? BorderSide(color: Colors.green.shade300, width: 1)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: destination.isVisited ? Colors.green.shade100 : Colors.blue.shade100,
          child: Icon(
            categoryIcon,
            color: destination.isVisited ? Colors.green : Colors.blue,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                destination.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                destination.category,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              destination.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            destination.isVisited
                ? const Text(
                    'Visitado',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  )
                : const Text(
                    'Não visitado',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
          ],
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