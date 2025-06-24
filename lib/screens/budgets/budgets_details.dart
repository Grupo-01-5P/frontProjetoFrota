import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; 
import 'package:front_projeto_flutter/screens/budgets/budgets_listage.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_reproval.dart';
import 'package:front_projeto_flutter/screens/budgets/services/detailsService.dart';
import 'package:front_projeto_flutter/screens/budgets/services/aprovalService.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  final _secureStorage = const FlutterSecureStorage();

  Map<String, dynamic>? _detailedBudget;
  bool _isLoading = true;
  String? _error;
  bool _isApproving = false;
  bool _isDeletingProduct = false;
  bool _isAddingProduct = false;
  bool _isLoadingProducts = false;
  bool _isSavingProduct = false;
  bool _isSearchingProducts = false;
  
  List<Map<String, dynamic>> _availableProducts = [];
  List<Map<String, dynamic>> _produtosEncontrados = [];
  Map<String, dynamic>? _produtoSelecionado;
  
  final _produtoSearchController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final _fornecedorController = TextEditingController();
  final _addProductFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchBudgetDetails();
  }

  @override
  void dispose() {
    _produtoSearchController.dispose();
    _quantidadeController.dispose();
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

  // Buscar produtos na API
  Future<void> _buscarProdutos(String query) async {
    if (query.length < 2) {
      setState(() {
        _produtosEncontrados = [];
      });
      return;
    }

    setState(() {
      _isSearchingProducts = true;
    });

    try {
      final token = await _secureStorage.read(key: 'auth_token');
      
      if (token == null) {
        print('Token não encontrado');
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:4040/api/products/search/?q=$query'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _produtosEncontrados = List<Map<String, dynamic>>.from(data['data']);
          _isSearchingProducts = false;
        });
      } else {
        print('Erro ao buscar produtos: ${response.statusCode}');
        setState(() {
          _produtosEncontrados = [];
          _isSearchingProducts = false;
        });
      }
    } catch (e) {
      print('Erro ao buscar produtos: $e');
      setState(() {
        _produtosEncontrados = [];
        _isSearchingProducts = false;
      });
    }
  }

  Future<void> _showAddProductForm() async {
    setState(() => _isAddingProduct = true);
  }

  void _hideAddProductForm() {
    setState(() {
      _isAddingProduct = false;
      _addProductFormKey.currentState?.reset();
      _produtoSelecionado = null;
      _produtoSearchController.clear();
      _quantidadeController.clear();
      _fornecedorController.clear();
      _produtosEncontrados = [];
    });
  }

  Future<void> _performAddProduct() async {
    if (!(_addProductFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSavingProduct = true);

    try {
      final data = {
        "produtoId": _produtoSelecionado!['id'],
        "quantidade": double.parse(_quantidadeController.text.replaceAll(',', '.')),
        "valorUnitario": (_produtoSelecionado!['precoMedio'] ?? 0.0).toDouble(),
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
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Confirmar Aprovação'),
          content: const Text('Tem certeza que deseja aprovar este orçamento?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              onPressed: _isApproving ? null : () async {
                Navigator.of(dialogContext).pop();
                await _performApproveBudget();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _isApproving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Aprovar'),
            ),
          ],
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
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Remover Produto'),
          content: Text('Tem certeza que deseja remover o produto "$nomeProduto" deste orçamento?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              onPressed: _isDeletingProduct ? null : () async {
                Navigator.of(dialogContext).pop();
                await _performRemoveProduct(productId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: _isDeletingProduct
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Remover'),
            ),
          ],
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

  // Calcular valor total do orçamento
  double get _valorTotalOrcamento {
    final List<dynamic> produtosApi = _getSafe(_detailedBudget, ['produtos'], []);
    final double valorMaoObra = _getSafe(_detailedBudget, ['valorMaoObra'], 0.0);
    
    double valorProdutos = 0.0;
    for (var produto in produtosApi) {
      if (produto is Map<String, dynamic>) {
        final double valor = _getSafe(produto, ['valorUnitario'], 0.0);
        final double quantidade = _getSafe(produto, ['quantidade'], 1.0);
        valorProdutos += valor * quantidade;
      }
    }
    
    return valorMaoObra + valorProdutos;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? dataSource = _detailedBudget ?? widget.budgetData;

    final String nomeMecanica = _getSafe(dataSource, ['oficina', 'nome'], 'N/A');
    final String placaVeiculo = _getSafe(dataSource, ['manutencao', 'veiculo', 'placa'], 'N/A');
    final String descricaoServico = _getSafe(dataSource, ['descricaoServico'], 'N/A');
    final double valorMaoObra = _getSafe(dataSource, ['valorMaoObra'], 0.0);
    final List<dynamic> produtosApi = _getSafe(_detailedBudget, ['produtos'], []);
    final String currentStatus = _getSafe(dataSource, ['status'], '').toLowerCase();
    final bool isFinalStatus = currentStatus == 'approved' || currentStatus == 'reproved' ||
                              currentStatus == 'aprovado' || currentStatus == 'reprovado';
    final bool isActionInProgress = _isApproving || _isDeletingProduct || _isAddingProduct || _isSavingProduct;

    if (_isLoading && _detailedBudget == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF0C7E3D)),
        ),
      );
    }
   
    if (_error != null && _detailedBudget == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  "Erro ao carregar detalhes:\n$_error", 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchBudgetDetails,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      
      // AppBar padronizado
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
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Detalhes do Orçamento',
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
                    onPressed: () {},
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
      
      body: Column(
        children: [
          // Header com informações do orçamento
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C7E3D).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Color(0xFF0C7E3D),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nomeMecanica,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Orçamento #${widget.budgetId}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(currentStatus).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(currentStatus),
                        style: TextStyle(
                          color: _getStatusColor(currentStatus),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem('Veículo', placaVeiculo),
                    ),
                    Expanded(
                      child: _buildInfoItem('Mão de Obra', 'R\$ ${valorMaoObra.toStringAsFixed(2)}'),
                    ),
                  ],
                ),
                
                if (descricaoServico != 'N/A') ...[
                  const SizedBox(height: 12),
                  _buildInfoItem('Descrição', descricaoServico),
                ],
              ],
            ),
          ),

          // Lista de produtos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0C7E3D)))
                : Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Produtos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!isFinalStatus && !_isAddingProduct)
                              ElevatedButton.icon(
                                onPressed: isActionInProgress ? null : _showAddProductForm,
                                icon: _isLoadingProducts
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.add, size: 18),
                                label: const Text('Adicionar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0C7E3D),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Expanded(
                          child: produtosApi.isEmpty && !_isAddingProduct
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Nenhum produto adicionado',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView(
                                  children: [
                                    // Formulário de adicionar produto
                                    if (_isAddingProduct) _buildAddProductCard(),
                                    
                                    // Lista de produtos existentes
                                    ...produtosApi.map((produtoDataMap) {
                                      if (produtoDataMap is Map<String, dynamic>) {
                                        return _buildProductCard(produtoDataMap, isFinalStatus, isActionInProgress);
                                      }
                                      return const SizedBox.shrink();
                                    }).toList(),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
          ),

          // Total e botões de ação
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Total do orçamento
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C7E3D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Valor Total do Orçamento:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'R\$ ${_valorTotalOrcamento.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Botões de ação
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (isFinalStatus || isActionInProgress) ? null : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => BudgetsReproval(budgetId: widget.budgetId),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF67E7E),
                          disabledBackgroundColor: const Color(0xFFF67E7E).withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
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
                          backgroundColor: const Color(0xFF4EB699),
                          disabledBackgroundColor: const Color(0xFF4EB699).withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: _isApproving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Aprovar',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> produtoDataMap, bool isFinalStatus, bool isActionInProgress) {
    final String nomeProduto = _getSafe(produtoDataMap, ['produto', 'nome'], 'Produto sem nome');
    final double precoProdutoNum = _getSafe(produtoDataMap, ['valorUnitario'], 0.0);
    final double quantidade = _getSafe(produtoDataMap, ['quantidade'], 1.0);
    final String descProduto = _getSafe(produtoDataMap, ['produto', 'descricao'], '');
    final String fornecedor = _getSafe(produtoDataMap, ['fornecedor'], '');
    final int produtoId = _getSafe(produtoDataMap, ['produto', 'id'], 0);
    
    final double valorTotal = precoProdutoNum * quantidade;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nomeProduto,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!isFinalStatus && !isActionInProgress)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _showRemoveProductConfirmationDialog(produtoId, nomeProduto),
                ),
            ],
          ),
          
          if (descProduto.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              descProduto,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Quantidade', quantidade.toStringAsFixed(quantidade.truncateToDouble() == quantidade ? 0 : 2)),
              ),
              Expanded(
                child: _buildInfoItem('Valor Unit.', 'R\$ ${precoProdutoNum.toStringAsFixed(2)}'),
              ),
              Expanded(
                child: _buildInfoItem('Total', 'R\$ ${valorTotal.toStringAsFixed(2)}'),
              ),
            ],
          ),
          
          if (fornecedor.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoItem('Fornecedor', fornecedor),
          ],
        ],
      ),
    );
  }

  Widget _buildAddProductCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0C7E3D), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Form(
        key: _addProductFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_circle, color: Color(0xFF0C7E3D)),
                const SizedBox(width: 8),
                const Text(
                  'Adicionar Produto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _hideAddProductForm,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Campo de busca de produto
            const Text(
              'Buscar Produto',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _produtoSearchController,
              decoration: InputDecoration(
                hintText: 'Digite o nome do produto...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: _isSearchingProducts 
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search),
              ),
              onChanged: (value) {
                _buscarProdutos(value);
              },
            ),
            const SizedBox(height: 8),

            // Lista de produtos encontrados
            if (_produtosEncontrados.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _produtosEncontrados.length,
                  itemBuilder: (context, index) {
                    final produto = _produtosEncontrados[index];
                    final isSelected = _produtoSelecionado?['id'] == produto['id'];
                    
                    return ListTile(
                      dense: true,
                      selected: isSelected,
                      selectedTileColor: const Color(0xFF0C7E3D).withOpacity(0.1),
                      title: Text(
                        produto['nome'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (produto['descricao'] != null && produto['descricao'].isNotEmpty)
                            Text(
                              produto['descricao'],
                              style: const TextStyle(fontSize: 12),
                            ),
                          Text(
                            'Preço médio: R\$ ${(produto['precoMedio'] ?? 0.0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF0C7E3D),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _produtoSelecionado = produto;
                        });
                      },
                    );
                  },
                ),
              ),
            
            if (_produtoSelecionado != null) ...[
              const SizedBox(height: 16),
              
              // Produto selecionado
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C7E3D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF0C7E3D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF0C7E3D), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Produto Selecionado: ${_produtoSelecionado!['nome']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Preço: R\$ ${(_produtoSelecionado!['precoMedio'] ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(color: Color(0xFF0C7E3D)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Campos de quantidade e fornecedor
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quantidade',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _quantidadeController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: '1',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Campo obrigatório';
                            }
                            final quantidade = double.tryParse(value.replaceAll(',', '.'));
                            if (quantidade == null || quantidade <= 0) {
                              return 'Quantidade inválida';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fornecedor',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _fornecedorController,
                          decoration: InputDecoration(
                            hintText: 'Nome do fornecedor',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Campo obrigatório';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Botões do formulário
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSavingProduct ? null : _hideAddProductForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF67E7E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_isSavingProduct || _produtoSelecionado == null) ? null : _performAddProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4EB699),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: _isSavingProduct
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Adicionar',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'aprovado':
        return Colors.green;
      case 'reproved':
      case 'reprovado':
        return Colors.red;
      case 'pending':
      case 'pendente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'aprovado':
        return 'Aprovado';
      case 'reproved':
      case 'reprovado':
        return 'Reprovado';
      case 'pending':
      case 'pendente':
        return 'Pendente';
      default:
        return 'Desconhecido';
    }
  }
}