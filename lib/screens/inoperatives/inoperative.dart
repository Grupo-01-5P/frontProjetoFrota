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

  @override
  void initState() {
    super.initState();
    // Comentando chamada da API e usando dados estáticos
    // fetchInoperantes();
    carregarDadosEstaticos();
  }

  void carregarDadosEstaticos() {
    // Dados estáticos para teste
    inoperantes = [
      {
        "id": 1,
        "veiculo": {
          "placa": "ABC1234",
          "marca": "Toyota",
          "modelo": "Corolla",
          "anoModelo": 2023,
          "cor": "Prata",
          "empresa": "Empresa XYZ",
          "departamento": "Frota Operacional",
        },
      },
      {
        "id": 2,
        "veiculo": {
          "placa": "DEF5678",
          "marca": "Honda",
          "modelo": "Civic",
          "anoModelo": 2022,
          "cor": "Preto",
          "empresa": "Empresa ABC",
          "departamento": "Vendas",
        },
      },
      {
        "id": 3,
        "veiculo": {
          "placa": "GHI9012",
          "marca": "Volkswagen",
          "modelo": "Golf",
          "anoModelo": 2023,
          "cor": "Branco",
          "empresa": "Empresa 123",
          "departamento": "Administrativo",
        },
      },
    ];
    setState(() {
      isLoading = false;
    });
  }

  // Comentando a função de chamada da API
  /*
  Future<void> fetchInoperantes() async {
    try {
      final token = await _secureStorage.read(key: 'token');
      final response = await http.get(
        Uri.parse('http://localhost:4040/inoperative/inoperative'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          inoperantes = data['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }
  */

  void filterInoperantes(String query) {
    setState(() {
      searchQuery = query.isEmpty ? null : query.toUpperCase();
    });
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
                          itemCount: filteredInoperantes.length,
                          itemBuilder: (context, index) {
                            final inoperante = filteredInoperantes[index];
                            final veiculo = inoperante['veiculo'];

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ViewInoperative(
                                          inoperanteId: inoperante['id'] as int,
                                        ),
                                  ),
                                );
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            veiculo['placa'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 20,
                                            ),
                                          ),
                                          Text(
                                            "${veiculo['marca']} ${veiculo['modelo']} ${veiculo['anoModelo']}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        veiculo['cor'],
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        veiculo['empresa'],
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            veiculo['departamento'],
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
                                              color: const Color(
                                                0xFFFFAC26,
                                              ).withOpacity(0.7),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Text(
                                              "Inoperante",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
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
