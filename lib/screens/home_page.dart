import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart'; // Importe o CustomDrawer atualizado
import 'package:front_projeto_flutter/screens/inoperatives/inoperative.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:front_projeto_flutter/components/custom_drawer.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MapController _mapController = MapController();
  
  List<MaintenanceData> _maintenances = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMaintenances();
  }

  Future<void> _loadMaintenances() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await http.get(
        Uri.parse('http://localhost:4040/api/maintenence/?status=pendente'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> maintenancesJson = data['manutencoes'];
        
        setState(() {
          _maintenances = maintenancesJson
              .map((json) => MaintenanceData.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Erro ao carregar manutenções: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro de conexão: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(useCustomIcons: false),
      body: Stack(
        children: [
          // Mapa como background
          _buildMap(),
          
          // Header com botões
          _buildHeader(),
          
          // Cards inferiores
          _buildBottomCards(),
          
          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: _maintenances.isNotEmpty 
            ? LatLng(_maintenances.first.latitude, _maintenances.first.longitude)
            : const LatLng(-24.6181640639423, -53.70934113100743), // Coordenada padrão
        zoom: 13.0,
        minZoom: 5.0,
        maxZoom: 18.0,
        interactiveFlags: InteractiveFlag.all,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'com.example.app',
        ),
        MarkerLayer(
          markers: _maintenances.map((maintenance) => 
            Marker(
              point: LatLng(maintenance.latitude, maintenance.longitude),
              width: 80,
              height: 80,
              builder: (context) => GestureDetector(
                onTap: () => _showMaintenanceDetails(maintenance),
                child: Container(
                  decoration: BoxDecoration(
                    color: _getUrgencyColor(maintenance.urgencia),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.build,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Botão menu
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
            
            // Botões de ação do mapa
            Row(
              children: [
                // Botão refresh
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.black),
                    onPressed: _loadMaintenances,
                  ),
                ),
                
                // Botão notificações
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.black),
                        onPressed: () {},
                      ),
                    ),
                    if (_maintenances.isNotEmpty)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${_maintenances.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCards() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: const [
                _PlacaCard(titulo: "Aprovar solicitação"),
                SizedBox(height: 12),
                _PlacaCard(titulo: "Visualizar manutenção do veículo"),
                SizedBox(height: 12),
                _PlacaCard(titulo: "Deslocamento de veículo"),
                SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Color _getUrgencyColor(String urgencia) {
    switch (urgencia.toLowerCase()) {
      case 'alta':
        return Colors.red;
      case 'media':
      case 'média':
        return Colors.orange;
      case 'baixa':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  void _showMaintenanceDetails(MaintenanceData maintenance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Título
              Row(
                children: [
                  Icon(
                    Icons.build,
                    color: _getUrgencyColor(maintenance.urgencia),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Detalhes da Manutenção',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Informações
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Veículo', '${maintenance.veiculo.marca} ${maintenance.veiculo.modelo}'),
                      _buildDetailRow('Placa', maintenance.veiculo.placa),
                      _buildDetailRow('Problema', maintenance.descricaoProblema),
                      _buildDetailRow('Urgência', maintenance.urgencia.toUpperCase()),
                      _buildDetailRow('Status', maintenance.status.toUpperCase()),
                      _buildDetailRow('Supervisor', maintenance.supervisor.nome),
                      _buildDetailRow('Email', maintenance.supervisor.email),
                      _buildDetailRow('Empresa', maintenance.veiculo.empresa),
                      _buildDetailRow('Departamento', maintenance.veiculo.departamento),
                      _buildDetailRow('Data Solicitação', _formatDate(maintenance.dataSolicitacao)),
                    ],
                  ),
                ),
              ),
              
              // Botões de ação
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Implementar aprovação
                      },
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Aprovar', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Implementar reprovação
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text('Reprovar', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}

// Classe para representar os dados de manutenção
class MaintenanceData {
  final int id;
  final int veiculoId;
  final String descricaoProblema;
  final double latitude;
  final double longitude;
  final String urgencia;
  final String status;
  final String dataSolicitacao;
  final Vehicle veiculo;
  final Supervisor supervisor;

  MaintenanceData({
    required this.id,
    required this.veiculoId,
    required this.descricaoProblema,
    required this.latitude,
    required this.longitude,
    required this.urgencia,
    required this.status,
    required this.dataSolicitacao,
    required this.veiculo,
    required this.supervisor,
  });

  factory MaintenanceData.fromJson(Map<String, dynamic> json) {
    return MaintenanceData(
      id: json['id'],
      veiculoId: json['veiculoId'],
      descricaoProblema: json['descricaoProblema'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      urgencia: json['urgencia'],
      status: json['status'],
      dataSolicitacao: json['dataSolicitacao'],
      veiculo: Vehicle.fromJson(json['veiculo']),
      supervisor: Supervisor.fromJson(json['supervisor']),
    );
  }
}

class Vehicle {
  final int id;
  final String placa;
  final String marca;
  final String modelo;
  final String empresa;
  final String departamento;

  Vehicle({
    required this.id,
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.empresa,
    required this.departamento,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      placa: json['placa'],
      marca: json['marca'],
      modelo: json['modelo'],
      empresa: json['empresa'],
      departamento: json['departamento'],
    );
  }
}

class Supervisor {
  final int id;
  final String nome;
  final String email;

  Supervisor({
    required this.id,
    required this.nome,
    required this.email,
  });

  factory Supervisor.fromJson(Map<String, dynamic> json) {
    return Supervisor(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
    );
  }
}

// Widget do card de placa (mantido igual)
class _PlacaCard extends StatelessWidget {
  final String titulo;

  const _PlacaCard({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Digite a placa do veículo',
                filled: true,
                fillColor: Color(0xFFF1F1F1),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}