import 'package:flutter/material.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart';
import 'package:front_projeto_flutter/screens/maintenences/manutencoes_geral.dart';
import 'package:front_projeto_flutter/screens/maintenences/manutencoes_solicitadas.dart';

class ManutencaoScreen extends StatefulWidget {
  const ManutencaoScreen({Key? key}) : super(key: key);

  @override
  _ManutencaoScreenState createState() => _ManutencaoScreenState();
}

class _ManutencaoScreenState extends State<ManutencaoScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  void _handleLogout() {
    // Implementar lógica de logout
    print('Logout realizado');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp( // Remova isto se sua tela já está dentro de um MaterialApp
      home: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F5F5),
        
        // Adicione seu drawer aqui
        drawer: CustomDrawer(
          onLogout: _handleLogout,
          userName: 'Kelvin',
          userSubtitle: 'Editar minhas informações',
          useCustomIcons: false,
        ),
        
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.menu,
              color: Color(0xFF0C7E3D),
            ),
            onPressed: () {
              // Abrir o drawer diretamente usando _scaffoldKey
              if (_scaffoldKey.currentState != null) {
                _scaffoldKey.currentState!.openDrawer();
              }
            },
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
                      onPressed: () {
                        // Ação para notificações
                      },
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
            const SizedBox(height: 20),
            
            // Card de Manutenções Solicitadas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: InkWell(
                onTap: () {
                  //navega para tela de manutenções solicitadas
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManutencoesSolicitadasScreen(),
                      ),
                    );
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: const [
                            Center(
                              child: Text(
                                'Manutenções solicitadas',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            Center(
                              child: Icon(
                                Icons.build,
                                size: 32,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB74343), // Vermelho
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            '3',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Card de Manutenções
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManutencoesGeralScreen(),
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
                            'Manutenções',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Center(
                          child: Icon(
                            Icons.build,
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
            
            // Imagem do Pneu ou ícone alternativo
            Expanded(
              child: Center(
                child: tryLoadImage('lib/assets/images/tire.png', iconColor: const Color(0xFF0C7E3D)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Método para tentar carregar a imagem ou retornar um ícone alternativo
  Widget tryLoadImage(String imagePath, {Color? iconColor, double width = 400}) {
    try {
      return Image.asset(
        imagePath,
        width: width,
        color: iconColor,
        errorBuilder: (context, error, stackTrace) {
          print('Erro ao carregar a imagem: $error');
          return Icon(
            Icons.directions_car,
            size: width / 2,
            color: iconColor,
          );
        },
      );
    } catch (e) {
      print('Exceção ao tentar carregar a imagem: $e');
      return Icon(
        Icons.directions_car,
        size: width / 2,
        color: iconColor,
      );
    }
  }
}