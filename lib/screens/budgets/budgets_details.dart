import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_listage.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_reproval.dart';
import 'package:front_projeto_flutter/screens/budgets/services/detailsService.dart';

class BudgetsDetails extends StatefulWidget {
  final Map<String, dynamic> budgetData;
  final int budgetId;

  const BudgetsDetails({
    super.key,
    required this.budgetData,
    required this.budgetId,
  });

  @override
  State<BudgetsDetails> createState() => _BudgetsDetailsState();
}

class _BudgetsDetailsState extends State<BudgetsDetails> {
  // Usar o novo BudgetDetailsService
  final BudgetDetailsService _budgetDetailsService = BudgetDetailsService();
  Map<String, dynamic>? _detailedBudget;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBudgetDetails();
  }

  Future<void> _fetchBudgetDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Chamar o método do novo service
      final data = await _budgetDetailsService.fetchBudgetDetails(widget.budgetId);
      setState(() {
        _detailedBudget = data;
        _isLoading = false;
      });
    } catch (e) {
      print("Erro capturado em _fetchBudgetDetails: $e");
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  T _getSafe<T>(Map<String, dynamic>? map, List<String> keys, T defaultValue) {
    if (map == null) return defaultValue;
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
    final Map<String, dynamic>? dataSource = _detailedBudget ?? widget.budgetData;

    final String nomeMecanica = _getSafe(dataSource, ['oficina', 'nome'], 'Carregando...');
    final String placaVeiculo = _getSafe(dataSource, ['manutencao', 'veiculo', 'placa'], 'Carregando...');
    
    final List<dynamic> produtosApi = _getSafe(_detailedBudget, ['produtos'], []);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding( 
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end, 
                children: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.black),
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
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nomeMecanica,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Placa: $placaVeiculo',
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text( 
                        'Orçamento ID: ${widget.budgetId}',
                        style: const TextStyle(fontSize: 14, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text("Erro ao carregar produtos:\n$_error", textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
                        ))
                      : produtosApi.isEmpty
                            ? const Center(child: Text("Nenhum produto atribuído a este orçamento."))
                            : ListView(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                children: [
                                  ...produtosApi.map((produtoData) {
                                    if (produtoData is Map<String, dynamic>) {
                                      final String nomeProduto = _getSafe(produtoData, ['produto', 'nome'], 'Produto sem nome');
                                      final double precoProdutoNum = _getSafe(produtoData, ['valorUnitario'], 0.0);
                                      final String precoProduto = "R\$ ${precoProdutoNum.toStringAsFixed(2)}";
                                      final String descProduto = _getSafe(produtoData, ['produto', 'descricao'], 'Sem descrição');
                                      
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom:16.0), 
                                        child: _buildCardProduto(
                                          nomeProduto: nomeProduto,
                                          preco: precoProduto,
                                          descricao: descProduto,
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink(); 
                                  }).toList(),
                                  const SizedBox(height: 16),
                                  Center(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: const CircleBorder(),
                                        padding: const EdgeInsets.all(20),
                                        backgroundColor: Colors.green,
                                      ),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Funcionalidade de adicionar produto a ser implementada.')),
                                        );
                                      },
                                      child: const Icon(Icons.add, color: Colors.white, size: 30),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => BudgetsReproval(budgetId: widget.budgetId,))); 
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Reprovar',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => BudgetsListage()),
                            (Route<dynamic> route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Aprovar',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar( 
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Manutenções',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'lib/assets/images/_2009906610368.svg', 
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
        currentIndex: 1, 
        onTap: (index) {
            if (index == 0) { /* Navegar para Manutenções */ }
            if (index == 2) { /* Navegar para Inoperante */ }
        },
      ),
    );
  }
}

// Widget _buildCardProduto (permanece o mesmo da resposta anterior)
Widget _buildCardProduto({
  required String nomeProduto,
  required String preco,
  required String descricao,
}) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded( 
                child: Text(
                  nomeProduto,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                preco,
                style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            descricao,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Align( 
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                 // Ação de remover produto (futuro)
              },
              child: Container(
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}