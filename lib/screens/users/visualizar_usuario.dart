import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:front_projeto_flutter/screens/users/cadastrar_usuario.dart';
import 'package:front_projeto_flutter/screens/users/editar_usuario.dart';
import 'package:front_projeto_flutter/models/usuario.dart';

class VisualizarUsuariosScreen extends StatefulWidget {
  const VisualizarUsuariosScreen({Key? key}) : super(key: key);

  @override
  _VisualizarUsuariosScreenState createState() => _VisualizarUsuariosScreenState();
}

class _VisualizarUsuariosScreenState extends State<VisualizarUsuariosScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _secureStorage = const FlutterSecureStorage();
  final TextEditingController _pesquisaController = TextEditingController();
  
  bool _isLoading = true;
  String? _errorMessage;
  List<Usuario> _usuarios = [];
  List<Usuario> _usuariosFiltrados = [];
  
  // Variáveis de paginação
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalItems = 0;
  int _totalPages = 0;
  bool _hasNextPage = false;
  bool _hasPrevPage = false;
  
  // Variáveis de filtro e ordenação
  String? _filtroFuncao;
  String _sortField = 'nome';
  String _sortOrder = 'asc';
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _carregarUsuarios();
  }
  
  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }
  
  // Função para carregar os usuários da API com paginação
  Future<void> _carregarUsuarios({int? page, bool showLoading = true}) async {
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
      
      // Adicionar filtro de função se selecionado
      if (_filtroFuncao != null && _filtroFuncao!.isNotEmpty) {
        queryParams['funcao'] = _filtroFuncao!;
      }
      
      final uri = Uri.parse('http://localhost:4040/api/users').replace(
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
          final List<Usuario> usuariosCarregados = [];
          
          for (var usuarioJson in data['data']) {
            usuariosCarregados.add(Usuario.fromJson(usuarioJson));
          }
          
          // Extrair informações de paginação da resposta
          final meta = data['meta'];
          
          setState(() {
            _usuarios = usuariosCarregados;
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
          _errorMessage = 'Erro ao carregar usuários: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro de conexão: $e';
        _isLoading = false;
      });
      print('Erro ao carregar usuários: $e');
    }
  }
  
  // Aplicar filtro de busca local
  void _aplicarFiltroBusca() {
    if (_searchQuery.isEmpty) {
      _usuariosFiltrados = List.from(_usuarios);
    } else {
      final query = _searchQuery.toLowerCase();
      _usuariosFiltrados = _usuarios.where((usuario) {
        return usuario.nome.toLowerCase().contains(query) ||
            usuario.email.toLowerCase().contains(query) ||
            usuario.login.toLowerCase().contains(query);
      }).toList();
    }
  }
  
  // Filtrar usuários com base no texto de pesquisa (busca local)
  void _filtrarUsuarios(String pesquisa) {
    setState(() {
      _searchQuery = pesquisa;
      _aplicarFiltroBusca();
    });
  }
  
  // Navegar para página específica
  Future<void> _irParaPagina(int page) async {
    if (page >= 1 && page <= _totalPages && page != _currentPage) {
      await _carregarUsuarios(page: page);
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
    _carregarUsuarios(page: 1);
  }
  
  // Alterar filtro de função
  void _alterarFiltroFuncao(String? funcao) {
    setState(() {
      _filtroFuncao = funcao;
    });
    _carregarUsuarios(page: 1);
  }
  
  // Alterar itens por página
  void _alterarItensPorPagina(int novoLimit) {
    setState(() {
      _itemsPerPage = novoLimit;
    });
    _carregarUsuarios(page: 1);
  }
  
  // Alterar o status (ativo/inativo) de um usuário
  Future<void> _alterarStatusUsuario(Usuario usuario) async {
    // Implementação será feita quando tiver os detalhes da API
    // Por enquanto, apenas simularemos a mudança localmente
    
    setState(() {
      usuario.ativo = !usuario.ativo;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status de ${usuario.nome} alterado para ${usuario.ativo ? 'Ativo' : 'Inativo'}'),
        backgroundColor: usuario.ativo ? Colors.green : Colors.red,
      ),
    );
  }
  
  void _editarUsuario(BuildContext context, Usuario usuario) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarUsuarioScreen(usuario: usuario),
      ),
    );
    
    // Se retornou true, significa que houve alteração e precisamos recarregar a lista
    if (result == true) {
      // Recarregar a página atual
      _carregarUsuarios(page: _currentPage);
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
            'Mostrando ${_usuarios.length} de $_totalItems usuários (Página $_currentPage de $_totalPages)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          
          // Controles de navegação
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Botão página anterior
              ElevatedButton.icon(
                onPressed: _hasPrevPage ? () => _irParaPagina(_currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Anterior'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasPrevPage ? const Color(0xFF0C7E3D) : Colors.grey[300],
                  foregroundColor: _hasPrevPage ? Colors.white : Colors.grey[600],
                ),
              ),
              
              // Indicador de páginas
              if (_totalPages <= 7)
                Row(
                  children: List.generate(_totalPages, (index) {
                    final pageNum = index + 1;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: ElevatedButton(
                        onPressed: pageNum != _currentPage ? () => _irParaPagina(pageNum) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pageNum == _currentPage 
                              ? const Color(0xFF0C7E3D) 
                              : Colors.grey[200],
                          foregroundColor: pageNum == _currentPage 
                              ? Colors.white 
                              : Colors.black87,
                          minimumSize: const Size(40, 40),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(pageNum.toString()),
                      ),
                    );
                  }),
                )
              else
                Text(
                  'Página $_currentPage',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              
              // Botão próxima página
              ElevatedButton.icon(
                onPressed: _hasNextPage ? () => _irParaPagina(_currentPage + 1) : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Próxima'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasNextPage ? const Color(0xFF0C7E3D) : Colors.grey[300],
                  foregroundColor: _hasNextPage ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
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
          Row(
            children: [
              // Filtro por função
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filtroFuncao,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por função',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem<String>(value: null, child: Text('Todas as funções')),
                    DropdownMenuItem<String>(value: 'analista', child: Text('Analista')),
                    DropdownMenuItem<String>(value: 'supervisor', child: Text('Supervisor')),
                  ],
                  onChanged: _alterarFiltroFuncao,
                ),
              ),
              const SizedBox(width: 16),
              
              // Itens por página
              Expanded(
                child: DropdownButtonFormField<int>(
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
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Ordenação
          Row(
            children: [
              const Text(
                'Ordenar por:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    _buildSortChip('nome', 'Nome'),
                    _buildSortChip('email', 'Email'),
                    _buildSortChip('funcao', 'Função'),
                  ],
                ),
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
          Text(label),
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
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      
      drawer: CustomDrawer(
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
        onRefresh: () => _carregarUsuarios(page: _currentPage),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              const Text(
                'Gerenciar Usuários',
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
                  hintText: 'Buscar por nome, email ou login...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: _filtrarUsuarios,
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
                        onPressed: () => _carregarUsuarios(page: _currentPage),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              
              // Lista de usuários
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0C7E3D),
                        ),
                      )
                    : _usuariosFiltrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty 
                                      ? 'Nenhum usuário encontrado'
                                      : 'Nenhum usuário encontrado com "${_searchQuery}"',
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
                                      _filtrarUsuarios('');
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
                                  itemCount: _usuariosFiltrados.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final usuario = _usuariosFiltrados[index];
                                    return _buildUsuarioCard(usuario);
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
      
      // Botão flutuante para adicionar novo usuário
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CadastrarUsuarioScreen()),
          );
          
          // Se retornou true, recarregar a lista
          if (result == true) {
            _carregarUsuarios(page: _currentPage);
          }
        },
        backgroundColor: const Color(0xFF0C7E3D),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
  
  // Widget para o card de usuário
  Widget _buildUsuarioCard(Usuario usuario) {
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
            // Avatar do usuário
            CircleAvatar(
              backgroundColor: const Color(0xFF0C7E3D).withOpacity(0.1),
              child: Text(
                usuario.nome.isNotEmpty ? usuario.nome[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Color(0xFF0C7E3D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Informações do usuário
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario.nome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    usuario.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: usuario.funcao == 'analista' 
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      usuario.funcao.substring(0, 1).toUpperCase() + usuario.funcao.substring(1),
                      style: TextStyle(
                        fontSize: 12,
                        color: usuario.funcao == 'analista' ? Colors.blue : Colors.purple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Botão de editar
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF0C7E3D),
              ),
              onPressed: () => _editarUsuario(context, usuario),
            ),
            
            // Status do usuário (Ativo/Inativo)
            GestureDetector(
              onTap: () => _alterarStatusUsuario(usuario),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: usuario.ativo ? const Color(0xFF4EB699) : Colors.red.shade400,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  usuario.ativo ? 'Ativo' : 'Inativo',
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