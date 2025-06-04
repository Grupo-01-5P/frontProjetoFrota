import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Para o BottomNavigationBar
import 'package:front_projeto_flutter/screens/budgets/budgets_listage.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_reproval.dart';
// Ajuste o caminho do import se o nome do seu arquivo de service for diferente
import 'package:front_projeto_flutter/screens/budgets/services/detailsService.dart';
import 'package:front_projeto_flutter/screens/budgets/services/aprovalService.dart';
// Adicione o import do intl se ainda não estiver lá, para _formatDateTime
// import 'package:intl/intl.dart'; // Lembre de adicionar 'intl' ao pubspec.yaml

class BudgetsDetails extends StatefulWidget {
  final Map<String, dynamic> budgetData; // Dados iniciais/parciais da tela anterior
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
  final BudgetDetailsService _budgetDetailsService = BudgetDetailsService();
  final BudgetApprovalService _budgetApprovalService = BudgetApprovalService();

  Map<String, dynamic>? _detailedBudget;
  bool _isLoading = true;
  String? _error;
  bool _isApproving = false;
  bool _isDeletingProduct = false;

  @override
  void initState() {
    super.initState();
    _fetchBudgetDetails();
  }

  Future<void> _fetchBudgetDetails() async {
    if (!mounted) return; // Evitar chamar setState em widget desmontado
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _budgetDetailsService.fetchBudgetDetails(widget.budgetId);
      if (!mounted) return;
      setState(() {
        _detailedBudget = data;
        _isLoading = false;
      });
    } catch (e) {
      print("Erro capturado em _fetchBudgetDetails: $e");
      if (!mounted) return;
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
    if (defaultValue is String && current != null) { // Adicionado para conversão segura para String
      return current.toString() as T;
    }
    return defaultValue;
  }

  Future<void> _showApprovalConfirmationDialog() async {
    if (_isApproving || _isDeletingProduct) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Usar StatefulWidget para o conteúdo do diálogo se precisar atualizar o estado do botão "Sim"
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Confirmar Aprovação'),
              content: const SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('Tem certeza que deseja aprovar este orçamento?'),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Não'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                TextButton(
                  onPressed: _isApproving ? null : () async {
                    setDialogState(() { // Atualiza o estado do diálogo
                       // _isApproving = true; // O estado _isApproving da tela principal será usado
                    });
                    Navigator.of(dialogContext).pop(); // Fecha o diálogo primeiro
                    await _performApproveBudget();   // Depois executa a ação
                  },
                  child: _isApproving 
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Text('Sim'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _performApproveBudget() async {
    if(!mounted) return;
    setState(() {
      _isApproving = true;
    });

    try {
      await _budgetApprovalService.approveBudget(widget.budgetId);
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orçamento aprovado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => BudgetsListage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print("Erro ao aprovar orçamento: $e");
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao aprovar orçamento: ${e.toString().split(':').last.trim()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isApproving = false;
        });
      }
    }
  }

