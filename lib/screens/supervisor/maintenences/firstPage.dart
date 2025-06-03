import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart';
import 'package:front_projeto_flutter/screens/supervisor/maintenences/manutencoes_geral.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:front_projeto_flutter/screens/supervisor/maintenences/selecao_veiculo_manutencao.dart';

class ManutencaoScreenSupervisor extends StatefulWidget {
  const ManutencaoScreenSupervisor({Key? key}) : super(key: key);

  @override
  _ManutencaoScreenSupervisorState createState() => _ManutencaoScreenSupervisorState();
}

class _ManutencaoScreenSupervisorState extends State<ManutencaoScreenSupervisor> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _secureStorage = const FlutterSecureStorage();
  
  // Variáveis para controlar o estado da tela
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  // Função para carregar a quantidade de manutenções solicitadas

  @override
  Widget build(BuildContext context) {
    return MaterialApp( // Remova isto se sua tela já está dentro de um MaterialApp
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F5F5),
        // Adicione seu drawer aqui
        drawer: CustomDrawer(// Função vazia, lógica já implementada no drawer
          useCustomIcons: false,
        ),
        
        appBar: AppBar(
          leading: Container(
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
        
        body: _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                  ],
                ),
              )
            : Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Card de Manutenções Solicitadas
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VeiculosDisponiveisScreen(), // Pass the 'vehicle' map here
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
                                      'Solicitar Manutenção',
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
                            )
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
                              builder: (context) => const ManutencoesGeralScreenSupervisor(),
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