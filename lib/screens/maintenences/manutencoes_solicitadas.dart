import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:front_projeto_flutter/screens/maintenences/manutencao_detalhe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class ManutencoesSolicitadasScreen extends StatefulWidget {
  const ManutencoesSolicitadasScreen({Key? key}) : super(key: key);

  @override
  _ManutencoesSolicitadasScreenState createState() => _ManutencoesSolicitadasScreenState();
}

class _ManutencoesSolicitadasScreenState extends State<ManutencoesSolicitadasScreen> {
  final _secureStorage = const FlutterSecureStorage();
  bool _isLoading = true;
  List<dynamic> _manutencoes = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchManutencoes();
  }

  Future<void> _fetchManutencoes() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final token = await _secureStorage.read(key: 'auth_token');
      
      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sessão expirada. Por favor, faça login novamente.';
        });
        return;
      }

      // Opção 1: Filtrar no servidor (adicionar parâmetro de filtro à URL)
      // Modifique a URL para incluir o filtro por status "pendente"
      final url = Uri.parse('http://localhost:4040/api/maintenance/?status=pendente');
      
      // Nota: Se seu backend não suportar filtragem por parâmetros de URL,
      // use a Opção 2 mostrada na explicação acima
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        setState(() {
          _manutencoes = data['manutencoes'];
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sessão expirada. Por favor, faça login novamente.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao carregar dados: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro de conexão: ${e.toString()}';
      });
    }
  }

  // Função para formatar a data
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manutenções Pendentes'),
        backgroundColor: const Color(0xFF0C7E3D),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchManutencoes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0C7E3D),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[300],
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C7E3D),
                        ),
                        onPressed: _fetchManutencoes,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _manutencoes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.build_circle_outlined,
                            color: Colors.grey[400],
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Nenhuma manutenção pendente encontrada',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchManutencoes,
                      color: const Color(0xFF0C7E3D),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _manutencoes.length,
                        itemBuilder: (context, index) {
                          final manutencao = _manutencoes[index];
                          final veiculo = manutencao['veiculo'];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () async {
                                // Navegar para detalhes com dados completos da manutenção
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ManutencaoDetailScreen(
                                      manutencao: manutencao,
                                    ),
                                  ),
                                );
                                
                                // Se retornar true, recarregar a lista para refletir alterações
                                if (result == true) {
                                  _fetchManutencoes();
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          veiculo['placa'] ?? 'Placa não informada',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        Icon(
                                          Icons.directions_car,
                                          color: Colors.red[400],
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Marca: ${veiculo['marca']} ${veiculo['modelo']} ${veiculo['anoModelo']}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Chassi: ${veiculo['chassi']}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Urgencia: ${manutencao['urgencia']}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Text(
                                          'Supervisor: ',
                                          style: TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          manutencao['supervisor']['nome'],
                                          style: const TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Indicador visual de status
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.orange),
                                      ),
                                      child: const Text(
                                        'Pendente',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Data: ${_formatDate(manutencao['dataSolicitacao'])}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}