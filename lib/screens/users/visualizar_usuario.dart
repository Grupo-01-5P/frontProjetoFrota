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
  
  // Função para carregar os usuários da API
  Future<void> _carregarUsuarios() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
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
      
      // Fazer a requisição para o endpoint
      final response = await http.get(
        Uri.parse('http://localhost:4040/api/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['data'] != null && data['data'] is List) {
          final List<Usuario> usuariosCarregados = [];
          
          for (var usuarioJson in data['data']) {
            usuariosCarregados.add(Usuario.fromJson(usuarioJson));
          }
          
          setState(() {
            _usuarios = usuariosCarregados;
            _usuariosFiltrados = List.from(_usuarios);
            _isLoading = false;
          });
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
  
  // Filtrar usuários com base no texto de pesquisa
  void _filtrarUsuarios(String pesquisa) {
    setState(() {
      if (pesquisa.isEmpty) {
        _usuariosFiltrados = List.from(_usuarios);
      } else {
        pesquisa = pesquisa.toLowerCase();
        _usuariosFiltrados = _usuarios.where((usuario) {
          return usuario.nome.toLowerCase().contains(pesquisa) ||
              usuario.email.toLowerCase().contains(pesquisa) ||
              usuario.login.toLowerCase().contains(pesquisa);
        }).toList();
      }
    });
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
    // Recarregar a lista de usuários
    _carregarUsuarios();
  }
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
                  'Buscar usuário',
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
                    // Implementar ordenação
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Campo de pesquisa
            TextField(
              controller: _pesquisaController,
              decoration: InputDecoration(
                hintText: 'Digite o nome do usuario',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: _filtrarUsuarios,
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
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
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
                      ? const Center(
                          child: Text(
                            'Nenhum usuário encontrado',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _usuariosFiltrados.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final usuario = _usuariosFiltrados[index];
                            return _buildUsuarioCard(usuario);
                          },
                        ),
            ),
          ],
        ),
      ),
      
      // Botão flutuante para adicionar novo usuário
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar para a tela de cadastro de usuário
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CadastrarUsuarioScreen()),
          );
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
            // Informações do usuário
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        usuario.nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8)
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    usuario.funcao.substring(0, 1).toUpperCase() + usuario.funcao.substring(1),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            
            // Botão de editar
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: Color(0xFF0C7E3D),
              ),
              onPressed: () => _editarUsuario(context, usuario),
            ),
            
            // Status do usuário (Ativo/Inativo)
            GestureDetector(
              onTap: () => _alterarStatusUsuario(usuario),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: usuario.ativo ? const Color(0xFF4EB699) : Colors.red.shade400,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  usuario.ativo ? 'Ativo' : 'Inativo',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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