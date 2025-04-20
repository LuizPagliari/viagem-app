import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/itinerary_provider.dart';
import '../models/itinerary_model.dart';

class ItineraryFormScreen extends StatefulWidget {
  final Itinerary? itinerary;

  const ItineraryFormScreen({super.key, this.itinerary});

  @override
  State<ItineraryFormScreen> createState() => _ItineraryFormScreenState();
}

class _ItineraryFormScreenState extends State<ItineraryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    
    // Se estiver editando um itinerário existente, preenche os campos
    if (widget.itinerary != null) {
      _nameController.text = widget.itinerary!.name;
      _descriptionController.text = widget.itinerary!.description ?? '';
      _startDate = widget.itinerary!.startDate;
      _endDate = widget.itinerary!.endDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Exibir seletor de data
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _startDate ?? DateTime.now()
          : _endDate ?? (_startDate?.add(const Duration(days: 1)) ?? DateTime.now().add(const Duration(days: 1))),
      firstDate: isStartDate
          ? DateTime.now().subtract(const Duration(days: 365))
          : _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1825)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Se a data final for anterior à nova data inicial, redefine-a
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate!.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Salvar itinerário
  void _saveItinerary() {
    if (_formKey.currentState!.validate()) {
      final itineraryProvider = Provider.of<ItineraryProvider>(context, listen: false);
      
      if (widget.itinerary == null) {
        // Criar novo itinerário
        itineraryProvider.createItinerary(
          name: _nameController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          startDate: _startDate,
          endDate: _endDate,
        );
      } else {
        // Atualizar itinerário existente
        final updatedItinerary = Itinerary(
          id: widget.itinerary!.id,
          name: _nameController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          startDate: _startDate,
          endDate: _endDate,
          days: widget.itinerary!.days,
        );
        itineraryProvider.updateItinerary(updatedItinerary);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.itinerary == null
              ? 'Itinerário criado com sucesso!'
              : 'Itinerário atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itinerary == null ? 'Novo Itinerário' : 'Editar Itinerário'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome do itinerário
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Itinerário',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.bookmark),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe um nome para o itinerário';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Descrição do itinerário
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                
                const SizedBox(height: 24),
                
                // Seleção de datas
                Text(
                  'Período da viagem',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Data de início
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Data de início'),
                  subtitle: Text(_startDate != null
                      ? dateFormat.format(_startDate!)
                      : 'Clique para selecionar'),
                  onTap: () => _selectDate(context, true),
                  tileColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Data de término
                ListTile(
                  leading: const Icon(Icons.event), // Corrigido para um ícone válido
                  title: const Text('Data de término'),
                  subtitle: Text(_endDate != null
                      ? dateFormat.format(_endDate!)
                      : 'Clique para selecionar'),
                  onTap: () => _selectDate(context, false),
                  tileColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabled: _startDate != null,
                ),
                
                const SizedBox(height: 32),
                
                // Botão de salvar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveItinerary,
                    child: Text(
                      widget.itinerary == null ? 'Criar Itinerário' : 'Salvar Alterações',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}