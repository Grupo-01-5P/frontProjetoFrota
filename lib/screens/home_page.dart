import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:front_projeto_flutter/screens/maintenences/manutencao_detalhe.dart';
import 'package:front_projeto_flutter/screens/supervisor/maintenences/manutencao_detalhe.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

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
  String _selectedCity = 'Todas';

  // Coordenadas das cidades
  final Map<String, LatLng> _cities = {
    'Todas': const LatLng(-24.6181640639423, -53.70934113100743),
    'Londrina': const LatLng(-23.3045, -51.1696),
    'Curitiba': const LatLng(-25.4244, -49.2654),
    'Toledo': const LatLng(-24.7133, -53.7434),
    'Cuiabá': const LatLng(-15.6014, -56.0979),
  };

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
      
      final _secureStorage = const FlutterSecureStorage();
      final token = await _secureStorage.read(key: 'auth_token');
      
      if (token == null) {
        setState(() {
          _error = 'Token de autenticação não encontrado';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:4040/api/maintenance/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> maintenancesJson = data['manutencoes'];
        print('Manutenções carregadas: ${maintenancesJson.length}');
        
        setState(() {
          _maintenances = maintenancesJson
              .where((json) => json['latitude'] != null && json['longitude'] != null)
              .map((json) => MaintenanceData.fromJson(json))
              .toList();
          _isLoading = false;
        });

        // Centralizar o mapa na primeira manutenção se houver alguma
        if (_maintenances.isNotEmpty) {
          _mapController.move(
            LatLng(_maintenances.first.latitude, _maintenances.first.longitude),
            13.0,
          );
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _error = 'Sessão expirada. Por favor, faça login novamente.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Erro ao carregar manutenções: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar manutenções: $e');
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

          // Filtro de cidades horizontal no topo
          _buildTopCityFilter(),

          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),

          // Error overlay
          if (_error != null) _buildErrorOverlay(),
        ],
      ),
    );
  }

  Widget _buildTopCityFilter() {
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: _cities.keys.map((cityName) {
              final isSelected = _selectedCity == cityName;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCity = cityName;
                    });
                    _moveToCity(cityName);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0C7E3D) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cityName == 'Todas' ? Icons.visibility : Icons.location_on,
                          size: 16,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cityName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _moveToCity(String cityName) {
    final coordinates = _cities[cityName];
    if (coordinates != null) {
      if (cityName == 'Todas') {
        _showAllMaintenances();
      } else {
        _mapController.move(coordinates, 12.0);
        
        // Mostrar snackbar com feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navegando para $cityName'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF0C7E3D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _showAllMaintenances() {
    if (_maintenances.isNotEmpty) {
      // Calcular o centro baseado em todas as manutenções
      double latSum = 0;
      double lngSum = 0;
      
      for (var maintenance in _maintenances) {
        latSum += maintenance.latitude;
        lngSum += maintenance.longitude;
      }
      
      final centerLat = latSum / _maintenances.length;
      final centerLng = lngSum / _maintenances.length;
      
      _mapController.move(LatLng(centerLat, centerLng), 10.0);
    } else {
      // Se não há manutenções, usar coordenada padrão
      _mapController.move(const LatLng(-24.6181640639423, -53.70934113100743), 8.0);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _maintenances.isNotEmpty
              ? 'Visualizando todas as ${_maintenances.length} manutenções'
              : 'Nenhuma manutenção encontrada',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0C7E3D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: _maintenances.isNotEmpty
            ? LatLng(
                _maintenances.first.latitude,
                _maintenances.first.longitude,
              )
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
          markers: _maintenances
              .map(
                (maintenance) => Marker(
                  point: LatLng(
                    maintenance.latitude,
                    maintenance.longitude,
                  ),
                  width: 80,
                  height: 80,
                  builder: (context) => GestureDetector(
                    onTap: () => _showMaintenanceDetails(maintenance),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getStatusColor(maintenance.status),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getStatusIcon(maintenance.status),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
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
                        icon: const Icon(
                          Icons.notifications,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          // Implementar notificações
                        },
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

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0C7E3D),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });
                  _loadMaintenances();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C7E3D),
                ),
                child: const Text(
                  'Tentar Novamente',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Obter cor baseada no status da manutenção
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendente':
        return Colors.orange;
      case 'aprovada':
        return Colors.blue;
      case 'concluída':
        return Colors.green;
      case 'reprovada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Obter ícone baseado no status da manutenção
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pendente':
        return Icons.schedule;
      case 'aprovada':
        return Icons.build;
      case 'concluída':
        return Icons.check_circle;
      case 'reprovada':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  // Obter cor da urgência (para uso secundário se necessário)
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
        height: MediaQuery.of(context).size.height * 0.7,
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

              // Título com status
              Row(
                children: [
                  Icon(
                    _getStatusIcon(maintenance.status),
                    color: _getStatusColor(maintenance.status),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detalhes da Manutenção',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(maintenance.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            maintenance.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(maintenance.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Informações da manutenção
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ID da manutenção
                      _buildDetailRow('ID Manutenção', '#${maintenance.id}'),
                      
                      // Informações do veículo
                      _buildSectionTitle('Veículo'),
                      _buildDetailRow('Placa', maintenance.veiculo.placa),
                      _buildDetailRow(
                        'Veículo',
                        '${maintenance.veiculo.marca} ${maintenance.veiculo.modelo}',
                      ),
                      _buildDetailRow('Tipo', maintenance.veiculo.tipoVeiculo),
                      _buildDetailRow('Empresa', maintenance.veiculo.empresa),
                      _buildDetailRow('Departamento', maintenance.veiculo.departamento),

                      const SizedBox(height: 16),

                      // Informações da manutenção
                      _buildSectionTitle('Manutenção'),
                      _buildDetailRow('Problema', maintenance.descricaoProblema),
                      _buildDetailRow(
                        'Urgência',
                        maintenance.urgencia.toUpperCase(),
                        valueColor: _getUrgencyColor(maintenance.urgencia),
                      ),
                      _buildDetailRow(
                        'Data Solicitação',
                        _formatDate(maintenance.dataSolicitacao),
                      ),
                      if (maintenance.dataAprovacao != null)
                        _buildDetailRow(
                          'Data Aprovação',
                          _formatDate(maintenance.dataAprovacao!),
                        ),
                      if (maintenance.dataEnviarMecanica != null)
                        _buildDetailRow(
                          'Data para Mecânica',
                          _formatDateOnly(maintenance.dataEnviarMecanica!),
                        ),

                      const SizedBox(height: 16),

                      // Fase atual (se houver)
                      if (maintenance.faseAtual != null) ...[
                        _buildSectionTitle('Fase Atual'),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getFaseIcon(maintenance.faseAtual!.tipoFase),
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      maintenance.faseAtual!.descricaoFase,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (maintenance.faseAtual!.emAndamento)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Responsável: ${maintenance.faseAtual!.responsavel.nome}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Início: ${_formatDate(maintenance.faseAtual!.dataInicio)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Informações do supervisor
                      _buildSectionTitle('Supervisor'),
                      _buildDetailRow('Nome', maintenance.supervisor.nome),
                      _buildDetailRow('Email', maintenance.supervisor.email),

                      const SizedBox(height: 16),

                      // Informações da oficina (se houver)
                      if (maintenance.oficina != null) ...[
                        _buildSectionTitle('Oficina'),
                        _buildDetailRow('Nome', maintenance.oficina!.nome),
                        _buildDetailRow('Cidade', '${maintenance.oficina!.cidade} - ${maintenance.oficina!.estado}'),
                        _buildDetailRow('Telefone', maintenance.oficina!.telefone),
                        _buildDetailRow('Email', maintenance.oficina!.email),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Botão para fechar
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C7E3D),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Fechar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final _secureStorage = const FlutterSecureStorage();
                    final function = await _secureStorage.read(key: 'user_function');
                    if (function == "analista"){
                      final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManutencaoDetailScreen(
                          manutencao: {
                            'id': maintenance.id,
                            'veiculoId': maintenance.veiculoId,
                            'descricaoProblema': maintenance.descricaoProblema,
                            'latitude': maintenance.latitude,
                            'longitude': maintenance.longitude,
                            'urgencia': maintenance.urgencia,
                            'status': maintenance.status,
                            'dataSolicitacao': maintenance.dataSolicitacao,
                            'dataAprovacao': maintenance.dataAprovacao,
                            'dataEnviarMecanica': maintenance.dataEnviarMecanica,
                            'veiculo': {
                              'id': maintenance.veiculo.id,
                              'placa': maintenance.veiculo.placa,
                              'marca': maintenance.veiculo.marca,
                              'modelo': maintenance.veiculo.modelo,
                              'empresa': maintenance.veiculo.empresa,
                              'departamento': maintenance.veiculo.departamento,
                              'tipoVeiculo': maintenance.veiculo.tipoVeiculo,
                            },
                            'supervisor': {
                              'id': maintenance.supervisor.id,
                              'nome': maintenance.supervisor.nome,
                              'email': maintenance.supervisor.email,
                            },
                            'faseAtual': maintenance.faseAtual,
                          },
                          oficina: {
                            'id': maintenance.oficina?.id,
                            'nome': maintenance.oficina?.nome,
                            'cidade': maintenance.oficina?.cidade,
                            'estado': maintenance.oficina?.estado,
                            'telefone': maintenance.oficina?.telefone,
                            'email': maintenance.oficina?.email,
                          },
                        ),
                      ),
                    );
                    }else{
                      final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManutencaoDetailScreenSupervisor(
                          manutencao: {
                            'id': maintenance.id,
                            'veiculoId': maintenance.veiculoId,
                            'descricaoProblema': maintenance.descricaoProblema,
                            'latitude': maintenance.latitude,
                            'longitude': maintenance.longitude,
                            'urgencia': maintenance.urgencia,
                            'status': maintenance.status,
                            'dataSolicitacao': maintenance.dataSolicitacao,
                            'dataAprovacao': maintenance.dataAprovacao,
                            'dataEnviarMecanica': maintenance.dataEnviarMecanica,
                            'veiculo': {
                              'id': maintenance.veiculo.id,
                              'placa': maintenance.veiculo.placa,
                              'marca': maintenance.veiculo.marca,
                              'modelo': maintenance.veiculo.modelo,
                              'empresa': maintenance.veiculo.empresa,
                              'departamento': maintenance.veiculo.departamento,
                              'tipoVeiculo': maintenance.veiculo.tipoVeiculo,
                            },
                            'supervisor': {
                              'id': maintenance.supervisor.id,
                              'nome': maintenance.supervisor.nome,
                              'email': maintenance.supervisor.email,
                            },
                            'faseAtual': maintenance.faseAtual,
                          },
                          oficina: {
                            'id': maintenance.oficina?.id,
                            'nome': maintenance.oficina?.nome,
                            'cidade': maintenance.oficina?.cidade,
                            'estado': maintenance.oficina?.estado,
                            'telefone': maintenance.oficina?.telefone,
                            'email': maintenance.oficina?.email,
                          },
                        ),
                      ),
                    );
                    }
                    
                    
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C7E3D),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  
                  child: const Text(
                    'Ir para manutenção',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0C7E3D),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Colors.black87,
                fontWeight: valueColor != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFaseIcon(String tipoFase) {
    switch (tipoFase) {
      case 'INICIAR_VIAGEM':
        return Icons.directions_car;
      case 'DEIXAR_VEICULO':
        return Icons.garage;
      case 'SERVICO_FINALIZADO':
        return Icons.build_circle;
      case 'RETORNO_VEICULO':
        return Icons.keyboard_return;
      case 'VEICULO_ENTREGUE':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateOnly(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
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
  final String? dataAprovacao;
  final String? dataEnviarMecanica;
  final Vehicle veiculo;
  final Supervisor supervisor;
  final Oficina? oficina;
  final FaseAtual? faseAtual;

  MaintenanceData({
    required this.id,
    required this.veiculoId,
    required this.descricaoProblema,
    required this.latitude,
    required this.longitude,
    required this.urgencia,
    required this.status,
    required this.dataSolicitacao,
    this.dataAprovacao,
    this.dataEnviarMecanica,
    required this.veiculo,
    required this.supervisor,
    this.oficina,
    this.faseAtual,
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
      dataAprovacao: json['dataAprovacao'],
      dataEnviarMecanica: json['dataEnviarMecanica'],
      veiculo: Vehicle.fromJson(json['veiculo']),
      supervisor: Supervisor.fromJson(json['supervisor']),
      oficina: json['oficina'] != null ? Oficina.fromJson(json['oficina']) : null,
      faseAtual: json['faseAtual'] != null ? FaseAtual.fromJson(json['faseAtual']) : null,
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
  final String tipoVeiculo;

  Vehicle({
    required this.id,
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.empresa,
    required this.departamento,
    required this.tipoVeiculo,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      placa: json['placa'],
      marca: json['marca'],
      modelo: json['modelo'],
      empresa: json['empresa'],
      departamento: json['departamento'],
      tipoVeiculo: json['tipoVeiculo'],
    );
  }
}

class Supervisor {
  final int id;
  final String nome;
  final String email;

  Supervisor({required this.id, required this.nome, required this.email});

  factory Supervisor.fromJson(Map<String, dynamic> json) {
    return Supervisor(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
    );
  }
}

class Oficina {
  final int id;
  final String nome;
  final String cidade;
  final String estado;
  final String telefone;
  final String email;

  Oficina({
    required this.id,
    required this.nome,
    required this.cidade,
    required this.estado,
    required this.telefone,
    required this.email,
  });

  factory Oficina.fromJson(Map<String, dynamic> json) {
    return Oficina(
      id: json['id'],
      nome: json['nome'],
      cidade: json['cidade'],
      estado: json['estado'],
      telefone: json['telefone'],
      email: json['email'],
    );
  }
}

class FaseAtual {
  final int id;
  final String tipoFase;
  final String descricaoFase;
  final String dataInicio;
  final bool emAndamento;
  final ResponsavelFase responsavel;

  FaseAtual({
    required this.id,
    required this.tipoFase,
    required this.descricaoFase,
    required this.dataInicio,
    required this.emAndamento,
    required this.responsavel,
  });

  factory FaseAtual.fromJson(Map<String, dynamic> json) {
    return FaseAtual(
      id: json['id'],
      tipoFase: json['tipoFase'],
      descricaoFase: json['descricaoFase'],
      dataInicio: json['dataInicio'],
      emAndamento: json['emAndamento'],
      responsavel: ResponsavelFase.fromJson(json['responsavel']),
    );
  }
}

class ResponsavelFase {
  final int id;
  final String nome;

  ResponsavelFase({required this.id, required this.nome});

  factory ResponsavelFase.fromJson(Map<String, dynamic> json) {
    return ResponsavelFase(
      id: json['id'],
      nome: json['nome'],
    );
  }
}