import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_page.dart';

class BudgetsDetails extends StatelessWidget {
  BudgetsDetails({super.key});

  // Criação de uma GlobalKey para controlar o Scaffold
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Vincula a chave ao Scaffold
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Cabeçalho do menu
            UserAccountsDrawerHeader(
              accountName: const Text('Kelvin'),
              accountEmail: const Text('Editar minhas informações'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.person, size: 40, color: Colors.grey),
              ),
              decoration: const BoxDecoration(color: Colors.green),
            ),

            // Itens do menu
            _buildDrawerItem(
              icon: Icons.request_quote,
              text: 'Orçamentos',
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => BudgetsPage()));
              },
            ),
            _buildDrawerItem(
              icon: Icons.build,
              text: 'Visualizar manutenções',
              onTap: () {
                // Ação para Visualizar manutenções
              },
            ),
            _buildDrawerItem(
              icon: Icons.warning,
              text: 'Veículos inoperantes',
              onTap: () {
                // Ação para Veículos inoperantes
              },
            ),
            _buildDrawerItem(
              icon: Icons.bar_chart,
              text: 'Dashboards',
              onTap: () {
                // Ação para Dashboards
              },
            ),
            _buildDrawerItem(
              icon: Icons.store,
              text: 'Mecânicas',
              onTap: () {
                // Ação para Mecânicas
              },
            ),
            _buildDrawerItem(
              icon: Icons.directions_car,
              text: 'Veículos',
              onTap: () {
                // Ação para Veículos
              },
            ),
            _buildDrawerItem(
              icon: Icons.settings,
              text: 'Configurações',
              onTap: () {
                // Ação para Configurações
              },
            ),
            _buildDrawerItem(
              icon: Icons.exit_to_app,
              text: 'Sair',
              iconColor: Colors.red,
              onTap: () {
                // Ação para Sair
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Botões no topo
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
                            onPressed: () {
                              // Ação para notificações
                            },
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
                // LISTAGEM DOS CARDS
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildCardProduto(
                        title: "TorqueMax Mecânica",
                        subtitle: "JDP3H82",
                        nomeProduto: "Filtro de óleo",
                        preco: "R\$ 45,90",
                        descricao:
                            "Filtro de Óleo Bosch Premium OF101 10 cm (altura) x 8 cm (diâmetro)",
                      ),
                      const SizedBox(height: 16),
                      _buildCardProduto(
                        title: "Outra Mecânica",
                        subtitle: "XYZ1234",
                        nomeProduto: "Pneu 175/65",
                        preco: "R\$ 320,00",
                        descricao:
                            "Pneu Continental EcoContact 6 - Medida 175/65 R14",
                      ),
                      const SizedBox(height: 16),
                      // Você pode adicionar quantos cards quiser assim...
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Barra de navegação inferior
      bottomNavigationBar: BottomNavigationBar(
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Manutenções',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'lib/assets/images/_2009906610368.svg', // Caminho do SVG
              width: 24,
              height: 24,
              color: Colors.green, // Cor do ícone
            ),
            label: 'Orçamentos',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Inoperante',
          ),
        ],
        selectedItemColor: Colors.green,
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
}

Widget _buildCardProduto({
  required String title,
  required String subtitle,
  required String nomeProduto,
  required String preco,
  required String descricao,
}) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 2,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Topo
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Título e subtítulo
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              // Ícone "adicionar"
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.1),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.add,
                  color: Colors.green,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        // Produto
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    nomeProduto,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    preco,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.open_in_new, size: 16, color: Colors.green),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                descricao,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
