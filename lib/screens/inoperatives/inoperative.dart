import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'viewInoperative.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart';
import 'package:front_projeto_flutter/components/custom_bottom_navigation.dart';

// Definindo constantes de estilo
const kPrimaryColor = Color(0xFF148553);
const kSecondaryColor = Color(0xFFFFAC26);
const kBackgroundColor = Color(0xFFF5F5F5);
const kCardShadow = BoxShadow(
  color: Color(0x1A000000),
  blurRadius: 10,
  offset: Offset(0, 4),
  spreadRadius: 0,
);

// Cores para os status
const kStatusGreen = Color(0xFF28A745);
const kStatusRed = Color(0xFFDC3545);

class Inoperative extends StatefulWidget {
  const Inoperative({super.key});

  @override
  State<Inoperative> createState() => _InoperativeState();
}

class _InoperativeState extends State<Inoperative> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  List<dynamic> inoperantes = [];
  bool isLoading = true;
  String? searchQuery;
  int currentPage = 1;
  bool hasMoreItems = true;
  final ScrollController _scrollController = ScrollController();
  String selectedFilter = 'todos';

  @override
  void initState() {
    super.initState();
    fetchInoperantes();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!isLoading && hasMoreItems) {
        currentPage++;
        fetchInoperantes(isLoadMore: true);
      }
    }
  }

  Future<String?> getValidToken() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sessão expirada. Por favor, faça login novamente.'),
            backgroundColor: Colors.red,
          ),
        );
        // TODO: Redirecionar para tela de login
        return null;
      }
      return token;
    } catch (e) {
      print('Erro ao buscar token: $e');
      return null;
    }
  }

  Future<void> fetchInoperantes({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final token = await getValidToken();
      if (token == null) return;

      print('\n=== BUSCANDO MANUTENÇÕES ===');
      print('URL: http://localhost:4040/inoperative?_page=$currentPage&_limit=10');

      final response = await http.get(
        Uri.parse('http://localhost:4040/inoperative?_page=$currentPage&_limit=10'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('\n=== RESPOSTA DA LISTAGEM ===');
      print('Status code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('\n=== DADOS RECEBIDOS ===');
        print('Total de itens: ${data['meta']['totalItems']}');
        print('Página atual: ${data['meta']['currentPage']}');
        print('Total de páginas: ${data['meta']['totalPages']}');
        print('\n=== MANUTENÇÕES RECEBIDAS ===');
        for (var manutencao in data['data']) {
          print('\nManutenção ID: ${manutencao['id']}');
          print('Status: ${manutencao['status']}');
          print('Veículo: ${manutencao['veiculo']['marca']} ${manutencao['veiculo']['modelo']} - Placa: ${manutencao['veiculo']['placa']}');
          if (manutencao['oficina'] != null) {
            print('Oficina: ${manutencao['oficina']['nome']} - ${manutencao['oficina']['cidade']}/${manutencao['oficina']['estado']}');
          }
        }

        setState(() {
          if (isLoadMore) {
            inoperantes.addAll(data['data']);
          } else {
            inoperantes = data['data'];
          }
          hasMoreItems = data['meta']['hasNextPage'];
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          isLoading = false;
        });
        await _secureStorage.delete(key: 'auth_token');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sessão expirada. Por favor, faça login novamente.'),
            backgroundColor: Colors.red,
          ),
        );
        // TODO: Redirecionar para tela de login
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar veículos inoperantes: ${response.statusCode}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Tentar Novamente',
              textColor: Colors.white,
              onPressed: () {
                if (!isLoadMore) {
                  currentPage = 1;
                }
                fetchInoperantes(isLoadMore: isLoadMore);
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('\n=== ERRO NA LISTAGEM ===');
      print('Erro: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar dados: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Tentar Novamente',
            textColor: Colors.white,
            onPressed: () {
              if (!isLoadMore) {
                currentPage = 1;
              }
              fetchInoperantes(isLoadMore: isLoadMore);
            },
          ),
        ),
      );
    }
  }

  void filterInoperantes(String query) {
    setState(() {
      searchQuery = query.isEmpty ? null : query.toUpperCase();
    });
  }

  Future<int?> createInoperante(int veiculoId) async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro de autenticação. Por favor, faça login novamente.'),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }

      final response = await http.post(
        Uri.parse('http://localhost:4040/inoperative/vehicle/$veiculoId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data']['id'] as int;
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sessão expirada. Por favor, faça login novamente.'),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      } else {
        throw Exception('Falha ao criar inoperante');
      }
    } catch (e) {
      print('Erro ao criar inoperante: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao criar inoperante. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> getExistingInoperante(int veiculoId) async {
    try {
      final token = await getValidToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('http://localhost:4040/inoperative/check/$veiculoId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Status code da verificação: ${response.statusCode}');
      print('Resposta da verificação: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else if (response.statusCode == 401) {
        await _secureStorage.delete(key: 'auth_token');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sessão expirada. Por favor, faça login novamente.'),
            backgroundColor: Colors.red,
          ),
        );
        // TODO: Redirecionar para tela de login
      }
      
      return null;
    } catch (e) {
      print('Erro ao verificar inoperante: $e');
      return null;
    }
  }

  Future<void> handleVehicleSelection(dynamic manutencao) async {
    try {
      print('\n=== SELEÇÃO DE MANUTENÇÃO ===');
      print('Dados completos da manutenção:');
      print(json.encode(manutencao));
      
      setState(() {
        isLoading = true;
      });

      if (manutencao == null || manutencao['id'] == null) {
        print('\n=== ERRO: DADOS INVÁLIDOS ===');
        print('Manutenção recebida: $manutencao');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao selecionar manutenção'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final token = await getValidToken();
      if (token == null) return;

      final manutencaoId = manutencao['id'] as int;
      print('\n=== VERIFICANDO MANUTENÇÃO ===');
      print('ID da Manutenção: $manutencaoId');
      print('URL: http://localhost:4040/inoperative/check/maintenance/$manutencaoId');
      
      // Primeiro, verifica se já existe um inoperante para esta manutenção
      final response = await http.get(
        Uri.parse('http://localhost:4040/inoperative/check/maintenance/$manutencaoId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('\n=== RESPOSTA DA VERIFICAÇÃO ===');
      print('Status code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('\n=== DADOS DA VERIFICAÇÃO ===');
        print('Existe inoperante: ${data['exists']}');
        print('Elegível: ${data['isEligible']}');
        print('Mensagem: ${data['message']}');
        print('Dados: ${data['data']}');
        
        // Se existe um inoperante
        if (data['exists'] == true && data['data'] != null) {
          print('\n=== INOPERANTE ENCONTRADO ===');
          print('ID do Inoperante: ${data['data']['id']}');
          print('Fase Atual: ${data['data']['faseAtual']}');
          
          // Busca os detalhes do inoperante
          final inoperanteId = data['data']['id'] as int;
          final phaseResponse = await http.get(
            Uri.parse('http://localhost:4040/inoperative/$inoperanteId/phase'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          print('\n=== RESPOSTA DAS FASES ===');
          print('Status code: ${phaseResponse.statusCode}');
          print('Body: ${phaseResponse.body}');

          if (phaseResponse.statusCode == 200) {
            final phaseData = json.decode(phaseResponse.body);
            // Navega para a visualização do inoperante com os dados das fases
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewInoperative(
                  inoperanteId: inoperanteId,
                  initialPhaseData: phaseData['data'],
                ),
              ),
            );
          } else {
            throw Exception('Falha ao buscar fases do inoperante');
          }
          return;
        }

        // Se não tem inoperante mas a manutenção é elegível
        if (data['isEligible'] == true) {
          print('\n=== CRIANDO NOVO INOPERANTE ===');
          print('URL: http://localhost:4040/inoperative/maintenance/$manutencaoId');
          
          final createResponse = await http.post(
            Uri.parse('http://localhost:4040/inoperative/maintenance/$manutencaoId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          print('\n=== RESPOSTA DA CRIAÇÃO ===');
          print('Status code: ${createResponse.statusCode}');
          print('Headers: ${createResponse.headers}');
          print('Body: ${createResponse.body}');

          if (createResponse.statusCode == 201) {
            final createData = json.decode(createResponse.body);
            print('\n=== INOPERANTE CRIADO ===');
            print('ID do novo inoperante: ${createData['data']['id']}');
            print('Dados completos: ${json.encode(createData)}');
            
            // Busca as fases do novo inoperante
            final newInoperanteId = createData['data']['id'] as int;
            final newPhaseResponse = await http.get(
              Uri.parse('http://localhost:4040/inoperative/$newInoperanteId/phase'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            );

            if (newPhaseResponse.statusCode == 200) {
              final newPhaseData = json.decode(newPhaseResponse.body);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewInoperative(
                    inoperanteId: newInoperanteId,
                    initialPhaseData: newPhaseData['data'],
                  ),
                ),
              );
            } else {
              throw Exception('Falha ao buscar fases do novo inoperante');
            }
          } else {
            final errorData = json.decode(createResponse.body);
            print('\n=== ERRO NA CRIAÇÃO ===');
            print('Erro: ${errorData['message']}');
            throw Exception(errorData['message'] ?? 'Falha ao processar manutenção');
          }
        } else {
          print('\n=== MANUTENÇÃO NÃO ELEGÍVEL ===');
          print('Mensagem: ${data['message']}');
          
          // Verifica o status da manutenção para mostrar uma mensagem mais específica
          final status = manutencao['status'] as String?;
          String mensagem = data['message'] ?? 'Manutenção não elegível para criar inoperante';
          
          if (status == 'concluída') {
            mensagem = 'Esta manutenção já foi concluída. Não é possível criar ou modificar inoperantes para manutenções concluídas.';
          } else if (status == 'reprovada') {
            mensagem = 'Esta manutenção foi reprovada. Não é possível criar inoperantes para manutenções reprovadas.';
          } else if (status == 'pendente') {
            mensagem = 'Esta manutenção ainda está pendente de aprovação. Somente manutenções aprovadas ou em andamento podem ter inoperantes.';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensagem),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else if (response.statusCode == 401) {
        print('\n=== ERRO DE AUTENTICAÇÃO ===');
        await _secureStorage.delete(key: 'auth_token');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sessão expirada. Por favor, faça login novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        print('\n=== ERRO NA VERIFICAÇÃO ===');
        print('Status code: ${response.statusCode}');
        print('Body: ${response.body}');
        throw Exception('Falha ao verificar status da manutenção');
      }
    } catch (e) {
      print('\n=== ERRO GERAL ===');
      print('Erro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao processar manutenção: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Função para determinar o texto de exibição do status
  String getStatusText(String? status) {
    if (status == null) return "INOPERANTE";
    
    switch (status.toLowerCase()) {
      case 'aprovada':
        return "INOPERANTE";
      default:
        return status.toUpperCase();
    }
  }

  // Função para determinar a cor do status
  Color getStatusColor(String? status) {
    if (status == null) return kStatusRed;
    
    switch (status.toLowerCase()) {
      case 'concluida':
      case 'concluída':
        return kStatusGreen;
      case 'aprovada':
      case 'inoperante':
      default:
        return kStatusRed;
    }
  }

  // Função para determinar a cor de fundo do status
  Color getStatusBackgroundColor(String? status) {
    if (status == null) return kStatusRed.withOpacity(0.1);
    
    switch (status.toLowerCase()) {
      case 'concluida':
      case 'concluída':
        return kStatusGreen.withOpacity(0.1);
      case 'aprovada':
      case 'inoperante':
      default:
        return kStatusRed.withOpacity(0.1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredInoperantes = inoperantes.where((inop) {
      bool matchesSearch = searchQuery == null || 
          inop['veiculo']['placa'].toString().contains(searchQuery!);
      
      bool matchesFilter = selectedFilter == 'todos' ||
          (selectedFilter == 'inoperantes' && 
              (inop['status'] == null || inop['status'].toLowerCase() == 'aprovada')) ||
          (selectedFilter == 'concluidos' && 
              (inop['status']?.toLowerCase() == 'concluida' || 
               inop['status']?.toLowerCase() == 'concluída'));
      
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kBackgroundColor,
      drawer: CustomDrawer(
        headerColor: kPrimaryColor,
        useCustomIcons: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com Menu e Título
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [kCardShadow],
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
                  const SizedBox(width: 20),
                ],
              ),
              const SizedBox(height: 24),

              // Card de Busca
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [kCardShadow],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Buscar veículo",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: filterInoperantes,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        hintText: "Digite a placa do veículo",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botões de Filtro
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterButton(
                      text: "Todos",
                      isSelected: selectedFilter == 'todos',
                      onTap: () {
                        setState(() {
                          selectedFilter = 'todos';
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    FilterButton(
                      text: "Inoperantes",
                      isSelected: selectedFilter == 'inoperantes',
                      onTap: () {
                        setState(() {
                          selectedFilter = 'inoperantes';
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    FilterButton(
                      text: "Concluídos",
                      isSelected: selectedFilter == 'concluidos',
                      onTap: () {
                        setState(() {
                          selectedFilter = 'concluidos';
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Lista de Veículos
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                        ),
                      )
                    : filteredInoperantes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.car_repair,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhum veículo inoperante encontrado',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredInoperantes.length + (hasMoreItems ? 1 : 0),
                            controller: _scrollController,
                            itemBuilder: (context, index) {
                              if (index == filteredInoperantes.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                                    ),
                                  ),
                                );
                              }

                              final inoperante = filteredInoperantes[index];
                              final veiculo = inoperante['veiculo'];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: InkWell(
                                  onTap: () async {
                                    await handleVehicleSelection(inoperante);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [kCardShadow],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: kPrimaryColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  veiculo['placa'] ?? 'Sem placa',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                    color: kPrimaryColor,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: getStatusBackgroundColor(inoperante['status']),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  getStatusText(inoperante['status']),
                                                  style: TextStyle(
                                                    color: getStatusColor(inoperante['status']),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            "${veiculo['marca'] ?? ''} ${veiculo['modelo'] ?? ''} ${veiculo['anoModelo'] ?? ''}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF2D2D2D),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.palette_outlined,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                veiculo['cor'] ?? 'Cor não informada',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.business_outlined,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                veiculo['empresa'] ?? 'Empresa não informada',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.domain_outlined,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                veiculo['departamento'] ?? 'Departamento não informado',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            // Manutenções
          } else if (index == 1) {
            // Orçamentos
          }
        },
      ),
    );
  }
}

// Widget do botão de filtro
class FilterButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterButton({
    Key? key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: kPrimaryColor,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : kPrimaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
