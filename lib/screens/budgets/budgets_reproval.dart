import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_page.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_exibition.dart';
import 'package:front_projeto_flutter/screens/budgets/services/reprovalService.dart';

class BudgetsReproval extends StatefulWidget {
  final int budgetId;

  const BudgetsReproval({super.key, required this.budgetId});

  @override
  State<BudgetsReproval> createState() => _BudgetsReprovalState();
}

class _BudgetsReprovalState extends State<BudgetsReproval> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _descriptionController = TextEditingController();
  bool _receiveNewBudget = true;

  // Instanciar o service
  final BudgetReprovalService _reprovalService = BudgetReprovalService();
  bool _isSending = false; // Para controlar o estado de envio

  Future<void> _submitReproval() async {
    if (_isSending) return; // Evitar múltiplos envios

    setState(() {
      _isSending = true;
    });

    try {
      // O texto da descrição e o checkbox não são enviados para o backend por enquanto,
      // conforme especificado. Apenas o status é alterado para "reproved".
      await _reprovalService.reproveBudget(widget.budgetId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orçamento reprovado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      // Navegar para BudgetsExibition após sucesso
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BudgetsExibition(budgetId: widget.budgetId),
        ),
      );
    } catch (e) {
      print("Erro ao enviar reprovação: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao reprovar orçamento: ${e.toString().split(':').last.trim()}',
          ), // Mensagem de erro mais limpa
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        // Verificar se o widget ainda está montado
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.black),
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      ),
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reprovação de orçamento', // Mostrando o ID
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Descreva abaixo o motivo da reprovação', // Atualizado
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 250,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextField(
                                    controller: _descriptionController,
                                    maxLines: null,
                                    expands: true,
                                    decoration: const InputDecoration(
                                      hintText:
                                          'Descrição (não será salva no backend nesta etapa)', // Atualizado
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.all(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Receber um novo orçamento do mecânico?', // Atualizado
                                      ),
                                    ),
                                    Checkbox(
                                      value: _receiveNewBudget,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _receiveNewBudget = value ?? true;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _isSending
                                  ? null
                                  : () {
                                    // Desabilitar se estiver enviando
                                    Navigator.of(context).pop();
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'CANCELAR',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _isSending
                                  ? null
                                  : _submitReproval, // Chamar _submitReproval
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child:
                              _isSending
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text(
                                    'ENVIAR',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // _buildDrawer() e _buildDrawerItem() permanecem os mesmos
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Kelvin'),
            accountEmail: const Text('Editar minhas informações'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.person, size: 40, color: Colors.grey),
            ),
            decoration: const BoxDecoration(color: Colors.green),
          ),
          _buildDrawerItem(
            icon: Icons.request_quote,
            text: 'Orçamentos',
            onTap: () {
              // Para evitar empilhamento, pode-se usar pushReplacement ou verificar a rota atual
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => BudgetsPage()),
                (route) => false,
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.build,
            text: 'Visualizar manutenções',
            onTap: () {},
          ),
          _buildDrawerItem(
            icon: Icons.warning,
            text: 'Veículos inoperantes',
            onTap: () {},
          ),
          _buildDrawerItem(
            icon: Icons.bar_chart,
            text: 'Dashboards',
            onTap: () {},
          ),
          _buildDrawerItem(icon: Icons.store, text: 'Mecânicas', onTap: () {}),
          _buildDrawerItem(
            icon: Icons.directions_car,
            text: 'Veículos',
            onTap: () {},
          ),
          _buildDrawerItem(
            icon: Icons.settings,
            text: 'Configurações',
            onTap: () {},
          ),
          _buildDrawerItem(
            icon: Icons.exit_to_app,
            text: 'Sair',
            iconColor: Colors.red,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
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

  // _buildBottomNavigationBar() - Corrigindo o `color` do SvgPicture
  Widget _buildBottomNavigationBar() {
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
            // Correção: Usar colorFilter para SvgPicture
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
      // Adicionar currentIndex para que o item 'Orçamentos' pareça selecionado
      // ou o item que corresponde à funcionalidade geral desta seção do app.
      // Se esta tela faz parte da seção de orçamentos, o índice 1 é apropriado.
      currentIndex: 1,
      onTap: (index) {
        // Lógica de navegação do BottomNavigationBar se necessário
        if (index == 1) {
          // Se clicar em Orçamentos, talvez voltar para a lista
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => BudgetsPage(),
            ), // Ou BudgetsListage()
            (route) => false,
          );
        }
      },
    );
  }
}
