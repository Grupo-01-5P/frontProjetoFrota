import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front_projeto_flutter/screens/budgets/services/detailsService.dart';
import 'package:intl/intl.dart'; 

class BudgetsExibition extends StatefulWidget {
  final int budgetId;

  const BudgetsExibition({
    super.key,
    required this.budgetId,
  });

  @override
  State<BudgetsExibition> createState() => _BudgetsExibitionState();
}

class _BudgetsExibitionState extends State<BudgetsExibition> {
  final BudgetDetailsService _detailsService = BudgetDetailsService();
  Map<String, dynamic>? _budgetDetailsData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBudgetDetailsData();
  }

  Future<void> _fetchBudgetDetailsData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _detailsService.fetchBudgetDetails(widget.budgetId);
      setState(() {
        _budgetDetailsData = data;
        _isLoading = false;
      });
    } catch (e) {
      print("Erro ao buscar detalhes do orçamento para exibição: $e");
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Função auxiliar para obter valores de forma segura do mapa
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

  // Função para determinar a cor e o texto da flag de status
  Widget _buildStatusFlag(String? status) {
    Color flagColor = Colors.grey.shade300; // Cor padrão para status desconhecido
    Color textColor = Colors.black54;
    String statusText = status?.toUpperCase() ?? "DESCONHECIDO";

    // Normalizar o status para minúsculas para comparação
    String normalizedStatus = status?.toLowerCase() ?? "";

    if (normalizedStatus == 'reproved' || normalizedStatus == 'reprovado') {
      flagColor = Colors.red.shade300;
      textColor = Colors.white;
      statusText = "REPROVADO";
    } else if (normalizedStatus == 'approved' || normalizedStatus == 'aprovado') {
      flagColor = Colors.green.shade300;
      textColor = Colors.white;
      statusText = "APROVADO";
    } else if (normalizedStatus == 'pending' || normalizedStatus == 'pendente') {
      flagColor = Colors.amber.shade300;
      textColor = Colors.black87;
      statusText = "PENDENTE";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: flagColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Função para formatar datas
  String _formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }
    try {
      // Usando o pacote intl para formatação mais robusta
      final dateTime = DateTime.parse(dateString).toLocal(); // Converter para local se for UTC
      return DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(dateTime);
    } catch (e) {
      return dateString; // Retorna a string original se houver erro no parse
    }
  }
  
  // Widget _buildItem (adaptado para ser um método da classe)
  Widget _buildItemWidget(String title, String price, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded( // Para que o título possa quebrar linha
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                price,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16, // Consistência de tamanho
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (description.isNotEmpty) // Só mostra descrição se houver
            Text(
              description,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes do Orçamento')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _budgetDetailsData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes do Orçamento')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Erro ao carregar detalhes do orçamento:\n${_error ?? 'Dados não disponíveis.'}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    // Extração de dados do _budgetDetailsData
    final String nomeMecanica = _getSafe(_budgetDetailsData, ['oficina', 'nome'], 'N/A');
    final String placaVeiculo = _getSafe(_budgetDetailsData, ['manutencao', 'veiculo', 'placa'], 'N/A');
    final String statusOrcamento = _getSafe(_budgetDetailsData, ['status'], 'null');
    
    final List<dynamic> produtos = _getSafe(_budgetDetailsData, ['produtos'], []);
    final double valorMaoObra = _getSafe(_budgetDetailsData, ['valorMaoObra'], 0.0);
    final String descricaoServicoMaoObra = _getSafe(_budgetDetailsData, ['descricaoServico'], "Serviços gerais de mão de obra");

    double somaProdutos = 0.0;
    for (var produto in produtos) {
      if (produto is Map<String, dynamic>) {
        somaProdutos += _getSafe(produto, ['valorUnitario'], 0.0);
      }
    }
    final double totalGeral = somaProdutos + valorMaoObra;

    final String? dataReprovacao = _getSafe(_budgetDetailsData, ['dataReprovacao'], null);
    final String? motivoReprovacao = _getSafe(_budgetDetailsData, ['motivoReprovacao'], null);
    final bool isReprovado = statusOrcamento?.toLowerCase() == 'reproved' || statusOrcamento?.toLowerCase() == 'reprovado';


    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumo do Orçamento'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start, // Alinha melhor se o status for grande
              children: [
                Expanded( // Para o texto da mecânica/placa quebrar linha se necessário
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nomeMecanica,
                        style: const TextStyle(
                          fontSize: 20, // Um pouco maior para destaque
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Placa: $placaVeiculo',
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8), // Espaço antes da flag
                _buildStatusFlag(statusOrcamento),
              ],
            ),
            const SizedBox(height: 24),

            // Lista de Itens (Produtos + Mão de Obra)
            if (produtos.isNotEmpty)
              ...produtos.map((produtoData) {
                if (produtoData is Map<String, dynamic>) {
                  final String nomeProduto = _getSafe(produtoData, ['produto', 'nome'], 'N/A');
                  final double precoProdutoNum = _getSafe(produtoData, ['valorUnitario'], 0.0);
                  final String descProduto = _getSafe(produtoData, ['produto', 'descricao'], '');
                  return _buildItemWidget(
                    nomeProduto,
                    "R\$ ${precoProdutoNum.toStringAsFixed(2)}",
                    descProduto,
                  );
                }
                return const SizedBox.shrink();
              }).toList(),
            
            // Mão de Obra sempre listada
            _buildItemWidget(
              "Mão de obra",
              "R\$ ${valorMaoObra.toStringAsFixed(2)}",
              descricaoServicoMaoObra, // Usando a descrição do serviço do orçamento
            ),

            const Divider(height: 32, thickness: 1),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Geral', // Alterado para mais clareza
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'R\$ ${totalGeral.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20, // Destaque no total
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Seção de Reprovação (Condicional)
            if (isReprovado) ...[
              const Text(
                'Detalhes da Reprovação:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 8),
              if (dataReprovacao != null && dataReprovacao.isNotEmpty)
                Text.rich(
                  TextSpan(
                    text: 'Data e hora: ',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    children: [
                      TextSpan(
                        text: _formatDateTime(dataReprovacao),
                        style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8), // Espaço mesmo se não houver data
              if (motivoReprovacao != null && motivoReprovacao.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blueGrey, // Cor diferente para esta ação
                    padding: const EdgeInsets.symmetric(vertical: 12), // Menor padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Motivo da Reprovação'),
                          content: Text(motivoReprovacao.isEmpty ? "Nenhum motivo fornecido." : motivoReprovacao),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Fechar'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text('Visualizar Motivo da Reprovação'),
                ),
              ),
              const SizedBox(height: 24),
            ],
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
              'lib/assets/images/_2009906610368.svg', // Verifique este caminho
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
        currentIndex: 1, // Manter "Orçamentos" selecionado
        // Adicionar lógica de onTap se necessário
      ),
    );
  }
}