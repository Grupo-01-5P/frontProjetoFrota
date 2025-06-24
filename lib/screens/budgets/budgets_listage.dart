import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_page.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_create.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_details.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BudgetsListage extends StatefulWidget {
  BudgetsListage({super.key});

  @override
  _BudgetsListageState createState() => _BudgetsListageState();
}

class _BudgetsListageState extends State<BudgetsListage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _pesquisaController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();
  
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _budgets = [];
  List<Map<String, dynamic>> _budgetsFiltrados = [];
  
  // Variáveis de paginação
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalItems = 0;
  int _totalPages = 0;
  bool _hasNextPage = false;
  bool _hasPrevPage = false;
  
  // Variáveis de filtro e ordenação
  String? _filtroStatus;
  String _sortField = 'id';
  String _sortOrder = 'desc';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _carregarBudgets();
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  // Função para carregar os orçamentos da API com paginação
  Future<void> _carregarBudgets({int? page, bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    
    try {
      // Obter o token de autenticação
      final token = await _secureStorage.read(key: 'auth_token');
      
      if (token == null) {
        setState(() {
          _errorMessage = 'Token de autenticação não encontrado';
          _isLoading = false;
        });
        return;
      }
      
      // Construir URL com parâmetros de paginação
      final queryParams = <String, String>{
        '_page': (page ?? _currentPage).toString(),
        '_limit': _itemsPerPage.toString(),
        '_sort': _sortField,
        '_order': _sortOrder,
      };
      
      // Adicionar filtro de status se selecionado
      if (_filtroStatus != null && _filtroStatus!.isNotEmpty) {
        queryParams['status'] = _filtroStatus!;
      }
      
      final uri = Uri.parse('http://localhost:4040/api/budgets').replace(
        queryParameters: queryParams,
      );
      
      print('Fazendo requisição para: $uri'); // Debug
      
      // Fazer a requisição para o endpoint
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('Resposta: ${response.statusCode} - ${response.body}'); // Debug
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['data'] != null && data['data'] is List && data['meta'] != null) {
          final List<Map<String, dynamic>> budgetsCarregados = [];
          
          for (var budgetJson in data['data']) {
            budgetsCarregados.add(budgetJson as Map<String, dynamic>);
          }
          
          // Extrair informações de paginação da resposta
          final meta = data['meta'];
          
          setState(() {
            _budgets = budgetsCarregados;
            _currentPage = meta['currentPage'] ?? 1;
            _totalItems = meta['totalItems'] ?? 0;
            _totalPages = meta['totalPages'] ?? 0;
            _hasNextPage = meta['hasNextPage'] ?? false;
            _hasPrevPage = meta['hasPrevPage'] ?? false;
            _itemsPerPage = meta['itemsPerPage'] ?? 10;
            _isLoading = false;
          });
          
          // Aplicar filtro local de busca se necessário
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
          _errorMessage = 'Erro ao carregar orçamentos: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro de conexão: $e';
        _isLoading = false;
      });
      print('Erro ao carregar orçamentos: $e');
    }
  }

  // Aplicar filtro de busca local
  void _aplicarFiltroBusca() {
    if (_searchQuery.isEmpty) {
      _budgetsFiltrados = List.from(_budgets);
    } else {
      final query = _searchQuery.toLowerCase();
      _budgetsFiltrados = _budgets.where((budget) {
        final placa = _getSafe(budget, ['manutencao', 'veiculo', 'placa'], '').toLowerCase();
        final oficina = _getSafe(budget, ['oficina', 'nome'], '').toLowerCase();
        final descricao = _getSafe(budget, ['descricaoServico'], '').toLowerCase();
        
        return placa.contains(query) || 
               oficina.contains(query) || 
               descricao.contains(query);
      }).toList();
    }
  }

  // Filtrar orçamentos com base no texto de pesquisa
  void _filtrarBudgets(String pesquisa) {
    setState(() {
      _searchQuery = pesquisa;
      _aplicarFiltroBusca();
    });
  }

  // Navegar para página específica
  Future<void> _irParaPagina(int page) async {
    if (page >= 1 && page <= _totalPages && page != _currentPage) {
      await _carregarBudgets(page: page);
    }
  }

  // Alterar ordenação
  void _alterarOrdenacao(String field) {
    setState(() {
      if (_sortField == field) {
        _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc';
      } else {
        _sortField = field;
        _sortOrder = 'asc';
      }
    });
    _carregarBudgets(page: 1);
  }

  // Alterar filtro de status
  void _alterarFiltroStatus(String? status) {
    setState(() {
      _filtroStatus = status;
    });
    _carregarBudgets(page: 1);
  }

  // Alterar itens por página
  void _alterarItensPorPagina(int novoLimit) {
    setState(() {
      _itemsPerPage = novoLimit;
    });
    _carregarBudgets(page: 1);
  }

  // Função auxiliar para obter valores de forma segura do mapa
  T _getSafe<T>(Map<String, dynamic> map, List<String> keys, T defaultValue) {
    dynamic current = map;
    for (String key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return defaultValue;
      }
    }
    if (current is T) {
      return current;
    }
    // Tentar uma conversão se for num e T for double ou int
    if (defaultValue is double && current is num) {
      return current.toDouble() as T;
    }
    if (defaultValue is int && current is num) {
      return current.toInt() as T;
    }
    return defaultValue;
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  // Widget para controles de paginação
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
          // Informações da paginação
          Text(
            'Mostrando ${_budgets.length} de $_totalItems orçamentos',
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
          
          // Controles de navegação responsivos
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 500) {
                // Layout para telas maiores
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botão página anterior
                    Flexible(
                      child: ElevatedButton.icon(
                        onPressed: _hasPrevPage ? () => _irParaPagina(_currentPage - 1) : null,
                        icon: const Icon(Icons.chevron_left, size: 18),
                        label: const Text('Anterior'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasPrevPage ? Colors.green : Colors.grey[300],
                          foregroundColor: _hasPrevPage ? Colors.white : Colors.grey[600],
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    
                    // Indicador de páginas
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
                                        ? Colors.green 
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
                    
                    // Botão próxima página
                    Flexible(
                      child: ElevatedButton.icon(
                        onPressed: _hasNextPage ? () => _irParaPagina(_currentPage + 1) : null,
                        icon: const Icon(Icons.chevron_right, size: 18),
                        label: const Text('Próxima'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasNextPage ? Colors.green : Colors.grey[300],
                          foregroundColor: _hasNextPage ? Colors.white : Colors.grey[600],
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Layout para telas menores
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Botão página anterior
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _hasPrevPage ? () => _irParaPagina(_currentPage - 1) : null,
                            icon: const Icon(Icons.chevron_left, size: 18),
                            label: const Text('Anterior'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasPrevPage ? Colors.green : Colors.grey[300],
                              foregroundColor: _hasPrevPage ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Botão próxima página
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _hasNextPage ? () => _irParaPagina(_currentPage + 1) : null,
                            icon: const Icon(Icons.chevron_right, size: 18),
                            label: const Text('Próxima'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasNextPage ? Colors.green : Colors.grey[300],
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
                                    ? Colors.green 
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

  // Widget para filtros e ordenação
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
          // Filtros em linha para telas maiores, coluna para menores
          MediaQuery.of(context).size.width > 600
              ? Row(
                  children: [
                    // Filtro por status
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filtroStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem<String>(value: null, child: Text('Todos')),
                          DropdownMenuItem<String>(value: 'pendente', child: Text('Pendente')),
                          DropdownMenuItem<String>(value: 'aprovado', child: Text('Aprovado')),
                          DropdownMenuItem<String>(value: 'reprovado', child: Text('Reprovado')),
                        ],
                        onChanged: _alterarFiltroStatus,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Itens por página
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
              : Column(
                  children: [
                    // Filtro por status
                    DropdownButtonFormField<String>(
                      value: _filtroStatus,
                      decoration: const InputDecoration(
                        labelText: 'Filtrar por status',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem<String>(value: null, child: Text('Todos os status')),
                        DropdownMenuItem<String>(value: 'pendente', child: Text('Pendente')),
                        DropdownMenuItem<String>(value: 'aprovado', child: Text('Aprovado')),
                        DropdownMenuItem<String>(value: 'reprovado', child: Text('Reprovado')),
                      ],
                      onChanged: _alterarFiltroStatus,
                    ),
                    const SizedBox(height: 12),
                    
                    // Itens por página
                    DropdownButtonFormField<int>(
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
                  ],
                ),
          const SizedBox(height: 12),
          
          // Ordenação
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
                  _buildSortChip('descricaoServico', 'Serviço'),
                  _buildSortChip('valorMaoObra', 'Valor'),
                  _buildSortChip('status', 'Status'),
                ],
              ),
            ],
          ),
        ],
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
      selectedColor: Colors.green.withOpacity(0.2),
      checkmarkColor: Colors.green,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      
      appBar: AppBar(
        title: const Text('Gerenciar Orçamentos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),

      body: RefreshIndicator(
        onRefresh: () => _carregarBudgets(page: _currentPage),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campo de pesquisa
              TextField(
                controller: _pesquisaController,
                decoration: InputDecoration(
                  hintText: 'Buscar por placa, oficina ou serviço...',
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
                            _filtrarBudgets('');
                          },
                        )
                      : null,
                ),
                onChanged: _filtrarBudgets,
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
                        onPressed: () => _carregarBudgets(page: _currentPage),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),

              // Lista de orçamentos
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.green,
                        ),
                      )
                    : _budgetsFiltrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty 
                                      ? 'Nenhum orçamento encontrado'
                                      : 'Nenhum orçamento encontrado com "${_searchQuery}"',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      _pesquisaController.clear();
                                      _filtrarBudgets('');
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
                                  itemCount: _budgetsFiltrados.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final budget = _budgetsFiltrados[index];
                                    return _buildBudgetCard(budget);
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
      
      // Botão flutuante para adicionar novo orçamento
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BudgetCreate()),
          );
          
          // Se retornou true, recarregar a lista
          if (result == true) {
            _carregarBudgets(page: _currentPage);
          }
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Criar Novo Orçamento',
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Manutenções',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'lib/assets/images/logoorcamentos.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                Colors.green,
                BlendMode.srcIn,
              ),
            ),
            label: 'Orçamentos',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Inoperante',
          ),
        ],
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        onTap: (index) {},
      ),
    );
  }

  // Widget para o card de orçamento
  Widget _buildBudgetCard(Map<String, dynamic> budget) {
    final String placa = _getSafe(budget, ['manutencao', 'veiculo', 'placa'], 'N/A');
    final String status = _getSafe(budget, ['status'], 'N/A').toString().toUpperCase();
    final String nomeOficina = _getSafe(budget, ['oficina', 'nome'], 'N/A');
    final String descServico = _getSafe(budget, ['descricaoServico'], 'N/A');
    final String dataEnvioStr = _getSafe(budget, ['dataEnvio'], '');
    final double valorMaoObra = _getSafe(budget, ['valorMaoObra'], 0.0);
    final int budgetId = _getSafe(budget, ['id'], 0);

    final List<dynamic> produtosDynamic = _getSafe(budget, ['produtos'], []);
    double totalProdutos = 0.0;
    if (produtosDynamic is List) {
      for (var produtoMap in produtosDynamic) {
        if (produtoMap is Map<String, dynamic>) {
          totalProdutos += _getSafe(produtoMap, ['valorUnitario'], 0.0);
        }
      }
    }

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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BudgetsDetails(
                budgetData: budget,
                budgetId: budgetId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar do orçamento
              CircleAvatar(
                backgroundColor: Colors.green.withOpacity(0.1),
                child: Icon(
                  Icons.receipt,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              
              // Informações do orçamento
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          placa,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (nomeOficina != 'N/A')
                      Text(
                        'Oficina: $nomeOficina',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (descServico != 'N/A')
                      Text(
                        descServico,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Enviado: ${_formatDate(dataEnvioStr)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          'R\$ ${(valorMaoObra + totalProdutos).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Ícone de navegação
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Função para obter cor do status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendente':
        return Colors.orange;
      case 'aprovado':
        return Colors.green;
      case 'reprovado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}