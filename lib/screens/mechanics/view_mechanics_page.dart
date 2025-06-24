import 'package:flutter/material.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:front_projeto_flutter/screens/mechanics/mechanic_detail_page.dart';

class ViewMechanicsPage extends StatefulWidget {
  const ViewMechanicsPage({Key? key}) : super(key: key);

  @override
  State<ViewMechanicsPage> createState() => _ViewMechanicsPageState();
}

class _ViewMechanicsPageState extends State<ViewMechanicsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _secureStorage = const FlutterSecureStorage();
  final TextEditingController _pesquisaController = TextEditingController();
  
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _mechanics = [];
  List<dynamic> _mechanicsFiltradas = [];
  
  // Variáveis de paginação
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalItems = 0;
  int _totalPages = 0;
  bool _hasNextPage = false;
  bool _hasPrevPage = false;
  
  // Variáveis de filtro e ordenação
  String? _filtroEstado;
  String _sortField = 'nome';
  String _sortOrder = 'asc';
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _carregarMechanics();
  }
  
  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }
  
  // Função para carregar as mecânicas da API com paginação
  Future<void> _carregarMechanics({int? page, bool showLoading = true}) async {
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
      
      // Adicionar filtro de estado se selecionado
      if (_filtroEstado != null && _filtroEstado!.isNotEmpty) {
        queryParams['estado'] = _filtroEstado!;
      }
      
      // Adicionar busca por nome se fornecida
      if (_searchQuery.isNotEmpty) {
        queryParams['nome'] = _searchQuery;
      }
      
      final uri = Uri.parse('http://localhost:4040/api/garage').replace(
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
        
        if (data['oficinas'] != null && data['oficinas'] is List) {
          final List<dynamic> mechanicsCarregadas = data['oficinas'];
          
          // Extrair informações de paginação da resposta
          final pageInfo = data['_page'];
          
          setState(() {
            _mechanics = mechanicsCarregadas;
            
            if (pageInfo != null) {
              _currentPage = pageInfo['current'] ?? 1;
              _totalPages = pageInfo['total'] ?? 1;
              _totalItems = pageInfo['size'] ?? 0;
              _hasNextPage = _currentPage < _totalPages;
              _hasPrevPage = _currentPage > 1;
            } else {
              // Fallback para estimativa baseada no tamanho da resposta
              _hasNextPage = mechanicsCarregadas.length == _itemsPerPage;
              _hasPrevPage = _currentPage > 1;
              _totalItems = mechanicsCarregadas.length;
            }
            
            _isLoading = false;
          });
          
          // Aplicar filtro local de busca se necessário (quando busca não for feita no servidor)
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
          _errorMessage = 'Erro ao carregar mecânicas: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro de conexão: $e';
        _isLoading = false;
      });
      print('Erro ao carregar mecânicas: $e');
    }
  }
  
  // Aplicar filtro de busca local
  void _aplicarFiltroBusca() {
    if (_searchQuery.isEmpty) {
      _mechanicsFiltradas = List.from(_mechanics);
    } else {
      final query = _searchQuery.toLowerCase();
      _mechanicsFiltradas = _mechanics.where((mechanic) {
        return (mechanic['nome']?.toLowerCase()?.contains(query) ?? false) ||
            (mechanic['email']?.toLowerCase()?.contains(query) ?? false) ||
            (mechanic['cnpj']?.toLowerCase()?.contains(query) ?? false) ||
            (mechanic['cidade']?.toLowerCase()?.contains(query) ?? false);
      }).toList();
    }
  }
  
  // Filtrar mecânicas com base no texto de pesquisa
  void _filtrarMechanics(String pesquisa) {
    setState(() {
      _searchQuery = pesquisa;
    });
    
    // Implementa debounce para busca no servidor
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == pesquisa) {
        _carregarMechanics(page: 1);
      }
    });
  }
  
  // Navegar para página específica
  Future<void> _irParaPagina(int page) async {
    if (page >= 1 && page <= _totalPages && page != _currentPage) {
      await _carregarMechanics(page: page);
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
    _carregarMechanics(page: 1);
  }
  
  // Alterar filtro de estado
  void _alterarFiltroEstado(String? estado) {
    setState(() {
      _filtroEstado = estado;
    });
    _carregarMechanics(page: 1);
  }
  
  // Alterar itens por página
  void _alterarItensPorPagina(int novoLimit) {
    setState(() {
      _itemsPerPage = novoLimit;
    });
    _carregarMechanics(page: 1);
  }
  
  // Alterar o status (ativo/inativo) de uma mecânica
  Future<void> _alterarStatusMechanic(dynamic mechanic) async {
    // Implementação será feita quando tiver os detalhes da API
    // Por enquanto, apenas simularemos a mudança localmente
    
    setState(() {
      mechanic['recebeEmail'] = !(mechanic['recebeEmail'] ?? false);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status de ${mechanic['nome']} alterado para ${mechanic['recebeEmail'] ? 'Ativo' : 'Inativo'}'),
        backgroundColor: mechanic['recebeEmail'] ? Colors.green : Colors.red,
      ),
    );
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
            'Mostrando ${_mechanics.length} de $_totalItems mecânicas',
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
                          backgroundColor: _hasPrevPage ? const Color(0xFF0C7E3D) : Colors.grey[300],
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
                    
                    // Botão próxima página
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
                              backgroundColor: _hasPrevPage ? const Color(0xFF0C7E3D) : Colors.grey[300],
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
              ? Column(
                  children: [
                    // Filtro por estado
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filtroEstado,
                        decoration: const InputDecoration(
                          labelText: 'Estado',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem<String>(value: null, child: Text('Todos')),
                          DropdownMenuItem<String>(value: 'pr', child: Text('PR')),
                          DropdownMenuItem<String>(value: 'sp', child: Text('SP')),
                          DropdownMenuItem<String>(value: 'rs', child: Text('RS')),
                          DropdownMenuItem<String>(value: 'sc', child: Text('SC')),
                        ],
                        onChanged: _alterarFiltroEstado,
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
                    // Filtro por estado
                    DropdownButtonFormField<String>(
                      value: _filtroEstado,
                      decoration: const InputDecoration(
                        labelText: 'Filtrar por estado',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem<String>(value: null, child: Text('Todos os estados')),
                        DropdownMenuItem<String>(value: 'pr', child: Text('Paraná (PR)')),
                        DropdownMenuItem<String>(value: 'sp', child: Text('São Paulo (SP)')),
                        DropdownMenuItem<String>(value: 'rs', child: Text('Rio Grande do Sul (RS)')),
                        DropdownMenuItem<String>(value: 'sc', child: Text('Santa Catarina (SC)')),
                      ],
                      onChanged: _alterarFiltroEstado,
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
                  _buildSortChip('nome', 'Nome'),
                  _buildSortChip('cidade', 'Cidade'),
                  _buildSortChip('estado', 'Estado'),
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
      selectedColor: const Color(0xFF0C7E3D).withOpacity(0.2),
      checkmarkColor: const Color(0xFF0C7E3D),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
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
        onRefresh: () => _carregarMechanics(page: _currentPage),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              const Text(
                'Gerenciar Mecânicas',
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
                  hintText: 'Buscar por nome, CNPJ, cidade ou email...',
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
                            _filtrarMechanics('');
                          },
                        )
                      : null,
                ),
                onChanged: _filtrarMechanics,
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
                        onPressed: () => _carregarMechanics(page: _currentPage),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              
              // Lista de mecânicas
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0C7E3D),
                        ),
                      )
                    : _mechanics.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty 
                                      ? 'Nenhuma mecânica encontrada'
                                      : 'Nenhuma mecânica encontrada com "${_searchQuery}"',
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
                                      _filtrarMechanics('');
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
                                  itemCount: _mechanics.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final mechanic = _mechanics[index];
                                    return _buildMechanicCard(mechanic);
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
  
  // Widget para o card de mecânica
  Widget _buildMechanicCard(dynamic mechanic) {
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Avatar da mecânica
            CircleAvatar(
              backgroundColor: const Color(0xFF0C7E3D).withOpacity(0.1),
              child: Icon(
                Icons.build,
                color: const Color(0xFF0C7E3D),
              ),
            ),
            const SizedBox(width: 12),
            
            // Informações da mecânica
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mechanic['nome'] ?? 'Nome não informado',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (mechanic['email'] != null)
                    Text(
                      mechanic['email'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (mechanic['telefone'] != null)
                    Text(
                      mechanic['telefone'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (mechanic['cidade'] != null && mechanic['estado'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${mechanic['cidade']}, ${mechanic['estado']?.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Botão de visualizar detalhes
            IconButton(
              icon: const Icon(
                Icons.visibility_outlined,
                color: Color(0xFF0C7E3D),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MechanicDetailPage(
                      mechanicId: mechanic['id'],
                    ),
                  ),
                );
              },
            ),
            
            // Status da mecânica (Ativo/Inativo)
            GestureDetector(
              onTap: () => _alterarStatusMechanic(mechanic),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (mechanic['recebeEmail'] ?? false) 
                      ? const Color(0xFF4EB699) 
                      : Colors.red.shade400,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  (mechanic['recebeEmail'] ?? false) ? 'Ativo' : 'Inativo',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}