  Future<void> _showRemoveProductConfirmationDialog(int orcamentoProdutoId, String nomeProduto) async {
    if (_isDeletingProduct || _isApproving) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder( // Para atualizar o estado do botão "Sim" no dialog
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Remover Produto'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('Tem certeza que deseja remover o produto "$nomeProduto" deste orçamento?'),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Não'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                TextButton(
                  onPressed: _isDeletingProduct ? null : () async {
                     // O estado _isDeletingProduct da tela principal será usado
                    Navigator.of(dialogContext).pop(); // Fecha o diálogo
                    await _performRemoveProduct(orcamentoProdutoId); // Executa a ação
                  },
                  child: _isDeletingProduct
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Sim'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _performRemoveProduct(int orcamentoProdutoId) async {
    if(!mounted) return;
    setState(() {
      _isDeletingProduct = true;
    });

    try {
      await _budgetDetailsService.removeProductFromBudget(orcamentoProdutoId);
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produto removido com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      await _fetchBudgetDetails(); // Recarrega os detalhes do orçamento
    } catch (e) {
      print("Erro ao remover produto: $e");
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao remover produto: ${e.toString().split(':').last.trim()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingProduct = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? dataSource = _detailedBudget ?? widget.budgetData;

    final String nomeMecanica = _getSafe(dataSource, ['oficina', 'nome'], 'N/A');
    final String placaVeiculo = _getSafe(dataSource, ['manutencao', 'veiculo', 'placa'], 'N/A');
    final List<dynamic> produtosApi = _getSafe(_detailedBudget, ['produtos'], []);
    final String currentStatus = _getSafe(dataSource, ['status'], '').toLowerCase();
    final bool isFinalStatus = currentStatus == 'approved' || currentStatus == 'reproved' ||
                               currentStatus == 'aprovado' || currentStatus == 'reprovado';

    if (_isLoading && _detailedBudget == null) { // Mostrar loading apenas na carga inicial
      return Scaffold(
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
         bottomNavigationBar: _buildBottomNav(context), // Mostrar bottomNav mesmo no loading
      );
    }
    
    if (_error != null && _detailedBudget == null) { // Mostrar erro se a carga inicial falhar
       return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Erro ao carregar detalhes:\n$_error", textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context),
      );
    }


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
              child: _isLoading // Para recargas (após deleção)
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && produtosApi.isEmpty // Erro durante recarga
                      ? Center(
                          child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text("Erro ao atualizar produtos:\n$_error", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        ))
                      : produtosApi.isEmpty 
                            ? const Center(child: Text("Nenhum produto atribuído a este orçamento."))
                            : ListView(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                children: [
                                  ...produtosApi.map((produtoDataMap) {
                                    if (produtoDataMap is Map<String, dynamic>) {
                                      final String nomeProduto = _getSafe(produtoDataMap, ['produto', 'nome'], 'Produto sem nome');
                                      final double precoProdutoNum = _getSafe(produtoDataMap, ['valorUnitario'], 0.0);
                                      final String precoProduto = "R\$ ${precoProdutoNum.toStringAsFixed(2)}";
                                      final String descProduto = _getSafe(produtoDataMap, ['produto', 'descricao'], '');
                                      final int orcamentoProdutoId = _getSafe(produtoDataMap, ['id'], 0); 

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom:16.0), 
                                        child: _buildCardProduto(
                                          nomeProduto: nomeProduto,
                                          preco: precoProduto,
                                          descricao: descProduto,
                                          orcamentoProdutoId: orcamentoProdutoId,
                                          onDeletePressed: () {
                                            if (orcamentoProdutoId != 0 && !isFinalStatus && !_isApproving && !_isDeletingProduct) {
                                              _showRemoveProductConfirmationDialog(orcamentoProdutoId, nomeProduto);
                                            }
                                          },
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink(); 
                                  }).toList(),
                                  const SizedBox(height: 16),
                                  if (!isFinalStatus)
                                    Center(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          shape: const CircleBorder(),
                                          padding: const EdgeInsets.all(20),
                                          backgroundColor: Colors.green,
                                        ),
                                        onPressed: (_isApproving || _isDeletingProduct) ? null : () {
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
                      onPressed: (isFinalStatus || _isApproving || _isDeletingProduct) ? null : () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => BudgetsReproval(budgetId: widget.budgetId,))); 
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        disabledBackgroundColor: Colors.red.shade200, 
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
                      onPressed: (isFinalStatus || _isApproving || _isDeletingProduct) ? null : _showApprovalConfirmationDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        disabledBackgroundColor: Colors.green.shade200, 
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isApproving 
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text(
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
      bottomNavigationBar: _buildBottomNav(context),
    );
  }
}

// Helper para o BottomNavigationBar, para manter o build principal mais limpo
Widget _buildBottomNav(BuildContext context) {
  return BottomNavigationBar( 
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
        if (index == 0) { /* Lógica para Manutenções */ }
        else if (index == 1) { 
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => BudgetsListage()), 
                (route) => false
            );
        }
        else if (index == 2) { /* Lógica para Inoperante */ }
    },
  );
}

Widget _buildCardProduto({
  required String nomeProduto,
  required String preco,
  required String descricao,
  required int orcamentoProdutoId,
  required VoidCallback onDeletePressed,
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
          if(descricao.isNotEmpty)
            Text(
              descricao,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          const SizedBox(height: 8),
          Align( 
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onDeletePressed, 
              borderRadius: BorderRadius.circular(8),
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