import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart';
import 'package:front_projeto_flutter/screens/products/addNewProduct.dart';
import 'package:front_projeto_flutter/screens/products/editProduct.dart';

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({Key? key}) : super(key: key);

  @override
  _ProdutosScreenState createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  List<dynamic> produtos = [];
  bool isLoading = true;
  String? searchQuery;

  @override
  void initState() {
    super.initState();
    fetchProdutos();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recarrega os produtos quando a tela for retomada
    fetchProdutos();
  }

  Future<void> fetchProdutos() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('http://localhost:4040/api/products'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          produtos = data['data'];
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

  void filterProdutos(String query) {
    setState(() {
      searchQuery = query.isEmpty ? null : query.toUpperCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredProdutos =
        searchQuery != null
            ? produtos
                .where(
                  (prod) => prod['nome'].toString().toUpperCase().contains(
                    searchQuery!,
                  ),
                )
                .toList()
            : produtos;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
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
                                "Buscar produto",
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
                          onChanged: filterProdutos,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFEEEEEE),
                            hintText: "Digite o nome do produto",
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

                // Lista de Produtos
                Expanded(
                  child:
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredProdutos.isEmpty
                          ? const Center(
                            child: Text('Nenhum produto encontrado'),
                          )
                          : ListView.builder(
                            itemCount: filteredProdutos.length,
                            itemBuilder: (context, index) {
                              final produto = filteredProdutos[index];

                              return Card(
                                color: Colors.white,
                                elevation: 8,
                                shadowColor: Colors.black.withOpacity(0.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: InkWell(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                EditProduct(produto: produto),
                                      ),
                                    );

                                    // Se o produto foi editado ou excluído, recarrega a lista
                                    if (result == true) {
                                      fetchProdutos();
                                    }
                                  },
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
                                            Expanded(
                                              child: Text(
                                                produto['nome'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 20,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          produto['descricao'],
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              "R\$ ${produto['precoMedio'].toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF148553),
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
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddNewProduct()),
            );

            // Se um produto foi criado, recarrega a lista
            if (result == true) {
              fetchProdutos();
            }
          },
          backgroundColor: const Color(0xFF148553),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
