import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicles_listage.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicles_register.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({Key? key}) : super(key: key);

  @override
  _VehiclesPageState createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F5F5),
        
        // Drawer padronizado
        drawer: CustomDrawer(
          useCustomIcons: false,
        ),
        
        // AppBar padronizado
        appBar: AppBar(
          leading: Container(
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
        
        // Body padronizado
        body: Column(
          children: [
            const SizedBox(height: 20),
            
            // Card de Cadastrar Veículo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VehiclesRegister(),
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
                      children: [
                        const Center(
                          child: Text(
                            'Cadastrar um veículo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: tryLoadSvg(
                            'lib/assets/images/carromais.svg',
                            size: 32,
                            color: const Color(0xFF0C7E3D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Card de Visualizar Veículos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VehiclesListage(),
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
                      children: [
                        const Center(
                          child: Text(
                            'Visualizar a base de veículos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: tryLoadSvg(
                            'lib/assets/images/carro.svg',
                            size: 32,
                            color: const Color(0xFF0C7E3D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Imagem ilustrativa no final
            Expanded(
              child: Center(
                child: tryLoadImage(
                  'lib/assets/images/vehicle_illustration.png',
                  iconColor: const Color(0xFF0C7E3D),
                ),
              ),
            ),
          ],
        ),
        
        
      ),
    );
  }
  
  // Método para tentar carregar SVG ou retornar ícone alternativo
  Widget tryLoadSvg(String svgPath, {Color? color, double size = 24}) {
    try {
      return SvgPicture.asset(
        svgPath,
        width: size,
        height: size,
        color: color,
      );
    } catch (e) {
      print('Erro ao carregar o SVG: $e');
      return Icon(
        Icons.directions_car,
        size: size,
        color: color,
      );
    }
  }
  
  // Método para tentar carregar imagem ou retornar ícone alternativo
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