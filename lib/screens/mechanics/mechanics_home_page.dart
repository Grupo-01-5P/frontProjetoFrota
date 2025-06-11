import 'package:flutter/material.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart';
import 'package:front_projeto_flutter/screens/mechanics/new_mechanic_page.dart';
import 'package:front_projeto_flutter/screens/mechanics/view_mechanics_page.dart';

class MechanicsHomePage extends StatefulWidget {
  const MechanicsHomePage({Key? key}) : super(key: key);

  @override
  _MechanicsHomePageState createState() => _MechanicsHomePageState();
}

class _MechanicsHomePageState extends State<MechanicsHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: const CustomDrawer(useCustomIcons: false),
      body: Stack(
        children: [
          // SafeArea para os botões no topo
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botão para abrir o Drawer
                  Container(
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
                      icon: Image.asset(
                        'lib/assets/images/iconMenu.png',
                        width: 24,
                        height: 24,
                      ),
                      onPressed: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                    ),
                  ),
                  // Botão de notificações (opcional)
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
              children: [
                const SizedBox(height: 90), // Espaço abaixo do topo
                // Card para "Cadastrar uma nova mecânica"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NewMechanicPage(),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: const [
                            Center(
                              child: Text(
                                'Cadastrar uma nova mecânica',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            Center(
                              child: Icon(
                                Icons.add_business,
                                size: 32,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Card para "Visualizar mecânicas"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ViewMechanicsPage(),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: const [
                            Center(
                              child: Text(
                                'Visualizar mecânicas',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            Center(
                              child: Icon(
                                Icons.store,
                                size: 32,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Imagem ilustrativa centralizada
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'lib/assets/images/tire.png', // Substitua pelo caminho correto da imagem
                      height: 200, // Ajuste a altura da imagem
                      fit: BoxFit.contain,
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
}
