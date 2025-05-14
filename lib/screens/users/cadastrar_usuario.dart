import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Classe modelo para veículos
class Veiculo {
  final String id;
  final String placa;
  final String modelo;
  bool selecionado;

  Veiculo({
    required this.id,
    required this.placa,
    required this.modelo,
    this.selecionado = false,
  });
}

// Nova tela para cadastro de usuário
class CadastrarUsuarioScreen extends StatefulWidget {
  const CadastrarUsuarioScreen({Key? key}) : super(key: key);

  @override
  _CadastrarUsuarioScreenState createState() => _CadastrarUsuarioScreenState();
}

class _CadastrarUsuarioScreenState extends State<CadastrarUsuarioScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _secureStorage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para os campos de texto
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController = TextEditingController();
  final TextEditingController _pesquisaVeiculoController = TextEditingController();
  
  String _funcaoSelecionada = 'supervisor'; // Valor padrão
  bool _isLoading = false;
  String? _errorMessage;
  
  // Lista de opções para o dropdown de função
  final List<String> _opcoesFuncao = ['supervisor', 'analista'];
  
  // Lista de veículos fixos (mock) - simulando uma base grande
  List<Veiculo> _todosVeiculos = [];
  List<Veiculo> _veiculosFiltrados = [];
  List<Veiculo> _veiculosSelecionados = [];
  
  @override
  void initState() {
    super.initState();
    _gerarVeiculosMock();
    _veiculosFiltrados = List.from(_todosVeiculos);
  }
  
  // Gerar veículos mock para simular uma base grande
  void _gerarVeiculosMock() {
    // Modelos de caminhões comuns
    List<String> modelos = [
      'Mercedes-Benz Actros',
      'Volvo FH',
      'Scania R450',
      'MAN TGX',
      'DAF XF',
      'Iveco Stralis',
      'Ford Cargo',
      'Volkswagen Constellation',
      'Renault T',
      'Hyundai Xcient',
    ];
    
    // Gerar 300 veículos com placas e modelos diferentes
    for (int i = 1; i <= 300; i++) {
      String modeloIndex = (i % modelos.length).toString();
      String placa = 'ABC${i.toString().padLeft(4, '0')}';
      String modelo = modelos[i % modelos.length];
      
      _todosVeiculos.add(
        Veiculo(
          id: i.toString(),
          placa: placa,
          modelo: '$modelo - $modeloIndex',
          selecionado: false,
        ),
      );
    }
  }
  
  // Filtrar veículos com base no texto de pesquisa
  void _filtrarVeiculos(String pesquisa) {
    setState(() {
      if (pesquisa.isEmpty) {
        _veiculosFiltrados = List.from(_todosVeiculos);
      } else {
        pesquisa = pesquisa.toLowerCase();
        _veiculosFiltrados = _todosVeiculos.where((veiculo) {
          return veiculo.placa.toLowerCase().contains(pesquisa) ||
              veiculo.modelo.toLowerCase().contains(pesquisa);
        }).toList();
      }
    });
  }
  
  // Alternar seleção de veículo
  void _alternarSelecaoVeiculo(Veiculo veiculo) {
    setState(() {
      // Atualizar o estado de seleção no veículo original
      int indexTodos = _todosVeiculos.indexWhere((v) => v.id == veiculo.id);
      if (indexTodos != -1) {
        _todosVeiculos[indexTodos].selecionado = !_todosVeiculos[indexTodos].selecionado;
      }
      
      // Atualizar o estado de seleção no veículo filtrado
      int indexFiltrados = _veiculosFiltrados.indexWhere((v) => v.id == veiculo.id);
      if (indexFiltrados != -1) {
        _veiculosFiltrados[indexFiltrados].selecionado = _todosVeiculos[indexTodos].selecionado;
      }
      
      // Atualizar a lista de veículos selecionados
      if (_todosVeiculos[indexTodos].selecionado) {
        if (!_veiculosSelecionados.any((v) => v.id == veiculo.id)) {
          _veiculosSelecionados.add(_todosVeiculos[indexTodos]);
        }
      } else {
        _veiculosSelecionados.removeWhere((v) => v.id == veiculo.id);
      }
    });
  }
  
  // Remover veículo da seleção
  void _removerVeiculoSelecionado(Veiculo veiculo) {
    setState(() {
      // Encontrar o veículo no array original e atualizar seu estado
      int indexTodos = _todosVeiculos.indexWhere((v) => v.id == veiculo.id);
      if (indexTodos != -1) {
        _todosVeiculos[indexTodos].selecionado = false;
      }
      
      // Atualizar na lista filtrada também
      int indexFiltrados = _veiculosFiltrados.indexWhere((v) => v.id == veiculo.id);
      if (indexFiltrados != -1) {
        _veiculosFiltrados[indexFiltrados].selecionado = false;
      }
      
      // Remover da lista de selecionados
      _veiculosSelecionados.removeWhere((v) => v.id == veiculo.id);
    });
  }
  
  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _pesquisaVeiculoController.dispose();
    super.dispose();
  }
  
  // Função para cadastrar o usuário
  Future<void> _cadastrarUsuario() async {
    // Validar o formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Verificar se as senhas conferem
    if (_senhaController.text != _confirmarSenhaController.text) {
      setState(() {
        _errorMessage = 'As senhas não conferem';
      });
      return;
    }
    
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
      
      // Preparar os dados para envio
      final Map<String, dynamic> userData = {
        'nome': _nomeController.text,
        'email': _emailController.text,
        'login': _nomeController.text, // Usando o nome como login conforme exemplo
        'senha': _senhaController.text,
        'funcao': _funcaoSelecionada,
      };
      
      // Se for supervisor, adicionar veículos selecionados
      if (_funcaoSelecionada == 'supervisor' && _veiculosSelecionados.isNotEmpty) {
        List<String> veiculosIds = _veiculosSelecionados.map((v) => v.id).toList();
        userData['veiculos'] = veiculosIds;
      }
      
      // Fazer a requisição para o endpoint
      final response = await http.post(
        Uri.parse('http://localhost:4040/api/users/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(userData),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Cadastro bem-sucedido
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário cadastrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Voltar para a tela anterior
        Navigator.pop(context);
      } else if (response.statusCode == 401) {
        // Token inválido ou expirado
        setState(() {
          _errorMessage = 'Sessão expirada, faça login novamente';
          _isLoading = false;
        });
      } else {
        // Outro erro da API
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorData['message'] ?? 'Erro ao cadastrar usuário: ${response.statusCode}';
          _isLoading = false;
        });
        print('Resposta da API com erro: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro de conexão: $e';
        _isLoading = false;
      });
      print('Erro ao cadastrar usuário: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      
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
            icon: const Icon(Icons.arrow_back, color: Colors.black54),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: const Text(
          'Cadastrar Usuário',
          style: TextStyle(color: Colors.black87),
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
      
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mensagem de erro (se houver)
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                
                // Campo Nome
                const Text(
                  'Nome',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nomeController,
                  decoration: InputDecoration(
                    hintText: 'Informe o nome do usuário',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe o nome do usuário';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Campo E-mail
                const Text(
                  'E-mail',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Informe o E-mail do usuário',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe o e-mail do usuário';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Por favor, informe um e-mail válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Campo Senha
                const Text(
                  'Senha',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _senhaController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'crie uma senha para o usuário',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, crie uma senha para o usuário';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Campo Confirme a senha
                const Text(
                  'Confirme a senha',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmarSenhaController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'confirme a senha do usuário',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, confirme a senha do usuário';
                    }
                    if (value != _senhaController.text) {
                      return 'As senhas não conferem';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Campo Função (Dropdown)
                const Text(
                  'Função',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _funcaoSelecionada,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  items: _opcoesFuncao.map((String funcao) {
                    return DropdownMenuItem<String>(
                      value: funcao,
                      child: Text(
                        funcao.substring(0, 1).toUpperCase() + funcao.substring(1),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _funcaoSelecionada = newValue;
                        
                        // Limpar seleções se mudar de supervisor para analista
                        if (newValue != 'supervisor') {
                          for (var veiculo in _todosVeiculos) {
                            veiculo.selecionado = false;
                          }
                          _veiculosSelecionados.clear();
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
                
                // Seleção de veículos (apenas para supervisores)
                if (_funcaoSelecionada == 'supervisor') ...[
                  const Text(
                    'Veículos sob responsabilidade',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Campo de pesquisa de veículos
                  TextFormField(
                    controller: _pesquisaVeiculoController,
                    decoration: InputDecoration(
                      hintText: 'Pesquisar veículos por placa ou modelo...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onChanged: _filtrarVeiculos,
                  ),
                  const SizedBox(height: 10),
                  
                  // Lista de veículos selecionados
                  if (_veiculosSelecionados.isNotEmpty) ...[
                    const Text(
                      'Veículos selecionados:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _veiculosSelecionados.map((veiculo) {
                          return Chip(
                            backgroundColor: Colors.green.shade100,
                            label: Text(
                              '${veiculo.placa} - ${veiculo.modelo}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            deleteIcon: const Icon(
                              Icons.close,
                              size: 18,
                            ),
                            onDeleted: () => _removerVeiculoSelecionado(veiculo),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  
                  // Lista de veículos filtrados
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _veiculosFiltrados.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhum veículo encontrado',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _veiculosFiltrados.length,
                            itemBuilder: (context, index) {
                              final veiculo = _veiculosFiltrados[index];
                              return ListTile(
                                dense: true,
                                title: Text(
                                  veiculo.modelo,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  'Placa: ${veiculo.placa}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                leading: Checkbox(
                                  value: veiculo.selecionado,
                                  onChanged: (bool? value) {
                                    _alternarSelecaoVeiculo(veiculo);
                                  },
                                  activeColor: const Color(0xFF0C7E3D),
                                ),
                                onTap: () => _alternarSelecaoVeiculo(veiculo),
                              );
                            },
                          ),
                  ),
                  
                  // Contador de veículos selecionados
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '${_veiculosSelecionados.length} veículos selecionados',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                
                // Botões de ação
                Row(
                  children: [
                    // Botão Cancelar
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF67E7E),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Botão Salvar
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _cadastrarUsuario,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4EB699),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Salvar',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
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
  }
}
                          