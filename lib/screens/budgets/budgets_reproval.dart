import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_page.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_exibition.dart';

class BudgetsReproval extends StatefulWidget {
  const BudgetsReproval({super.key});

  @override
  State<BudgetsReproval> createState() => _BudgetsReprovalState();
}

class _BudgetsReprovalState extends State<BudgetsReproval> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _descriptionController = TextEditingController();
  bool _receiveNewBudget = true;

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
                // Botões do topo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

                // Conteúdo da página
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
                                const Text(
                                  'Reprovação de orçamento',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Descreva abaixo o motivo da reprovação',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 250, // Caixa maior
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextField(
                                    controller: _descriptionController,
                                    maxLines: null,
                                    expands: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Descrição',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.all(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text('Receber um novo orçamento do mecânico?'),
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

                // Botões fora do Card, no final da página
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Ação de enviar
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => BudgetsExibition()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'ENVIAR',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Ação de cancelar
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
          _buildDrawerItem(icon: Icons.request_quote, text: 'Orçamentos', onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => BudgetsPage()));
          }),
          _buildDrawerItem(icon: Icons.build, text: 'Visualizar manutenções', onTap: () {}),
          _buildDrawerItem(icon: Icons.warning, text: 'Veículos inoperantes', onTap: () {}),
          _buildDrawerItem(icon: Icons.bar_chart, text: 'Dashboards', onTap: () {}),
          _buildDrawerItem(icon: Icons.store, text: 'Mecânicas', onTap: () {}),
          _buildDrawerItem(icon: Icons.directions_car, text: 'Veículos', onTap: () {}),
          _buildDrawerItem(icon: Icons.settings, text: 'Configurações', onTap: () {}),
          _buildDrawerItem(icon: Icons.exit_to_app, text: 'Sair', iconColor: Colors.red, onTap: () {}),
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
            color: Colors.green,
          ),
          label: 'Orçamentos',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.warning),
          label: 'Inoperante',
        ),
      ],
      selectedItemColor: Colors.green,
    );
  }
}
