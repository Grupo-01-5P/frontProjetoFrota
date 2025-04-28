import 'package:flutter/material.dart';

class Inoperative extends StatelessWidget {
  Inoperative({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      drawer: Drawer(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.zero, // Remove os arredondamentos
  ),
  child: ListView(
    padding: EdgeInsets.zero,
    children: [
      UserAccountsDrawerHeader(
        accountName: Text(
          'Kelvin',
          style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
        ),
        accountEmail: Text(
          'Editar minhas informações',
          style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
        ),
        currentAccountPicture: CircleAvatar(
          backgroundColor: Color(0xFFD9D9D9),
          child: Icon(Icons.person, size: 40, color: Colors.white),
        ),
        decoration: const BoxDecoration(color: Color(0xFF148553)),
      ),
      _buildDrawerItem(
        icon: Image.asset('lib/assets/images/iconTerceirize.png', width: 24, height: 24),
        text: 'Orçamentos',
        onTap: () {
          // Ação para Orçamentos
        },
      ),
      SizedBox(height: 8),
      _buildDrawerItem(
        icon: Image.asset('lib/assets/images/iconManutencoes.png', width: 24, height: 24),
        text: 'Visualizar manutenções',
        onTap: () {
          // Ação para Visualizar manutenções
        },
      ),
      SizedBox(height: 8),
      _buildDrawerItem(
        icon: Image.asset('lib/assets/images/iconInoperantes.png', width: 24, height: 24),
        text: 'Veículos inoperantes',
        onTap: () {
          Navigator.pop(context);
        },
      ),
      SizedBox(height: 8),
      _buildDrawerItem(
        icon: Image.asset('lib/assets/images/iconDashboard.png', width: 24, height: 24),
        text: 'Dashboards',
        onTap: () {
          // Ação para Dashboards
        },
      ),
      SizedBox(height: 8),
      _buildDrawerItem(
        icon: Image.asset('lib/assets/images/iconMecanica.png', width: 24, height: 24),
        text: 'Mecânicas',
        onTap: () {
          // Ação para Mecânicas
        },
      ),
      SizedBox(height: 8),
      _buildDrawerItem(
        icon: Image.asset('lib/assets/images/iconCar.png', width: 24, height: 24),
        text: 'Veículos',
        onTap: () {
          // Ação para Veículos
        },
      ),
      SizedBox(height: 8),
      _buildDrawerItem(
        icon: Image.asset('lib/assets/images/iconEngrenagem.png', width: 24, height: 24),
        text: 'Configurações',
        onTap: () {
          // Ação para Configurações
        },
      ),
      SizedBox(height: 8),
      _buildDrawerItem(
        icon: Image.asset('lib/assets/images/iconExit.png', width: 24, height: 24),
        text: 'Sair',
        onTap: () {
          // Ação para Sair
        },
      ),
    ],
  ),
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
            offset: Offset(2, 2), // Posição do sombreado
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
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              "Buscar veículo",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconTheme(
                            data: IconThemeData(
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
                          fillColor: Color(0xFFEEEEEE),
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
                        children: [
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
                      Text(
                        "Prata",
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Logística Express Ltda.",
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Frota Operacional",
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFAC26).withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
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
                  offset: Offset(0, -10),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: 0,
              onTap: (index) {
                // Ação para a navegação entre as telas
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

  Widget _buildDrawerItem({
    required Widget icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: icon,
      title: Text(text),
      onTap: onTap,
    );
  }
}
