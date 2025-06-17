import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'viewInoperative.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart';

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

      print('URL: http://localhost:4040/inoperative?_page=$currentPage&_limit=10');

      final response = await http.get(
        Uri.parse('http://localhost:4040/inoperative?_page=$currentPage&_limit=10'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Status code: ${response.statusCode}');
      print('Resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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
      print('Erro na requisição: $e');
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

  Future<void> handleVehicleSelection(dynamic veiculo) async {
    try {
      print('Selecionando veículo: ${veiculo.toString()}');
      setState(() {
        isLoading = true;
      });

      if (veiculo == null || veiculo['id'] == null) {
        print('Erro: Veículo ou ID do veículo é nulo');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao selecionar veículo'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final token = await getValidToken();
      if (token == null) return;

      final veiculoId = veiculo['id'] as int;
      print('Verificando se veículo $veiculoId já está inoperante');
      
      // Primeiro, tenta buscar um inoperante existente
      final existingInoperante = await getExistingInoperante(veiculoId);
      
      if (existingInoperante != null) {
        print('Inoperante existente encontrado: ${existingInoperante['id']}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewInoperative(
              inoperanteId: existingInoperante['id'] as int,
            ),
          ),
        );
        return;
      }

      print('Criando novo inoperante para veículo $veiculoId');
      final response = await http.post(
        Uri.parse('http://localhost:4040/inoperative/vehicle/$veiculoId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Status code da criação: ${response.statusCode}');
      print('Resposta da criação: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final inoperanteId = data['data']['id'] as int;
        print('Inoperante criado com ID: $inoperanteId');
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewInoperative(
              inoperanteId: inoperanteId,
            ),
          ),
        );
      } else if (response.statusCode == 400) {
        // Se já existe um inoperante ativo
        final data = json.decode(response.body);
        if (data['data']?['id'] != null) {
          print('Inoperante já existe, navegando para ele: ${data['data']['id']}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewInoperative(
                inoperanteId: data['data']['id'] as int,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Erro ao processar veículo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (response.statusCode == 401) {
        await _secureStorage.delete(key: 'auth_token');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sessão expirada. Por favor, faça login novamente.'),
            backgroundColor: Colors.red,
          ),
        );
        // TODO: Redirecionar para tela de login
      } else {
        throw Exception('Falha ao processar veículo');
      }
    } catch (e) {
      print('Erro ao selecionar veículo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao processar veículo: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar inoperantes baseado na busca
    final filteredInoperantes =
        searchQuery != null
            ? inoperantes
                .where(
                  (inop) => inop['veiculo']['placa'].toString().contains(
                    searchQuery!,
                  ),
                )
                .toList()
            : inoperantes;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color.fromARGB(250, 250, 250, 250),
      drawer: CustomDrawer(
        headerColor: const Color(0xFF148553),
        useCustomIcons: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
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
                ],
              ),
              const SizedBox(height: 20),

              // Card de Busca
              Card(
                color: Colors.white,
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Text(
                              "Buscar veículo",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconTheme(
                            data: const IconThemeData(
                              color: Colors.black,
                              size: 28,
                            ),
                            child: Icon(Icons.sort_by_alpha),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        onChanged: filterInoperantes,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFEEEEEE),
                          hintText: "Digite a placa do veículo",
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Lista de Veículos
              Expanded(
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredInoperantes.isEmpty
                        ? const Center(
                          child: Text('Nenhum veículo inoperante encontrado'),
                        )
                        : ListView.builder(
                          itemCount: filteredInoperantes.length + (hasMoreItems ? 1 : 0),
                          controller: _scrollController,
                          itemBuilder: (context, index) {
                            if (index == filteredInoperantes.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final inoperante = filteredInoperantes[index];
                            final veiculo = inoperante['veiculo'];
                            final oficina = inoperante['oficina'];
                            final supervisor = inoperante['supervisor'];

                            return InkWell(
                              onTap: () async {
                                print('Card clicado. Dados do veículo:');
                                print(veiculo.toString());
                                await handleVehicleSelection(veiculo);
                              },
                              child: Card(
                                color: Colors.white,
                                elevation: 8,
                                shadowColor: Colors.black.withOpacity(0.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            veiculo['placa'] ?? 'Sem placa',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 20,
                                            ),
                                          ),
                                          Text(
                                            "${veiculo['marca'] ?? ''} ${veiculo['modelo'] ?? ''} ${veiculo['anoModelo'] ?? ''}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        veiculo['cor'] ?? 'Cor não informada',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        veiculo['empresa'] ?? 'Empresa não informada',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            veiculo['departamento'] ?? 'Departamento não informado',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6,
                                              horizontal: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFAC26).withOpacity(0.7),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              inoperante['status']?.toUpperCase() ?? "INOPERANTE",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (oficina != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          "Oficina: ${oficina['cidade'] ?? ''} - ${oficina['estado'] ?? ''}",
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                      if (supervisor != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          "Supervisor: ${supervisor['nome'] ?? 'Não atribuído'} (${supervisor['email'] ?? 'Sem email'})",
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ],
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
      bottomNavigationBar: SafeArea(
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.7),
                  blurRadius: 20.0,
                  spreadRadius: 5.0,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: 2,
              onTap: (index) {
                if (index == 0) {
                  // Manutenções
                } else if (index == 1) {
                  // Orçamentos
                }
              },
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.black,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              items: [
                BottomNavigationBarItem(
                  icon: SizedBox(
                    width: 30,
                    height: 30,
                    child: Image.asset('lib/assets/images/iconManutencoes.png'),
                  ),
                  label: 'Manutenções',
                ),
                BottomNavigationBarItem(
                  icon: SizedBox(
                    width: 30,
                    height: 30,
                    child: Image.asset('lib/assets/images/iconTerceirize.png'),
                  ),
                  label: 'Orçamentos',
                ),
                BottomNavigationBarItem(
                  icon: SizedBox(
                    width: 30,
                    height: 30,
                    child: Image.asset('lib/assets/images/iconInoperantes.png'),
                  ),
                  label: 'Inoperantes',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
