import 'package:flutter/material.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart'; // Importe o CustomDrawer

class Inoperative extends StatelessWidget {
  Inoperative({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Função de logout
  void _handleLogout() {
    // Implemente sua lógica de logout
    print('Logout realizado');
    // Navegue para a tela de login
    // Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      drawer: CustomDrawer(
        onLogout: _handleLogout,
        userName: 'Kelvin',
        userSubtitle: 'Editar minhas informações',
        headerColor: const Color(0xFF148553),
        useCustomIcons: true, // Use ícones personalizados
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white, // Círculo branco
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2), // Cor do sombreado
                          blurRadius: 6, // Intensidade do sombreado
                          offset: const Offset(2, 2), // Posição do sombreado
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Image.asset(
                        'lib/assets/images/iconMenu.png', // Caminho para a imagem do ícone de menu
                        width: 24,
                        height: 24,
                      ),
                      onPressed: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                    ),
                  ),
                  // Adicione o segundo ícone ou outros widgets aqui, se necessário
                ],
              ),
              const SizedBox(height: 20),

              Card(
                color: Colors.white,
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Text(
                              "Buscar veículo",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconTheme(
                            data: const IconThemeData(
                              color: Colors.black,
                              size: 28,
                            ),
                            child: Icon(Icons.sort_by_alpha),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFEEEEEE),
                          hintText: "Digite a placa do veículo",
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Card(
                color: Colors.white,
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            "RDM4J56",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            "Toyota Corolla XEi 2022",
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Prata",
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Logística Express Ltda.",
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Frota Operacional",
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFAC26).withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Inoperante",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.7),
                  blurRadius: 20.0,
                  spreadRadius: 5.0,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: 2, // Inoperantes selecionado
              onTap: (index) {
                // Navegar para a tela correspondente
                if (index == 0) {
                  // Navegar para Manutenções
                } else if (index == 1) {
                  // Navegar para Orçamentos
                }
              },
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.black,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              items: [
                BottomNavigationBarItem(
                  icon: SizedBox(
                    width: 30,
                    height: 30,
                    child: Image.asset('lib/assets/images/iconManutencoes.png'),
                  ),
                  label: 'Manutenções',
                ),
                BottomNavigationBarItem(
                  icon: SizedBox(
                    width: 30,
                    height: 30,
                    child: Image.asset('lib/assets/images/iconTerceirize.png'),
                  ),
                  label: 'Orçamentos',
                ),
                BottomNavigationBarItem(
                  icon: SizedBox(
                    width: 30,
                    height: 30,
                    child: Image.asset('lib/assets/images/iconInoperantes.png'),
                  ),
                  label: 'Inoperantes',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}