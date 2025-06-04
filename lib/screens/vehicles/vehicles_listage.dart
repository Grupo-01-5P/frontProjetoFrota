import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_page.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicles_details.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicle_service.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicles_page.dart';

class VehiclesListage extends StatefulWidget {
  const VehiclesListage({super.key});

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
  bool _isSearching = false;
  String _errorMessage = '';

  // Controles de paginação
  int _currentPage = 1;
  final int _itemsPerPage = 5;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _isSearching = false;
        _updateDisplayedVehicles();
      });
    }
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final vehicles = await _vehicleService.getVehicles();
      setState(() {
        _allVehicles = vehicles;
        _totalPages = (vehicles.length / _itemsPerPage).ceil();
        _updateDisplayedVehicles();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar veículos: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _updateDisplayedVehicles() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    var endIndex = startIndex + _itemsPerPage;

    if (endIndex > _allVehicles.length) {
      endIndex = _allVehicles.length;
    }

    setState(() {
      _displayedVehicles = _allVehicles.sublist(startIndex, endIndex);
    });
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
        _updateDisplayedVehicles();
      });
    }
  }

  Future<void> _searchVehicles() async {
    final plate = _searchController.text.trim().toLowerCase();

    if (plate.isEmpty) {
      setState(() {
        _isSearching = false;
        _updateDisplayedVehicles();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
      _errorMessage = '';
    });

    try {
      final localResults =
          _allVehicles.where((vehicle) {
            final vehiclePlate =
                vehicle['placa']?.toString().toLowerCase() ?? '';
            return vehiclePlate.contains(plate);
          }).toList();

      setState(() {
        _displayedVehicles = localResults;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro na busca: ${e.toString()}';
        _isLoading = false;
        _displayedVehicles = [];
      });
    }
  }

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

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
          ),
          Text('Página $_currentPage de $_totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed:
                _currentPage < _totalPages
                    ? () => _goToPage(_currentPage + 1)
                    : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Cabeçalho do menu
            UserAccountsDrawerHeader(
              accountName: const Text('Kelvin'),
              accountEmail: const Text('Editar minhas informações'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.person, size: 40, color: Colors.grey),
              ),
              decoration: const BoxDecoration(color: Colors.green),
            ),

            // Itens do menu
            _buildDrawerItem(
              icon: Icons.request_quote,
              text: 'Orçamentos',
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => BudgetsPage()));
              },
            ),
            _buildDrawerItem(
              icon: Icons.build,
              text: 'Visualizar manutenções',
              onTap: () {
                // Ação para Visualizar manutenções
              },
            ),
            _buildDrawerItem(
              icon: Icons.warning,
              text: 'Veículos inoperantes',
              onTap: () {
                // Ação para Veículos inoperantes
              },
            ),
            _buildDrawerItem(
              icon: Icons.bar_chart,
              text: 'Dashboards',
              onTap: () {
                // Ação para Dashboards
              },
            ),
            _buildDrawerItem(
              icon: Icons.store,
              text: 'Mecânicas',
              onTap: () {
                // Ação para Mecânicas
              },
            ),
            _buildDrawerItem(
              icon: Icons.directions_car,
              text: 'Veículos',
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => VehiclesPage()));
              },
            ),
            _buildDrawerItem(
              icon: Icons.settings,
              text: 'Configurações',
              onTap: () {
                // Ação para Configurações
              },
            ),
            _buildDrawerItem(
              icon: Icons.exit_to_app,
              text: 'Sair',
              iconColor: Colors.red,
              onTap: () {
                // Ação para Sair
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 80),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Buscar veículo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Digite a placa do veículo',
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            suffixIcon: IconButton(
                              icon:
                                  _isSearching
                                      ? const Icon(Icons.clear)
                                      : const Icon(Icons.search),
                              onPressed:
                                  _isSearching
                                      ? () {
                                        _searchController.clear();
                                        _searchVehicles();
                                      }
                                      : _searchVehicles,
                            ),
                          ),
                          onSubmitted: (_) => _searchVehicles(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage.isNotEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_errorMessage),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadVehicles,
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        )
                        : _displayedVehicles.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _isSearching
                                    ? 'Nenhum veículo encontrado para "${_searchController.text}"'
                                    : 'Nenhum veículo cadastrado',
                              ),
                              if (_isSearching)
                                TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchVehicles();
                                  },
                                  child: const Text('Limpar busca'),
                                ),
                            ],
                          ),
                        )
                        : RefreshIndicator(
                          onRefresh: _loadVehicles,
                          child: Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _displayedVehicles.length,
                                  itemBuilder: (context, index) {
                                    final vehicle = _displayedVehicles[index];
                                    return Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        8,
                                        16,
                                        8,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: InkWell(
                                          onTap:
                                              () => _navigateToVehicleDetails(
                                                vehicle,
                                              ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      vehicle['placa'] ?? 'N/A',
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${vehicle['modelo'] ?? 'N/A'}\n'
                                                      '${vehicle['anoFabricacao']?.toString() ?? 'N/A'}',
                                                      textAlign:
                                                          TextAlign.right,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              if (!_isSearching) _buildPaginationControls(),
                            ],
                          ),
                        ),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications,
                            color: Colors.black,
                          ),
                          onPressed: () {},
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '3',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Manutenções',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'lib/assets/images/_2009906610368.svg',
              width: 24,
              height: 24,
              color: Colors.green,
            ),
            label: 'Orçamentos',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Inoperante',
          ),
        ],
        selectedItemColor: Colors.green,
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color iconColor = Colors.green,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(text),
      onTap: onTap,
    );
  }
}
