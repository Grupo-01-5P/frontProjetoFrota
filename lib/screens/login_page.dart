import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:front_projeto_flutter/screens/home_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Adicione esta dependência
import 'package:jwt_decoder/jwt_decoder.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _secureStorage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _obscureText = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Função para realizar o login
  // No arquivo login_page.dart, modifique a função _login()

  Future<void> _login() async {
    // Validar o formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // URL da API - ajuste conforme necessário
      final Uri url = Uri.parse('http://localhost:4040/login');

      // Preparar dados para envio
      final Map<String, String> data = {
        'email': _emailController.text.trim(),
        'senha': _passwordController.text,
      };

      // Enviar requisição para a API
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        
        // Login bem-sucedido
        final responseData = jsonDecode(response.body);

        // Salvar token
        if (responseData['token'] != null) {
          final String token = responseData['token'];
          await _secureStorage.write(key: 'auth_token', value: token);

          // Adicionar print do token
          print('Token recebido: $token');
          print('Token decodificado: ${JwtDecoder.decode(token)}');

          final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

          // Extrair o ID do usuário do token decodificado
          int userId = decodedToken['id'];

          // Obter informações detalhadas do usuário
          await _fetchUserDetails(userId, token);

          //direciona para a tela inicial
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } else {
          setState(() {
            _errorMessage =
                'Resposta da API não contém token. Contate suporte.';
          });
        }
      } else if (response.statusCode == 401) {
        // Credenciais inválidas
        setState(() {
          _errorMessage = 'Email ou senha incorretos.';
        });
      } else {
        // Outro erro da API
        setState(() {
          _errorMessage = 'Erro no servidor. Tente novamente mais tarde.';
        });
      }
    } catch (e) {
      // Erro de conexão ou outro erro
      setState(() {
        _errorMessage =
            'Erro ao conectar com o servidor. Verifique sua conexão.';
      });
      print('Erro de login: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Função para buscar detalhes do usuário
  Future<void> _fetchUserDetails(int userId, String token) async {
    try {
      final Uri userUrl = Uri.parse('http://localhost:4040/api/users/$userId');

      final userResponse = await http.get(
        userUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Inclui o token na requisição
        },
      );

      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);

        // Armazenar informações do usuário
        await _secureStorage.write(
          key: 'user_id',
          value: userData['id'].toString(),
        );
        await _secureStorage.write(
          key: 'user_name',
          value: userData['nome'] ?? 'Usuário',
        );
        await _secureStorage.write(
          key: 'user_email',
          value: userData['email'] ?? '',
        );
        await _secureStorage.write(
          key: 'user_function',
          value: userData['funcao'] ?? '',
        );

        // Adicione outros dados do usuário que deseja armazenar

        print('Informações do usuário armazenadas com sucesso');
      } else {
        print('Erro ao obter detalhes do usuário: ${userResponse.statusCode}');
      }
    } catch (e) {
      print('Exceção ao obter detalhes do usuário: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      margin: const EdgeInsets.only(top: 40, bottom: 40),
                      child: Image.asset(
                        'lib/assets/images/logo.png', // Substitua pelo caminho da sua logo
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Título
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF148553), // Verde da sua aplicação
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Mensagem de erro
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Campo de Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Informe seu email',
                        prefixIcon: const Icon(
                          Icons.email,
                          color: Color(0xFF148553),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF148553),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, informe seu email';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Por favor, informe um email válido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Campo de Senha
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        hintText: 'Informe sua senha',
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Color(0xFF148553),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF148553),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, informe sua senha';
                        }
                        return null;
                      },
                    ),


                    const SizedBox(height: 30),

                    // Botão de Login
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF148553,
                          ), // Verde da sua aplicação
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 3,
                        ),
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'Entrar',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Rodapé com informações da empresa
                    const Text(
                      '© 2025 Fleet Management',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
