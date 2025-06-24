import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:front_projeto_flutter/screens/supervisor/maintenences/manutencao_detalhe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class ManutencoesGeralScreenSupervisor extends StatefulWidget {
  const ManutencoesGeralScreenSupervisor({Key? key}) : super(key: key);

  @override
  _ManutencoesGeralScreenSupervisorState createState() =>
      _ManutencoesGeralScreenSupervisorState();
}

class _ManutencoesGeralScreenSupervisorState
    extends State<ManutencoesGeralScreenSupervisor> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _pesquisaController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();
  
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _manutencoes = [];
  List<dynamic> _manutencoesFiltradas = [];
  
  // Variáveis de paginação
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalItems = 0;
  int _totalPages = 0;
  bool _hasNextPage = false;
  bool _hasPrevPage = false;
  
  // Variáveis de filtro e ordenação
  String _filtroStatus = 'aprovada';
  String _sortField = 'dataSolicitacao';
  String _sortOrder = 'desc';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _carregarManutencoes();
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  Future<void> _carregarManutencoes({int? page, bool showLoading = true}) async {
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
        'status': _filtroStatus,
      };
      
      final uri = Uri.parse('http://localhost:4040/api/maintenance').replace(
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
        
        if (data['manutencoes'] != null && data['manutencoes'] is List) {
          final List<dynamic> manutencoesCarregadas = data['manutencoes'];
          final pageInfo = data['_page'];
          
          setState(() {
            _manutencoes = manutencoesCarregadas;
            
            if (pageInfo != null) {
              _currentPage = pageInfo['current'] ?? 1;
              _totalPages = pageInfo['total'] ?? 1;
              _totalItems = pageInfo['size'] ?? 0;
              _hasNextPage = _currentPage < _totalPages;
              _hasPrevPage = _currentPage > 1;
            } else {
              _hasNextPage = manutencoesCarregadas.length == _itemsPerPage;
              _hasPrevPage = _currentPage > 1;
              _totalItems = manutencoesCarregadas.length;
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
          _errorMessage = 'Erro ao carregar manutenções: ${response.statusCode}';
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
      _manutencoesFiltradas = List.from(_manutencoes);
    } else {
      final query = _searchQuery.toLowerCase();
      _manutencoesFiltradas = _manutencoes.where((manutencao) {
        final placa = (manutencao['veiculo']?['placa'] ?? '').toLowerCase();
        final problema = (manutencao['descricaoProblema'] ?? '').toLowerCase();
        final localizacao = (manutencao['localizacao'] ?? '').toLowerCase();
        final id = manutencao['id'].toString();
        
        return placa.contains(query) || 
               problema.contains(query) || 
               localizacao.contains(query) ||
               id.contains(query);
      }).toList();
    }
  }

  void _filtrarManutencoes(String pesquisa) {
    setState(() {
      _searchQuery = pesquisa;
      _aplicarFiltroBusca();
    });
  }

  Future<void> _irParaPagina(int page) async {
    if (page >= 1 && page <= _totalPages && page != _currentPage) {
      await _carregarManutencoes(page: page);
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
    _carregarManutencoes(page: 1);
  }

  void _alterarFiltroStatus(String status) {
    setState(() {
      _filtroStatus = status;
    });
    _carregarManutencoes(page: 1);
  }

  void _alterarItensPorPagina(int novoLimit) {
    setState(() {
      _itemsPerPage = novoLimit;
    });
    _carregarManutencoes(page: 1);
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return "Data não informada";
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null) return "Não informado";
    try {
      final date = DateTime.parse(dateString);
      return "${DateFormat('dd/MM/yyyy').format(date)} - ${DateFormat('HH:mm').format(date)}";
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aprovada':
      case 'em analise':
        return const Color(0xFF0C7E3D);
      case 'pendente':
        return Colors.orange;
      case 'reprovada':
        return Colors.red;
      case 'concluída':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'aprovada':
      case 'em analise':
        return 'Em Andamento';
      case 'pendente':
        return 'Pendente';
      case 'reprovada':
        return 'Reprovada';
      case 'concluída':
        return 'Concluída';
      default:
        return status;
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

  // Função para obter cor da fase
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

  // Função para obter ícone da fase
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
            'Mostrando ${_manutencoes.length} de $_totalItems manutenções',
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
                _buildStatusTab('aprovada', 'Em Andamento'),
                const SizedBox(width: 8),
                _buildStatusTab('pendente', 'Pendentes'),
                const SizedBox(width: 8),
                _buildStatusTab('concluída', 'Concluídas'),
                const SizedBox(width: 8),
                _buildStatusTab('reprovada', 'Reprovadas'),
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
                  _buildSortChip('id', 'ID'),
                  _buildSortChip('dataSolicitacao', 'Data Solicitação'),
                  _buildSortChip('dataEnviarMecanica', 'Data Envio'),
                  _buildSortChip('urgencia', 'Urgência'),
                  _buildSortChip('status', 'Status'),
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
                fontSize: 12,
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

  Widget _buildManutencaoCard(dynamic manutencao) {
    final veiculo = manutencao['veiculo'];
    final status = manutencao['status'] ?? 'Desconhecido';
    final faseAtual = manutencao['faseAtual'];

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
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ManutencaoDetailScreenSupervisor(
                manutencao: manutencao,
                oficina: manutencao['oficina'],
              ),
            ),
          );

          if (result == true) {
            _carregarManutencoes(page: _currentPage);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manutenção #${manutencao['id']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              // NOVA SEÇÃO: Mostrar fase atual
              if (faseAtual != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getFaseColor(faseAtual['tipoFase']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getFaseColor(faseAtual['tipoFase']).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getFaseIcon(faseAtual['tipoFase']),
                        color: _getFaseColor(faseAtual['tipoFase']),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fase Atual: ${faseAtual['descricaoFase'] ?? faseAtual['tipoFase']}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: _getFaseColor(faseAtual['tipoFase']),
                                fontSize: 13,
                              ),
                            ),
                            if (faseAtual['emAndamento'] == true)
                              Text(
                                'Em andamento desde ${_formatDate(faseAtual['dataInicio'])}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            if (faseAtual['responsavel'] != null)
                              Text(
                                'Responsável: ${faseAtual['responsavel']['nome']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (faseAtual['emAndamento'] == true)
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
                ),
              ],

              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.directions_car, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Veículo: ${veiculo['placa']} - ${veiculo['marca']} ${veiculo['modelo']}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.build, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Problema: ${manutencao['descricaoProblema']?.length > 50 ? '${manutencao['descricaoProblema']?.substring(0, 50)}...' : manutencao['descricaoProblema'] ?? 'Não especificado'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Localização: ${manutencao['localizacao'] ?? 'Não especificada'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Data: ${_formatDate(manutencao['dataSolicitacao'])}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Data para levar: ${_formatDateTime(manutencao['dataEnviarMecanica'])}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              if (status.toLowerCase() == 'reprovada' && manutencao['motivoReprovacao'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Motivo da reprovação:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          manutencao['motivoReprovacao'],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (manutencao['urgencia'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getUrgenciaColor(manutencao['urgencia']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Urgência: ${manutencao['urgencia']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: _getUrgenciaColor(manutencao['urgencia']),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
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
      
      appBar: AppBar(
        title: const Text('Manutenções - Supervisor'),
        backgroundColor: const Color(0xFF0C7E3D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _carregarManutencoes(page: _currentPage),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () => _carregarManutencoes(page: _currentPage),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _pesquisaController,
                decoration: InputDecoration(
                  hintText: 'Buscar por ID, placa, problema ou localização...',
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
                            _filtrarManutencoes('');
                          },
                        )
                      : null,
                ),
                onChanged: _filtrarManutencoes,
              ),
              const SizedBox(height: 16),

              _buildFiltrosEOrdenacao(),

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
                        onPressed: () => _carregarManutencoes(page: _currentPage),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0C7E3D),
                        ),
                      )
                    : _manutencoesFiltradas.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.build_circle_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty 
                                      ? 'Nenhuma manutenção ${_getStatusText(_filtroStatus).toLowerCase()} encontrada'
                                      : 'Nenhuma manutenção encontrada com "${_searchQuery}"',
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
                                      _filtrarManutencoes('');
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
                                  itemCount: _manutencoesFiltradas.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final manutencao = _manutencoesFiltradas[index];
                                    return _buildManutencaoCard(manutencao);
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
    );
  }
}