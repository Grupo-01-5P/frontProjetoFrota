import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

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
                // Ação para Orçamentos
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
          // Background da tela
          Positioned.fill(
            child: Image.asset(
              'lib/assets/images/backgroundHome.png',
              fit: BoxFit.cover,
            ),
          ),

          // Botões no topo
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botão para abrir a sidebar
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer(); // Abre o Drawer
                    },
                  ),
                  // Botão de notificações
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
          ),

          // Conteúdo principal
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15), // Reduzido o espaço acima dos cards
                // Cards com input de placa
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .end, // Move os cards para perto da barra inferior
                      children: const [
                        _PlacaCard(titulo: "Aprovar solicitação"),
                        SizedBox(height: 12),
                        _PlacaCard(titulo: "Visualizar manutenção do veículo"),
                        SizedBox(height: 12),
                        _PlacaCard(titulo: "Deslocamento de veículo"),
                        SizedBox(height: 12),
                      ],
                    ),
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

class _PlacaCard extends StatelessWidget {
  final String titulo;

  const _PlacaCard({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Digite a placa do veículo',
                filled: true,
                fillColor: Color(0xFFF1F1F1),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
