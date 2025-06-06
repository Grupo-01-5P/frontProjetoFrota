import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart';
import 'package:front_projeto_flutter/screens/mechanics/edit_mechanic_page.dart';

class MechanicDetailPage extends StatefulWidget {
  final int mechanicId;
  const MechanicDetailPage({Key? key, required this.mechanicId})
    : super(key: key);

  @override
  State<MechanicDetailPage> createState() => _MechanicDetailPageState();
}

class _MechanicDetailPageState extends State<MechanicDetailPage> {
  final _secureStorage = const FlutterSecureStorage();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic>? mechanic;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchMechanic();
  }

  Future<void> fetchMechanic() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('http://localhost:4040/api/garage/${widget.mechanicId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          mechanic = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Erro ao buscar oficina (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Erro de conexão: $e';
        isLoading = false;
      });
    }
  }

  String formatCnpj(String cnpj) {
    if (cnpj.length != 14) return cnpj;
    return '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.${cnpj.substring(5, 8)}/${cnpj.substring(8, 12)}-${cnpj.substring(12)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(useCustomIcons: false),
      backgroundColor: const Color(0xFFF9F9F9),
      body: Stack(
        children: [
          // Topo customizado (Drawer e Notificação)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botão Drawer
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
                  // Botão Notificação
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications,
                          color: Colors.black,
                        ),
                        onPressed: () {},
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
            child: Padding(
              padding: const EdgeInsets.only(
                top: 80,
                left: 12,
                right: 12,
                bottom: 0,
              ),
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : error != null
                      ? Center(
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                      : SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            _buildHeaderCard(),
                            const SizedBox(height: 16),
                            _buildInfoCard(),
                            const SizedBox(height: 16),
                            _buildMenuCard(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFF148553),
            child: Icon(Icons.garage, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mechanic?['nome'] ?? '',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF148553),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 22, color: Color(0xFF148553)),
            onPressed: () {
              if (mechanic != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditMechanicPage(mechanic: mechanic!),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _infoLine('CNPJ:', formatCnpj(mechanic?['cnpj'] ?? '')),
          _infoLine('Rua:', mechanic?['rua'] ?? ''),
          _infoLine('Bairro:', mechanic?['bairro'] ?? ''),
          _infoLine('Cidade:', mechanic?['cidade'] ?? ''),
          _infoLine('Estado:', mechanic?['estado'] ?? ''),
          _infoLine('E-mail:', mechanic?['email'] ?? ''),
          _infoLine('Telefone:', mechanic?['telefone'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildMenuCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _menuItem(Icons.build, 'Manutenções'),
          _menuItem(Icons.medical_services, 'Orçamentos'),
          _menuItem(Icons.alt_route, 'Deslocamento'),
          _menuItem(Icons.directions_car, 'Veículos'),
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            '$label ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF148553)),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      onTap: () {},
    );
  }
}
