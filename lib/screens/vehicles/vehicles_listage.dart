import 'package:flutter/material.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicles_details.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicle_service.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicles_register.dart';

class VehiclesListage extends StatefulWidget {
  const VehiclesListage({Key? key}) : super(key: key);

  @override
  _VehiclesListageState createState() => _VehiclesListageState();
}

class _VehiclesListageState extends State<VehiclesListage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final VehicleService _vehicleService = VehicleService();
  
  List<dynamic> _allVehicles = [];
  List<dynamic> _displayedVehicles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Carregar veículos da API
  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vehicles = await _vehicleService.getVehicles();
      setState(() {
        _allVehicles = vehicles;
        _displayedVehicles = List.from(_allVehicles);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar veículos: ${e.toString()}';
        _isLoading = false;
      });
      print('Erro ao carregar veículos: $e');
    }
  }

  // Filtrar veículos com base no texto de pesquisa
  void _filterVehicles(String search) {
    setState(() {
      if (search.isEmpty) {
        _displayedVehicles = List.from(_allVehicles);
      } else {
        search = search.toLowerCase();
        _displayedVehicles = _allVehicles.where((vehicle) {
          final placa = vehicle['placa']?.toString().toLowerCase() ?? '';
          final marca = vehicle['marca']?.toString().toLowerCase() ?? '';
          final modelo = vehicle['modelo']?.toString().toLowerCase() ?? '';
          return placa.contains(search) ||
              marca.contains(search) ||
              modelo.contains(search);
        }).toList();
      }
    });
  }

  // Navegar para detalhes do veículo
  Future<void> _navigateToVehicleDetails(dynamic vehicle) async {
    final shouldRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => VehiclesDetails(vehicleId: vehicle['id']),
      ),
    );

    if (shouldRefresh == true && mounted) {
      await _loadVehicles();
    }
  }

  // Navegar para cadastro de veículo
  void _navigateToVehicleRegister() async {
    final shouldRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const VehiclesRegister(),
      ),
    );

    if (shouldRefresh == true && mounted) {
      await _loadVehicles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      
      // Drawer padronizado
      drawer: CustomDrawer(
        useCustomIcons: false,
      ),
      
      // AppBar padronizado
      appBar: AppBar(
        leading: Container(
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
            icon: Image.asset(
              'lib/assets/images/iconMenu.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      // Ação para notificações
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
      // Body padronizado
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título e botão de ordenação
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Buscar veículo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.sort_by_alpha,
                    color: Colors.black87,
                  ),
                  onPressed: () {
                    // Implementar ordenação se necessário
                    setState(() {
                      _displayedVehicles.sort((a, b) => 
                        (a['placa'] ?? '').toString().compareTo((b['placa'] ?? '').toString())
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Campo de pesquisa padronizado
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Digite a placa, marca ou modelo do veículo',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: _filterVehicles,
            ),
            const SizedBox(height: 16),
            
            // Mensagem de erro (se houver)
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade800, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadVehicles,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            
            // Lista de veículos padronizada
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0C7E3D),
                      ),
                    )
                  : _displayedVehicles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.directions_car_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'Nenhum veículo cadastrado'
                                    : 'Nenhum veículo encontrado',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterVehicles('');
                                  },
                                  child: const Text('Limpar busca'),
                                ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadVehicles,
                          child: ListView.separated(
                            itemCount: _displayedVehicles.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final vehicle = _displayedVehicles[index];
                              return _buildVehicleCard(vehicle);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      
      // Botão flutuante para adicionar novo veículo
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToVehicleRegister,
        backgroundColor: const Color(0xFF0C7E3D),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Widget para o card de veículo padronizado
  Widget _buildVehicleCard(dynamic vehicle) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToVehicleDetails(vehicle),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Ícone do veículo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C7E3D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: Color(0xFF0C7E3D),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Informações do veículo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Placa
                    Text(
                      vehicle['placa'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Marca e Modelo
                    Text(
                      '${vehicle['marca'] ?? 'N/A'} ${vehicle['modelo'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    
                    // Ano e Tipo
                    Text(
                      'Ano: ${vehicle['anoFabricacao']?.toString() ?? 'N/A'} • ${vehicle['tipoVeiculo'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Seta para indicar que é clicável
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}