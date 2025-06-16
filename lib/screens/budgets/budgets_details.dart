import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; 
import 'package:front_projeto_flutter/screens/budgets/budgets_listage.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_reproval.dart';
import 'package:front_projeto_flutter/screens/budgets/services/detailsService.dart';
import 'package:front_projeto_flutter/screens/budgets/services/aprovalService.dart';
import 'package:flutter/services.dart';

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
  final BudgetDetailsService _budgetDetailsService = BudgetDetailsService();
  final BudgetApprovalService _budgetApprovalService = BudgetApprovalService();

  Map<String, dynamic>? _detailedBudget;
  bool _isLoading = true;
  String? _error;
  bool _isApproving = false;
  bool _isDeletingProduct = false;
  bool _isAddingProduct = false;
  bool _isLoadingProducts = false;
  bool _isSavingProduct = false;
  List<Map<String, dynamic>> _availableProducts = [];
  int? _selectedProductId;
  final _valorUnitarioController = TextEditingController();
  final _fornecedorController = TextEditingController();
  final _addProductFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchBudgetDetails();
  }

  @override
  void dispose() {
    _valorUnitarioController.dispose();
    _fornecedorController.dispose();
    super.dispose();
  }

  Future<void> _fetchBudgetDetails() async {
    if (!mounted) return;
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

  Future<void> _showAddProductForm() async {
    if (_availableProducts.isEmpty && !_isLoadingProducts) {
      setState(() => _isLoadingProducts = true);
      try {
        final products = await _budgetDetailsService.fetchAllProducts();
        if (!mounted) return;
        setState(() {
          _availableProducts = products;
          _isAddingProduct = true;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao buscar produtos: ${e.toString()}'), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) setState(() => _isLoadingProducts = false);
      }
    } else {
      setState(() => _isAddingProduct = true);
    }
  }

  void _hideAddProductForm() {
    setState(() {
      _isAddingProduct = false;
      _addProductFormKey.currentState?.reset();
      _selectedProductId = null;
      _valorUnitarioController.clear();
      _fornecedorController.clear();
    });
  }

  Future<void> _performAddProduct() async {
    if (!(_addProductFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSavingProduct = true);

    try {
      final data = {
        "produtoId": _selectedProductId,
        "valorUnitario": double.parse(_valorUnitarioController.text.replaceAll(',', '.')),
        "fornecedor": _fornecedorController.text,
      };

      await _budgetDetailsService.addProductToBudget(widget.budgetId, data);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto adicionado com sucesso!'), backgroundColor: Colors.green),
      );

      _hideAddProductForm();
      await _fetchBudgetDetails();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar produto: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSavingProduct = false);
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
    if (defaultValue is String && current != null) {
      return current.toString() as T;
    }
    return defaultValue;
  }

  Future<void> _showApprovalConfirmationDialog() async {
    if (_isApproving || _isDeletingProduct || _isAddingProduct) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
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
                    Navigator.of(dialogContext).pop();
                    await _performApproveBudget();
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

  Future<void> _showRemoveProductConfirmationDialog(int productId, String nomeProduto) async {
    if (_isDeletingProduct || _isApproving || _isAddingProduct) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
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
                    Navigator.of(dialogContext).pop();
                    await _performRemoveProduct(productId);
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

  Future<void> _performRemoveProduct(int productId) async {
    if(!mounted) return;
    setState(() {
      _isDeletingProduct = true;
    });

    try {
      await _budgetDetailsService.removeProductFromBudget(widget.budgetId, productId);

      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produto removido com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      await _fetchBudgetDetails();
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
    final bool isActionInProgress = _isApproving || _isDeletingProduct || _isAddingProduct || _isSavingProduct;

    if (_isLoading && _detailedBudget == null) {
      return Scaffold(
        body: const SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
        bottomNavigationBar: _buildBottomNav(context),
      );
    }
   
    if (_error != null && _detailedBudget == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Erro ao carregar detalhes:\n$_error", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Orçamento'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
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
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                  : _error != null && produtosApi.isEmpty
                      ? Center(
                          child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text("Erro ao atualizar produtos:\n$_error", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        ))
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            ...produtosApi.map((produtoDataMap) {
                              if (produtoDataMap is Map<String, dynamic>) {
                                final String nomeProduto = _getSafe(produtoDataMap, ['produto', 'nome'], 'Produto sem nome');
                                final double precoProdutoNum = _getSafe(produtoDataMap, ['valorUnitario'], 0.0);
                                final String precoProduto = "R\$ ${precoProdutoNum.toStringAsFixed(2)}";
                                final String descProduto = _getSafe(produtoDataMap, ['produto', 'descricao'], '');
                                final int produtoId = _getSafe(produtoDataMap, ['produto', 'id'], 0);
                                final int orcamentoProdutoId = _getSafe(produtoDataMap, ['id'], 0);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom:16.0),
                                  child: _buildCardProduto(
                                    nomeProduto: nomeProduto,
                                    preco: precoProduto,
                                    descricao: descProduto,
                                    orcamentoProdutoId: orcamentoProdutoId,
                                    onDeletePressed: (produtoId != 0 && !isFinalStatus && !isActionInProgress)
                                        ? () => _showRemoveProductConfirmationDialog(produtoId, nomeProduto)
                                        : null,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }).toList(),
                           
                            if (!isFinalStatus)
                              _isAddingProduct
                                ? _buildAddProductCard()
                                : Center(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: const CircleBorder(),
                                        padding: const EdgeInsets.all(20),
                                        backgroundColor: Colors.green,
                                      ),
                                      onPressed: isActionInProgress ? null : _showAddProductForm,
                                      child: _isLoadingProducts
                                        ? const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                                        : const Icon(Icons.add, color: Colors.white, size: 30),
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
                      onPressed: (isFinalStatus || isActionInProgress) ? null : () {
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
                      onPressed: (isFinalStatus || isActionInProgress) ? null : _showApprovalConfirmationDialog,
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

  Widget _buildAddProductCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.green, width: 1.5),
      ),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _addProductFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Adicionar Novo Produto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedProductId,
                hint: const Text('Selecione um produto'),
                isExpanded: true,
                items: _availableProducts.map((product) {
                  return DropdownMenuItem<int>(
                    value: product['id'] as int,
                    child: Text(product['nome'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProductId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor, selecione um produto.';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Produto',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorUnitarioController,
                decoration: const InputDecoration(
                  labelText: 'Valor Unitário (R\$)',
                  border: OutlineInputBorder(),
                  prefixText: 'R\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um valor.';
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Por favor, insira um valor numérico válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fornecedorController,
                decoration: const InputDecoration(
                  labelText: 'Fornecedor',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um fornecedor.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSavingProduct ? null : _hideAddProductForm,
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSavingProduct ? null : _performAddProduct,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: _isSavingProduct
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Salvar', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildBottomNav(BuildContext context) {
  return BottomNavigationBar(
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
  required VoidCallback? onDeletePressed,
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
            child: GestureDetector(
              onTap: onDeletePressed,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: onDeletePressed != null ? Colors.red : Colors.grey,
                    borderRadius: BorderRadius.circular(8)
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
