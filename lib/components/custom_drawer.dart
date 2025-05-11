import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:front_projeto_flutter/screens/home_page.dart';
import 'package:front_projeto_flutter/screens/inoperative.dart';
import 'package:front_projeto_flutter/screens/login_page.dart';
import 'package:front_projeto_flutter/screens/maintenences/firstPage.dart';

class CustomDrawer extends StatelessWidget {
  final Function onLogout;
  final String userName;
  final String userSubtitle;
  final Widget? userAvatar;
  final Color headerColor;
  final bool useCustomIcons;

  const CustomDrawer({
    Key? key,
    required this.onLogout,
    this.userName = 'Kelvin',
    this.userSubtitle = 'Editar minhas informações',
    this.userAvatar,
    this.headerColor = const Color(0xFF148553),
    this.useCustomIcons = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // Remove os arredondamentos
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              userName,
              style: const TextStyle(color: Colors.white),
            ),
            accountEmail: Text(
              userSubtitle,
              style: const TextStyle(color: Colors.white),
            ),
            currentAccountPicture: userAvatar ?? CircleAvatar(
              backgroundColor: const Color(0xFFD9D9D9),
              child: const Icon(Icons.person, size: 40, color: Colors.white),
            ),
            decoration: BoxDecoration(color: headerColor),
          ),
          
