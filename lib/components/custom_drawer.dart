import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:front_projeto_flutter/screens/dashboard.dart';
import 'package:front_projeto_flutter/screens/home_page.dart';
import 'package:front_projeto_flutter/screens/login_page.dart';
import 'package:front_projeto_flutter/screens/maintenences/firstPage.dart';
// Corrigido: Import específico para a tela de manutenção do supervisor
import 'package:front_projeto_flutter/screens/supervisor/maintenences/firstPage.dart';
import 'package:front_projeto_flutter/screens/users/firstPage.dart';
import 'package:front_projeto_flutter/screens/mechanics/mechanics_home_page.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_page.dart';
import 'package:front_projeto_flutter/screens/products/products.dart';
// Corrigido: Import específico para VehiclesPage principal
import 'package:front_projeto_flutter/screens/vehicles/vehicles_page.dart';

class CustomDrawer extends StatefulWidget {
  final Color headerColor;
  final bool useCustomIcons;

  const CustomDrawer({
    Key? key,
    this.headerColor = const Color(0xFF148553),
    this.useCustomIcons = false,
  }) : super(key: key);

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final _secureStorage = const FlutterSecureStorage();
  String userName = 'Usuário';
  String userEmail = 'Editar minhas informações';
  String userFunction = '';
  bool isLoading = true;
  bool isSupervisor = false;
  bool isAnalista = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // Função para carregar informações do usuário do armazenamento seguro
  Future<void> _loadUserInfo() async {
    try {
      final name = await _secureStorage.read(key: 'user_name');
      final email = await _secureStorage.read(key: 'user_email');
      final function = await _secureStorage.read(key: 'user_function');

      setState(() {
        if (name != null && name.isNotEmpty) userName = name;
        if (email != null && email.isNotEmpty) userEmail = email;
        if (function != null && function.isNotEmpty) {
          userFunction = function;
          // Verificar o nível de acesso baseado na função
          isSupervisor = function.toLowerCase() == 'supervisor';
          isAnalista = function.toLowerCase() == 'analista';
        }
        isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar informações do usuário: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

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
              userFunction.isNotEmpty
                  ? "$userEmail - $userFunction"
                  : userEmail,
              style: const TextStyle(color: Colors.white),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: const Color(0xFFD9D9D9),
              child:
                  isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.person, size: 40, color: Colors.white),
            ),
            decoration: BoxDecoration(color: widget.headerColor),
          ),

          // Home / Dashboard - Apenas para Analista
          widget.useCustomIcons
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

          // Orçamentos - Apenas para Analista
          if (isAnalista)
            widget.useCustomIcons
                ? _buildDrawerItemWithImage(
                  imageAsset: 'lib/assets/images/iconTerceirize.png',
                  text: 'Orçamentos',
                  onTap: () {
                    if (ModalRoute.of(context)?.settings.name != '/budgets_page') {
                     Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => BudgetsPage()));
                } else {
                    Navigator.pop(context); 
                }
                  },
                )
                : _buildDrawerItemWithIcon(
                  icon: Icons.request_quote,
                  text: 'Orçamentos',
                  onTap: () {
                    if (ModalRoute.of(context)?.settings.name != '/budgets_page') {
                     Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => BudgetsPage()));
                } else {
                    Navigator.pop(context); 
                }
                  },
                ),
          if (isAnalista) const SizedBox(height: 8),

          // Manutenções - Acesso para ambos (Supervisor e Analista)
          widget.useCustomIcons
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
                  if (isAnalista) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManutencaoScreen(),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // Corrigido: Removido const se o construtor não suportar
                        builder: (context) => const ManutencaoScreenSupervisor(),
                      ),
                    );
                  }
                },
              ),
          const SizedBox(height: 8),

          

          // Dashboards - Apenas para Analista
          if (isAnalista)
            widget.useCustomIcons
                ? _buildDrawerItemWithImage(
                  imageAsset: 'lib/assets/images/iconDashboard.png',
                  text: 'Dashboards',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PowerBIPage(),
                      ),
                    );
                  },
                )
                : _buildDrawerItemWithIcon(
                  icon: Icons.bar_chart,
                  text: 'Dashboards',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PowerBIPage(),
                      ),
                    );
                  },
                ),
          if (isAnalista) const SizedBox(height: 8),

          // Mecânicas - Apenas para Analista
          if (isAnalista)
            widget.useCustomIcons
                ? _buildDrawerItemWithImage(
                  imageAsset: 'lib/assets/images/iconMecanica.png',
                  text: 'Mecânicas',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer

                    // Navegação para a tela de mecânicas
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MechanicsHomePage(),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MechanicsHomePage(),
                      ),
                    );
                  },
                ),
          if (isAnalista) const SizedBox(height: 8),

          // Produtos - Apenas para Analista
          if (isAnalista)
            widget.useCustomIcons
                ? _buildDrawerItemWithImage(
                  imageAsset: 'lib/assets/images/iconProducts.png',
                  text: 'Produtos',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer

                    // Navegação para a tela de produtos
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProdutosScreen(),
                      ),
                    );
                  },
                )
                : _buildDrawerItemWithIcon(
                  icon: Icons.inventory,
                  text: 'Produtos',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer

                    // Navegação para a tela de produtos
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProdutosScreen(),
                      ),
                    );
                  },
                ),
          if (isAnalista) const SizedBox(height: 8),

          // Veículos - Apenas para Analista
            widget.useCustomIcons
                ? _buildDrawerItemWithImage(
                  imageAsset: 'lib/assets/images/iconCar.png',
                  text: 'Veículos',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // Corrigido: Usando const com a VehiclesPage padronizada
                        builder: (context) => const VehiclesPage(),
                      ),
                    );
                    
                  },
                )
                : _buildDrawerItemWithIcon(
                  icon: Icons.directions_car,
                  text: 'Veículos',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // Corrigido: Usando const com a VehiclesPage padronizada
                        builder: (context) => const VehiclesPage(),
                      ),
                    );
                  },
                ),

          // Configurações/Usuários - Apenas para Analista
          if (isAnalista)
            widget.useCustomIcons
                ? _buildDrawerItemWithImage(
                  imageAsset: 'lib/assets/images/iconEngrenagem.png',
                  text: 'Usuarios',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UsuarioScreen(),
                      ),
                    );
                  },
                )
                : _buildDrawerItemWithIcon(
                  icon: Icons.people,
                  text: 'Usuarios',
                  onTap: () {
                    Navigator.pop(context); // Fechar o drawer

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UsuarioScreen(),
                      ),
                    );
                  },
                ),
          if (isAnalista) const SizedBox(height: 8),

          // Sair - Acesso para ambos
          widget.useCustomIcons
              ? _buildDrawerItemWithImage(
                imageAsset: 'lib/assets/images/iconExit.png',
                text: 'Sair',
                onTap: () => {_handleLogout(context)},
              )
              : _buildDrawerItemWithIcon(
                icon: Icons.exit_to_app,
                text: 'Sair',
                iconColor: Colors.red,
                onTap:
                    () => {
                      _handleLogout(context), // Chama o método de logout
                    },
              ),
        ],
      ),
    );
  }

  // Método para lidar com o logout
  void _handleLogout(BuildContext context) {
    // Armazenar uma referência ao contexto fora do escopo do dialog
    final navigatorContext = Navigator.of(context);

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
                try {
                  // Limpar o token e informações do usuário
                  final secureStorage = const FlutterSecureStorage();
                  await secureStorage.deleteAll();

                  // Fechar o diálogo
                  Navigator.of(dialogContext).pop();

                  // Pequeno atraso para garantir que o diálogo feche completamente
                  await Future.delayed(const Duration(milliseconds: 100));

                  // Usar o navigatorContext capturado anteriormente
                  navigatorContext.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false, // Remove todas as rotas anteriores
                  );
                } catch (e) {
                  print('Erro ao fazer logout: $e');
                  // Tentar mostrar erro de forma segura
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao fazer logout: $e')),
                    );
                  }
                }
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
      leading: Image.asset(imageAsset, width: 24, height: 24),
      title: Text(text),
      onTap: onTap,
    );
  }
}