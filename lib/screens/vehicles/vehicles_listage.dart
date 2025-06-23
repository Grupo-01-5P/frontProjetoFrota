import 'package:flutter/material.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicles_details.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicle_service.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicles_register.dart';
import 'package:intl/intl.dart';

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
  String _filtroAtivo = 'todos'; // 'todos', 'em_manutencao', 'em_frota'
  Map<String, int> _statusCount = {'emManutencao': 0, 'emFrota': 0};

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
      // Modificar o serviço para incluir o filtro de status se necessário
      final vehicles = await _vehicleService.getVehiclesWithStatus(_filtroAtivo);
      setState(() {
        _allVehicles = vehicles['data'] ?? [];
        _displayedVehicles = List.from(_allVehicles);
        
        // Atualizar contadores de status
        final meta = vehicles['meta'];
        if (meta != null && meta['statusCount'] != null) {
          _statusCount = {
            'emManutencao': meta['statusCount']['emManutencao'] ?? 0,
            'emFrota': meta['statusCount']['emFrota'] ?? 0,
          };
        }
        
        _isLoading = false;
      });
      
      // Aplicar filtro de busca se houver texto
      if (_searchController.text.isNotEmpty) {
        _filterVehicles(_searchController.text);
      }
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

  // Alterar filtro de status
  void _changeStatusFilter(String newFilter) {
    setState(() {
      _filtroAtivo = newFilter;
    });
    _loadVehicles();
  }

  // Obter cor do status
  Color _getStatusColor(String? statusManutencao) {
    switch (statusManutencao) {
      case 'Em manutenção':
        return Colors.orange;
      case 'Em frota':
        return const Color(0xFF0C7E3D);
      default:
        return Colors.grey;
    }
  }

  // Obter ícone do status
  IconData _getStatusIcon(String? statusManutencao) {
    switch (statusManutencao) {
      case 'Em manutenção':
        return Icons.build;
      case 'Em frota':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  // Obter cor da fase
  Color _getFaseColor(String? tipoFase) {
    if (tipoFase == null) return Colors.grey;
    
    switch (tipoFase) {
      case 'INICIAR_VIAGEM':
        return Colors.orange;
      case 'DEIXAR_VEICULO':
        return Colors.blue;
      case 'SERVICO_FINALIZADO':
        return Colors.lightGreen;
      case 'RETORNO_VEICULO':
        return Colors.deepOrange;
      case 'VEICULO_ENTREGUE':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Obter ícone da fase
  IconData _getFaseIcon(String? tipoFase) {
    if (tipoFase == null) return Icons.help_outline;
    
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

  // Formatar data
  String _formatDate(String? dateString) {
    if (dateString == null) return "N/A";
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadVehicles,
          ),
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
      
      // Body com abas de filtro
      body: Column(
        children: [
          // Abas de filtro de status
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _changeStatusFilter('todos'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _filtroAtivo == 'todos'
                            ? const Color(0xFF0C7E3D)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Todos (${_statusCount['emManutencao']! + _statusCount['emFrota']!})',
                          style: TextStyle(
                            color: _filtroAtivo == 'todos'
                                ? Colors.white
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _changeStatusFilter('em_manutencao'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _filtroAtivo == 'em_manutencao'
                            ? const Color(0xFF0C7E3D)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Em Manutenção (${_statusCount['emManutencao']})',
                          style: TextStyle(
                            color: _filtroAtivo == 'em_manutencao'
                                ? Colors.white
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _changeStatusFilter('em_frota'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _filtroAtivo == 'em_frota'
                            ? const Color(0xFF0C7E3D)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Em Frota (${_statusCount['emFrota']})',
                          style: TextStyle(
                            color: _filtroAtivo == 'em_frota'
                                ? Colors.white
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Conteúdo principal
          Expanded(
            child: Padding(
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
                  
                  // Campo de pesquisa
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
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: _filterVehicles,
                  ),
                  const SizedBox(height: 16),
                  
                  // Mensagem de erro
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
                  
                  // Lista de veículos
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
                                          ? 'Nenhum veículo encontrado'
                                          : 'Nenhum veículo encontrado para esta busca',
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
          ),
        ],
      ),
      
      // Botão flutuante para adicionar novo veículo
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToVehicleRegister,
        backgroundColor: const Color(0xFF0C7E3D),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Widget para o card de veículo com status de manutenção
  Widget _buildVehicleCard(dynamic vehicle) {
    final statusManutencao = vehicle['statusManutencao'] ?? 'Em frota';
    final manutencaoAtiva = vehicle['manutencaoAtiva'];
    final faseAtual = manutencaoAtiva?['faseAtual'];

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
          child: Column(
            children: [
              Row(
                children: [
                  // Ícone do veículo
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(statusManutencao).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: _getStatusColor(statusManutencao),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Informações do veículo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Placa e Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              vehicle['placa'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(statusManutencao).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(statusManutencao),
                                    size: 12,
                                    color: _getStatusColor(statusManutencao),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusManutencao,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: _getStatusColor(statusManutencao),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                  
                  // Seta
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 24,
                  ),
                ],
              ),
              
              // Informações da manutenção ativa (se houver)
              if (manutencaoAtiva != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.build,
                            size: 16,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Manutenção #${manutencaoAtiva['id']} - ${manutencaoAtiva['status']?.toString().toUpperCase()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      if (faseAtual != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              _getFaseIcon(faseAtual['tipoFase']),
                              size: 14,
                              color: _getFaseColor(faseAtual['tipoFase']),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Fase: ${faseAtual['descricaoFase'] ?? faseAtual['tipoFase']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            if (faseAtual['emAndamento'] == true)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Problema: ${manutencaoAtiva['descricaoProblema']?.length > 40 ? '${manutencaoAtiva['descricaoProblema']?.substring(0, 40)}...' : manutencaoAtiva['descricaoProblema'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (manutencaoAtiva['oficina'] != null)
                        Text(
                          'Oficina: ${manutencaoAtiva['oficina']['nome']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}