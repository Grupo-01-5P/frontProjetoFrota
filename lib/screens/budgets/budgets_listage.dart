import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_page.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_details.dart';
import 'package:front_projeto_flutter/screens/budgets/services/listageService.dart'; // Importar o Service

class BudgetsListage extends StatefulWidget {
  BudgetsListage({super.key});

  @override
  _BudgetsListageState createState() => _BudgetsListageState();
}

class _BudgetsListageState extends State<BudgetsListage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final BudgetService _budgetService = BudgetService();

  // Agora trabalharemos com List<Map<String, dynamic>>
  late Future<List<Map<String, dynamic>>> _budgetsFuture;
  List<Map<String, dynamic>> _allBudgets = [];
  List<Map<String, dynamic>> _filteredBudgets = [];

  @override
  void initState() {
    super.initState();
    _loadBudgets();
    _searchController.addListener(_filterBudgets);
  }

  void _loadBudgets() {
    _budgetsFuture = _budgetService.fetchBudgets();
    _budgetsFuture.then((budgets) {
      setState(() {
        _allBudgets = budgets;
        _filteredBudgets = budgets;
      });
    }).catchError((error) {
      print("Erro ao carregar orçamentos: $error");
      setState(() {
        _allBudgets = [];
        _filteredBudgets = [];
      });
    });
  }

  void _filterBudgets() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBudgets = _allBudgets.where((budget) {
        // Acesso cuidadoso aos campos do mapa
        final placa = budget['manutencao']?['veiculo']?['placa']?.toString().toLowerCase() ?? '';
        return placa.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterBudgets);
    _searchController.dispose();
    super.dispose();
  }
  
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return dateString; // Retorna a string original se o parse falhar
    }
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listagem dos Orçamentos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Stack(
        children: [
          Column(
            children: [
             // const SizedBox(height: 80), 
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Buscar Orçamento por Placa',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Digite a placa do veículo',
                            filled: true,
                            fillColor: Colors.grey.shade200,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _budgetsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Erro ao carregar orçamentos: ${snapshot.error}\nPor favor, verifique sua conexão e a URL da API no código.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Nenhum orçamento encontrado.'));
                    }
                    
                    if (_filteredBudgets.isEmpty && _searchController.text.isNotEmpty) {
                         return const Center(child: Text('Nenhum orçamento encontrado para esta placa.'));
                    }

                    return ListView.builder(
                      itemCount: _filteredBudgets.length,
                      itemBuilder: (context, index) {
                        final budget = _filteredBudgets[index];

                        // Acesso aos dados do mapa com checagem de nulidade e tipo
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

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => BudgetsDetails(
                                    budgetData: budget, // Continuamos passando o mapa completo
                                    budgetId: budgetId,   // <--- NOVO: Passando o ID extraído
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
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          placa,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: status.toLowerCase() == 'pendente' 
                                                   ? Colors.orangeAccent 
                                                   : (status.toLowerCase() == 'aprovado'
                                                      ? Colors.green 
                                                      : Colors.grey),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Oficina: $nomeOficina',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Serviço: $descServico',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Enviado em: ${_formatDate(dataEnvioStr)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                     Text(
                                      'Mão de Obra: R\$ ${valorMaoObra.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (produtosDynamic.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Total Produtos: R\$ ${totalProdutos.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                           fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar( // BottomNavigationBar permanece o mesmo
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
              colorFilter: const ColorFilter.mode(Colors.green, BlendMode.srcIn),
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

  Widget _buildDrawerItem({ // _buildDrawerItem permanece o mesmo
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color iconColor = Colors.green,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(text),
      onTap: onTap,
    );
  }
}