          // Home / Dashboard
          useCustomIcons
              ? _buildDrawerItemWithImage(
                  imageAsset: 'lib/assets/images/iconDashboard.png',
                  text: 'Home',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer
                    
                    // Verificar se já não está na Home
                    if (!(context.widget is HomePage)) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => HomePage()),
                        (route) => false, // Remove todas as rotas anteriores
                      );
                    }
                  },
                )
              : _buildDrawerItemWithIcon(
                  icon: Icons.home,
                  text: 'Home',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer
                    
                    // Verificar se já não está na Home
                    if (!(context.widget is HomePage)) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => HomePage()),
                        (route) => false, // Remove todas as rotas anteriores
                      );
                    }
                  },
                ),
          const SizedBox(height: 8),
          
          // Orçamentos
          useCustomIcons
              ? _buildDrawerItemWithImage(
                  imageAsset: 'lib/assets/images/iconTerceirize.png',
                  text: 'Orçamentos',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer
                    
                    // Navegação para a tela de orçamentos
                    // Quando implementada, substitua este código:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidade em desenvolvimento'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                )
              : _buildDrawerItemWithIcon(
                  icon: Icons.request_quote,
                  text: 'Orçamentos',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer
                    
                    // Navegação para a tela de orçamentos
                    // Quando implementada, substitua este código:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidade em desenvolvimento'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 8),
          
          // Manutenções
          useCustomIcons
              ? _buildDrawerItemWithImage(
                  imageAsset: 'lib/assets/images/iconManutencoes.png',
                  text: 'Visualizar manutenções',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer
                    
                    // Navegação direta para a tela de manutenções
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManutencaoScreen(),
                      ),
                    );
                  },
                )
              : _buildDrawerItemWithIcon(
                  icon: Icons.build,
                  text: 'Visualizar manutenções',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer
                    
                    // Navegação direta para a tela de manutenções
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManutencaoScreen(),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 8),
          
          // Veículos inoperantes - Usar navegação direta
          useCustomIcons
              ? _buildDrawerItemWithImage(
                  imageAsset: 'lib/assets/images/iconInoperantes.png',
                  text: 'Veículos inoperantes',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer
                    
                    // Navegação direta para a tela de inoperantes
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Inoperative(),
                      ),
                    );
                  },
                )
              : _buildDrawerItemWithIcon(
                  icon: Icons.warning,
                  text: 'Veículos inoperantes',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer
                    
                    // Navegação direta para a tela de inoperantes
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Inoperative(),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 8),
          
          // Dashboards
          useCustomIcons
              ? _buildDrawerItemWithImage(
                  imageAsset: 'lib/assets/images/iconDashboard.png',
                  text: 'Dashboards',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer
                    
                    // Navegação para a tela de dashboards
                    // Quando implementada, substitua este código:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidade em desenvolvimento'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                )
              : _buildDrawerItemWithIcon(
                  icon: Icons.bar_chart,
                  text: 'Dashboards',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer
                    
                    // Navegação para a tela de dashboards
                    // Quando implementada, substitua este código:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidade em desenvolvimento'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 8),
          
          // Mecânicas
          useCustomIcons
              ? _buildDrawerItemWithImage(
                  imageAsset: 'lib/assets/images/iconMecanica.png',
                  text: 'Mecânicas',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer
                    
                    // Navegação para a tela de mecânicas
                    // Quando implementada, substitua este código:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidade em desenvolvimento'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                )
              : _buildDrawerItemWithIcon(
                  icon: Icons.store,
                  text: 'Mecânicas',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer
                    
                    // Navegação para a tela de mecânicas
                    // Quando implementada, substitua este código:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidade em desenvolvimento'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 8),
          
          // Veículos
          useCustomIcons
              ? _buildDrawerItemWithImage(
                  imageAsset: 'lib/assets/images/iconCar.png',
                  text: 'Veículos',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer
                    
                    // Navegação para a tela de veículos
                    // Quando implementada, substitua este código:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidade em desenvolvimento'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                )
              : _buildDrawerItemWithIcon(
                  icon: Icons.directions_car,
                  text: 'Veículos',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer
                    
                    // Navegação para a tela de veículos
                    // Quando implementada, substitua este código:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidade em desenvolvimento'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 8),
          
          // Configurações
          useCustomIcons
              ? _buildDrawerItemWithImage(
                  imageAsset: 'lib/assets/images/iconEngrenagem.png',
                  text: 'Configurações',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer
                    
                    // Navegação para a tela de configurações
                    // Quando implementada, substitua este código:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidade em desenvolvimento'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                )
              : _buildDrawerItemWithIcon(
                  icon: Icons.settings,
                  text: 'Configurações',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer
                    
                    // Navegação para a tela de configurações
                    // Quando implementada, substitua este código:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidade em desenvolvimento'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 8),
          
          // Sair
          useCustomIcons
              ? _buildDrawerItemWithImage(
                  imageAsset: 'lib/assets/images/iconExit.png',
                  text: 'Sair',
                  onTap: () => _handleLogout(context),
                )
              : _buildDrawerItemWithIcon(
                  icon: Icons.exit_to_app,
                  text: 'Sair',
                  iconColor: Colors.red,
                  onTap: () => _handleLogout(context),
                ),
        ],
      ),
    );
  }

  // Método para lidar com o logout
  // Método para lidar com o logout
void _handleLogout(BuildContext context) {
  // Fechar o drawer
  Navigator.pop(context);
  
  // Mostrar diálogo de confirmação
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Confirmação'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Apenas fecha o diálogo
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              // Fecha o diálogo
              Navigator.of(dialogContext).pop();
              
              // Executa o logout
              onLogout();
              
              // Limpar o token (opcional)
              try {
                final secureStorage = const FlutterSecureStorage();
                await secureStorage.delete(key: 'auth_token');
              } catch (e) {
                print('Erro ao deletar token: $e');
              }
              
              // Navega para a tela de login usando navegação direta
              // e removendo todas as telas anteriores da pilha
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(),
                ),
              );
            },
            child: const Text('Sair'),
          ),
        ],
      );
    },
  );
}
  
  // Widget para item do menu com ícone
  Widget _buildDrawerItemWithIcon({
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

  // Widget para item do menu com imagem
  Widget _buildDrawerItemWithImage({
    required String imageAsset,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Image.asset(
        imageAsset,
        width: 24,
        height: 24,
      ),
      title: Text(text),
      onTap: onTap,
    );
  }
}