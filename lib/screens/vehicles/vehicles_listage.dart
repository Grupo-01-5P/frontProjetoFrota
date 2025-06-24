import 'package:flutter/material.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicles_details.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicles_register.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VehiclesListage extends StatefulWidget {
  const VehiclesListage({Key? key}) : super(key: key);

  @override
  _VehiclesListageState createState() => _VehiclesListageState();
}

class _VehiclesListageState extends State<VehiclesListage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _pesquisaController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();
  
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _vehicles = [];
  List<dynamic> _vehiclesFiltrados = [];
  
  // Variáveis de paginação
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalItems = 0;
  int _totalPages = 0;
  bool _hasNextPage = false;
  bool _hasPrevPage = false;
  
  // Variáveis de filtro e ordenação
  String _filtroStatus = 'todos';
  String _sortField = 'placa';
  String _sortOrder = 'asc';
  String _searchQuery = '';
  Map<String, int> _statusCount = {'emManutencao': 0, 'emFrota': 0};

  @override
  void initState() {
    super.initState();
    _carregarVehicles();
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  Future<void> _carregarVehicles({int? page, bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      
      if (token == null) {
        setState(() {
          _errorMessage = 'Token de autenticação não encontrado';
          _isLoading = false;
        });
        return;
      }
      
      final queryParams = <String, String>{
        '_page': (page ?? _currentPage).toString(),
        '_limit': _itemsPerPage.toString(),
        '_sort': _sortField,
        '_order': _sortOrder,
      };
      
      if (_filtroStatus != 'todos') {
        queryParams['status'] = _filtroStatus;
      }
      
      final uri = Uri.parse('http://localhost:4040/api/veiculos').replace(
        queryParameters: queryParams,
      );
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['data'] != null && data['data'] is List && data['meta'] != null) {
          final List<dynamic> vehiclesCarregados = data['data'];
          final meta = data['meta'];
          
          setState(() {
            _vehicles = vehiclesCarregados;
            _currentPage = meta['currentPage'] ?? 1;
            _totalItems = meta['totalItems'] ?? 0;
            _totalPages = meta['totalPages'] ?? 0;
            _hasNextPage = meta['hasNextPage'] ?? false;
            _hasPrevPage = meta['hasPrevPage'] ?? false;
            _itemsPerPage = meta['itemsPerPage'] ?? 10;
            
            if (meta['statusCount'] != null) {
              _statusCount = {
                'emManutencao': meta['statusCount']['emManutencao'] ?? 0,
                'emFrota': meta['statusCount']['emFrota'] ?? 0,
              };
            }
            
            _isLoading = false;
          });
          
          _aplicarFiltroBusca();
        } else {
          setState(() {
            _errorMessage = 'Formato de resposta inválido';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Sessão expirada, faça login novamente';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao carregar veículos: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro de conexão: $e';
        _isLoading = false;
      });
    }
  }

  void _aplicarFiltroBusca() {
    if (_searchQuery.isEmpty) {
      _vehiclesFiltrados = List.from(_vehicles);
    } else {
      final query = _searchQuery.toLowerCase();
      _vehiclesFiltrados = _vehicles.where((vehicle) {
        final placa = (vehicle['placa'] ?? '').toLowerCase();
        final marca = (vehicle['marca'] ?? '').toLowerCase();
        final modelo = (vehicle['modelo'] ?? '').toLowerCase();
        
        return placa.contains(query) || 
               marca.contains(query) || 
               modelo.contains(query);
      }).toList();
    }
  }

  void _filtrarVehicles(String pesquisa) {
    setState(() {
      _searchQuery = pesquisa;
      _aplicarFiltroBusca();
    });
  }

  Future<void> _irParaPagina(int page) async {
    if (page >= 1 && page <= _totalPages && page != _currentPage) {
      await _carregarVehicles(page: page);
    }
  }

  void _alterarOrdenacao(String field) {
    setState(() {
      if (_sortField == field) {
        _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc';
      } else {
        _sortField = field;
        _sortOrder = 'asc';
      }
    });
    _carregarVehicles(page: 1);
  }

  void _alterarFiltroStatus(String status) {
    setState(() {
      _filtroStatus = status;
    });
    _carregarVehicles(page: 1);
  }

  void _alterarItensPorPagina(int novoLimit) {
    setState(() {
      _itemsPerPage = novoLimit;
    });
    _carregarVehicles(page: 1);
  }

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

  Color _getUrgenciaColor(String? urgencia) {
    if (urgencia == null) return Colors.grey;
    
    switch (urgencia.toLowerCase()) {
      case 'alta':
      case 'high':
        return Colors.red;
      case 'média':
      case 'medium':
        return Colors.orange;
      case 'baixa':
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPaginationControls() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Text(
            'Mostrando ${_vehicles.length} de $_totalItems veículos',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Página $_currentPage de $_totalPages',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 500) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: ElevatedButton.icon(
                        onPressed: _hasPrevPage ? () => _irParaPagina(_currentPage - 1) : null,
                        icon: const Icon(Icons.chevron_left, size: 18),
                        label: const Text('Anterior'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasPrevPage ? const Color(0xFF0C7E3D) : Colors.grey[300],
                          foregroundColor: _hasPrevPage ? Colors.white : Colors.grey[600],
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    
                    if (_totalPages <= 7)
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_totalPages, (index) {
                            final pageNum = index + 1;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: ElevatedButton(
                                  onPressed: pageNum != _currentPage ? () => _irParaPagina(pageNum) : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: pageNum == _currentPage 
                                        ? const Color(0xFF0C7E3D) 
                                        : Colors.grey[200],
                                    foregroundColor: pageNum == _currentPage 
                                        ? Colors.white 
                                        : Colors.black87,
                                    padding: EdgeInsets.zero,
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  child: Text(pageNum.toString()),
                                ),
                              ),
                            );
                          }),
                        ),
                      )
                    else
                      Text(
                        'Página $_currentPage',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    
                    Flexible(
                      child: ElevatedButton.icon(
                        onPressed: _hasNextPage ? () => _irParaPagina(_currentPage + 1) : null,
                        icon: const Icon(Icons.chevron_right, size: 18),
                        label: const Text('Próxima'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasNextPage ? const Color(0xFF0C7E3D) : Colors.grey[300],
                          foregroundColor: _hasNextPage ? Colors.white : Colors.grey[600],
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _hasPrevPage ? () => _irParaPagina(_currentPage - 1) : null,
                            icon: const Icon(Icons.chevron_left, size: 18),
                            label: const Text('Anterior'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasPrevPage ? const Color(0xFF0C7E3D) : Colors.grey[300],
                              foregroundColor: _hasPrevPage ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _hasNextPage ? () => _irParaPagina(_currentPage + 1) : null,
                            icon: const Icon(Icons.chevron_right, size: 18),
                            label: const Text('Próxima'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasNextPage ? const Color(0xFF0C7E3D) : Colors.grey[300],
                              foregroundColor: _hasNextPage ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_totalPages <= 10) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        alignment: WrapAlignment.center,
                        children: List.generate(_totalPages, (index) {
                          final pageNum = index + 1;
                          return SizedBox(
                            width: 32,
                            height: 32,
                            child: ElevatedButton(
                              onPressed: pageNum != _currentPage ? () => _irParaPagina(pageNum) : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: pageNum == _currentPage 
                                    ? const Color(0xFF0C7E3D) 
                                    : Colors.grey[200],
                                foregroundColor: pageNum == _currentPage 
                                    ? Colors.white 
                                    : Colors.black87,
                                padding: EdgeInsets.zero,
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              child: Text(pageNum.toString()),
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosEOrdenacao() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusTab('todos', 'Todos (${_statusCount['emManutencao']! + _statusCount['emFrota']!})'),
                const SizedBox(width: 8),
                _buildStatusTab('em_manutencao', 'Em Manutenção (${_statusCount['emManutencao']})'),
                const SizedBox(width: 8),
                _buildStatusTab('em_frota', 'Em Frota (${_statusCount['emFrota']})'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          MediaQuery.of(context).size.width > 600
              ? Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _itemsPerPage,
                        decoration: const InputDecoration(
                          labelText: 'Por página',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem<int>(value: 5, child: Text('5')),
                          DropdownMenuItem<int>(value: 10, child: Text('10')),
                          DropdownMenuItem<int>(value: 20, child: Text('20')),
                          DropdownMenuItem<int>(value: 50, child: Text('50')),
                        ],
                        onChanged: (value) => value != null ? _alterarItensPorPagina(value) : null,
                        isDense: true,
                      ),
                    ),
                  ],
                )
              : DropdownButtonFormField<int>(
                  value: _itemsPerPage,
                  decoration: const InputDecoration(
                    labelText: 'Itens por página',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem<int>(value: 5, child: Text('5 por página')),
                    DropdownMenuItem<int>(value: 10, child: Text('10 por página')),
                    DropdownMenuItem<int>(value: 20, child: Text('20 por página')),
                    DropdownMenuItem<int>(value: 50, child: Text('50 por página')),
                  ],
                  onChanged: (value) => value != null ? _alterarItensPorPagina(value) : null,
                ),
          const SizedBox(height: 12),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ordenar por:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildSortChip('placa', 'Placa'),
                  _buildSortChip('marca', 'Marca'),
                  _buildSortChip('modelo', 'Modelo'),
                  _buildSortChip('anoFabricacao', 'Ano'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab(String status, String label) {
    final isActive = _filtroStatus == status;
    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      child: GestureDetector(
        onTap: () => _alterarFiltroStatus(status),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0C7E3D) : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String field, String label) {
    final isSelected = _sortField == field;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 4),
            Icon(
              _sortOrder == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (_) => _alterarOrdenacao(field),
      selectedColor: const Color(0xFF0C7E3D).withOpacity(0.2),
      checkmarkColor: const Color(0xFF0C7E3D),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

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
        onTap: () async {
          final shouldRefresh = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => VehiclesDetails(vehicleId: vehicle['id']),
            ),
          );

          if (shouldRefresh == true && mounted) {
            await _carregarVehicles(page: _currentPage);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
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
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        
                        Text(
                          '${vehicle['marca'] ?? 'N/A'} ${vehicle['modelo'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        
                        Text(
                          'Ano: ${vehicle['anoFabricacao']?.toString() ?? 'N/A'} • ${vehicle['tipoVeiculo'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        
                        if (vehicle['supervisor'] != null)
                          Text(
                            'Supervisor: ${vehicle['supervisor']['nome']}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 24,
                  ),
                ],
              ),
              
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
                          Expanded(
                            child: Text(
                              'Manutenção #${manutencaoAtiva['id']} - ${manutencaoAtiva['status']?.toString().toUpperCase()}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                          if (manutencaoAtiva['urgencia'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getUrgenciaColor(manutencaoAtiva['urgencia']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                manutencaoAtiva['urgencia'].toString().toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getUrgenciaColor(manutencaoAtiva['urgencia']),
                                  fontWeight: FontWeight.w500,
                                ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      
      drawer: const CustomDrawer(
        useCustomIcons: false,
      ),
      
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
            onPressed: () => _carregarVehicles(page: _currentPage),
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

      body: RefreshIndicator(
        onRefresh: () => _carregarVehicles(page: _currentPage),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              const Text(
                'Gerenciar Veículos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Campo de pesquisa
              TextField(
                controller: _pesquisaController,
                decoration: InputDecoration(
                  hintText: 'Buscar por placa, marca ou modelo...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _pesquisaController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _pesquisaController.clear();
                            _filtrarVehicles('');
                          },
                        )
                      : null,
                ),
                onChanged: _filtrarVehicles,
              ),
              const SizedBox(height: 16),

              // Filtros e ordenação
              _buildFiltrosEOrdenacao(),

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
                      Icon(Icons.error_outline, color: Colors.red.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _carregarVehicles(page: _currentPage),
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
                    : _vehiclesFiltrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty 
                                      ? 'Nenhum veículo encontrado'
                                      : 'Nenhum veículo encontrado com "${_searchQuery}"',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_searchQuery.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      _pesquisaController.clear();
                                      _filtrarVehicles('');
                                    },
                                    child: const Text('Limpar busca'),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: ListView.separated(
                                  itemCount: _vehiclesFiltrados.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final vehicle = _vehiclesFiltrados[index];
                                    return _buildVehicleCard(vehicle);
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildPaginationControls(),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
      
      // Botão flutuante para adicionar novo veículo
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final shouldRefresh = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const VehiclesRegister(),
            ),
          );

          if (shouldRefresh == true && mounted) {
            _carregarVehicles(page: _currentPage);
          }
        },
        backgroundColor: const Color(0xFF0C7E3D),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Cadastrar Novo Veículo',
      ),
    );
  }
}