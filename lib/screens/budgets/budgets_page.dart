import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_listage.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_listage_pending.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  _BudgetsPageState createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _secureStorage = const FlutterSecureStorage();

  // Variáveis para controlar o estado da tela
  bool _isLoading = true;
  int _quantidadeOrcamentosPendentes = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarOrcamentosPendentes();
  }

  // Função para carregar a quantidade de orçamentos pendentes
  Future<void> _carregarOrcamentosPendentes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Obter o token de autenticação
      final token = await _secureStorage.read(key: 'auth_token');

      if (token == null) {
        setState(() {
          _errorMessage = 'Token de autenticação não encontrado';
          _isLoading = false;
        });
        return;
      }

      // Fazer a requisição para o endpoint de orçamentos
      final response = await http.get(
        Uri.parse('http://localhost:4040/api/budgets/'), // Ajuste o endpoint conforme sua API
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Processar a resposta com base na estrutura da API
        final data = jsonDecode(response.body);

        int contador = 0;

        // Verifica se a resposta tem o campo 'orcamentos' ou estrutura similar
        if (data['data'] is List) {
          List orcamentos = data['data'];

          for (var orcamento in orcamentos) {
            // Contar orçamentos com status 'pendente' ou 'aguardando'
            if (orcamento['status'] == 'pendente' || orcamento['status'] == 'aguardando') {
              contador++;
            }
          }

          print('Encontrados $contador orçamentos pendentes');
        } else if (data is List) {
          // Caso a resposta seja diretamente uma lista
          for (var orcamento in data) {
            if (orcamento['status'] == 'pendente' || orcamento['status'] == 'aguardando') {
              contador++;
            }
          }
        } else {
          print('Estrutura de resposta da API diferente do esperado: ${data.toString().substring(0, 100)}...');
        }

        setState(() {
          _quantidadeOrcamentosPendentes = contador;
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        // Token inválido ou expirado
        setState(() {
          _errorMessage = 'Sessão expirada, faça login novamente';
          _isLoading = false;
        });
      } else {
        // Outro erro da API
        setState(() {
          _errorMessage = 'Erro ao carregar orçamentos: ${response.statusCode}';
          _isLoading = false;
        });
        print('Resposta da API com erro: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro de conexão: $e';
        _isLoading = false;
      });
      print('Erro ao carregar orçamentos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: CustomDrawer(
        useCustomIcons: false,
      ),
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
                  ElevatedButton(
                    onPressed: _carregarOrcamentosPendentes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C7E3D),
                    ),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                const SizedBox(height: 20),

                // Card de Orçamentos Pendentes
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: InkWell(
                    onTap: () {
                      // Navega para tela de orçamentos pendentes/aguardando aprovação
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BudgetsListagePending(), // Você pode criar uma tela específica para pendentes
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
                              children: [
                                const Center(
                                  child: Text(
                                    'Orçamentos pendentes',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: SvgPicture.asset(
                                    'lib/assets/images/logoorcamentos.svg',
                                    width: 32,
                                    height: 32,
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
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _quantidadeOrcamentosPendentes.toString(),
                                      style: const TextStyle(
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

                // Card de Todos os Orçamentos
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BudgetsListage(),
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
                                'Todos os orçamentos',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: SvgPicture.asset(
                                'lib/assets/images/logoorcamentos.svg',
                                width: 32,
                                height: 32,
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


                // Imagem decorativa ou ícone
                Expanded(
                  child: Center(
                    child: _tryLoadImage(
                      'lib/assets/images/budget_icon.png', // Você pode usar uma imagem específica para orçamentos
                      iconColor: const Color(0xFF0C7E3D),
                      fallbackIcon: Icons.receipt_long, // Ícone alternativo para orçamentos
                    ),
                  ),
                ),
              ],
            ),
      
      // Barra de navegação inferior
    );
  }

  // Método para tentar carregar a imagem ou retornar um ícone alternativo
  Widget _tryLoadImage(
    String imagePath, {
    Color? iconColor,
    double width = 400,
    IconData fallbackIcon = Icons.receipt_long,
  }) {
    try {
      return Image.asset(
        imagePath,
        width: width,
        color: iconColor,
        errorBuilder: (context, error, stackTrace) {
          print('Erro ao carregar a imagem: $error');
          return Icon(fallbackIcon, size: width / 2, color: iconColor);
        },
      );
    } catch (e) {
      print('Exceção ao tentar carregar a imagem: $e');
      return Icon(fallbackIcon, size: width / 2, color: iconColor);
    }
  }
}