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
  final TextEditingController _searchController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> mechanics = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 1;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchMechanics(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchMechanics({bool reset = false}) async {
    if (isLoading || isLoadingMore) return;
    setState(() {
      if (reset) {
        isLoading = true;
        mechanics.clear();
        currentPage = 1;
        hasMore = true;
      } else {
        isLoadingMore = true;
      }
      error = null;
    });
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse(
          'http://localhost:4040/api/garage?_page=$currentPage&_limit=10&_sort=nome&_order=asc',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> newMechanics = data['oficinas'];
        setState(() {
          mechanics.addAll(newMechanics);
          hasMore = newMechanics.length == 10;
          if (reset) isLoading = false;
          isLoadingMore = false;
          currentPage++;
        });
      } else {
        setState(() {
          error = 'Erro ao buscar mecânicas (${response.statusCode})';
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Erro de conexão: $e';
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        hasMore &&
        !isLoadingMore) {
      fetchMechanics();
    }
  }

  List<dynamic> get filteredMechanics {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return mechanics;
    return mechanics.where((m) {
      return m['nome'].toLowerCase().contains(query) ||
          m['cnpj'].toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: const CustomDrawer(useCustomIcons: false),
      body: Stack(
        children: [
          // Topo customizado (Drawer e Notificação)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botão Drawer
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
                  // Botão Notificação
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications,
                          color: Colors.black,
                        ),
                        onPressed: () {},
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Conteúdo principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 80,
                left: 12,
                right: 12,
                bottom: 0,
              ),
              child: Column(
                children: [
                  // Busca e filtro
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Buscar mecânicas',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.sort,
                                  color: Colors.black87,
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                          TextFormField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Digite o nome ou CNPJ, etc...',
                              filled: true,
                              fillColor: const Color(0xFFF8F8F8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Lista de mecânicas
                  Expanded(
                    child:
                        isLoading && mechanics.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : error != null
                            ? Center(
                              child: Text(
                                error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                            : filteredMechanics.isEmpty
                            ? const Center(
                              child: Text('Nenhuma mecânica encontrada.'),
                            )
                            : NotificationListener<ScrollNotification>(
                              onNotification: (scrollInfo) {
                                if (scrollInfo.metrics.pixels >=
                                        scrollInfo.metrics.maxScrollExtent -
                                            200 &&
                                    hasMore &&
                                    !isLoadingMore) {
                                  fetchMechanics();
                                }
                                return false;
                              },
                              child: ListView.separated(
                                controller: _scrollController,
                                itemCount:
                                    filteredMechanics.length +
                                    (isLoadingMore ? 1 : 0),
                                separatorBuilder:
                                    (context, index) =>
                                        const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  if (index == filteredMechanics.length &&
                                      isLoadingMore) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  final mechanic = filteredMechanics[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => MechanicDetailPage(
                                                mechanicId: mechanic['id'],
                                              ),
                                        ),
                                      );
                                    },
                                    child: Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Coluna principal
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        mechanic['nome'],
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Icon(
                                                        Icons.open_in_new,
                                                        color: Colors.green,
                                                        size: 18,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    mechanic['telefone'],
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Text(
                                                    mechanic['email'],
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Cidade/UF e status
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${mechanic['cidade']}, ${mechanic['estado']}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        mechanic['recebeEmail'] ==
                                                                true
                                                            ? const Color(
                                                              0xFF23C882,
                                                            )
                                                            : Colors.red[300],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    mechanic['recebeEmail'] ==
                                                            true
                                                        ? 'Ativo'
                                                        : 'Inativo',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
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
    );
  }
}
