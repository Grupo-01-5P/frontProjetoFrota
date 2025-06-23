import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:front_projeto_flutter/screens/maintenences/manutencao_detalhe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class ManutencoesGeralScreen extends StatefulWidget {
  const ManutencoesGeralScreen({Key? key}) : super(key: key);

  @override
  _ManutencoesGeralScreenState createState() => _ManutencoesGeralScreenState();
}

class _ManutencoesGeralScreenState extends State<ManutencoesGeralScreen> {
  final _secureStorage = const FlutterSecureStorage();
  bool _isLoading = true;
  List<dynamic> _manutencoes = [];
  String? _errorMessage;
  String _filtroAtivo = 'aprovada'; // Filtro inicial: Aprovadas (Em Andamento)

  @override
  void initState() {
    super.initState();
    _fetchManutencoes();
  }

  // Função para buscar manutenções com status específico
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

      final url = Uri.parse('http://localhost:4040/api/maintenance/?status=$_filtroAtivo');
      
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
  String _formatDate(String? dateString) {
    if (dateString == null) return "Data não informada";
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Função para obter cor baseada no status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aprovada':
        return const Color(0xFF0C7E3D); // Verde para aprovada/em andamento
      case 'reprovada':
        return Colors.red; // Vermelho para Reprovada
      case 'concluída':
        return Colors.blue; // Azul para concluída
      default:
        return Colors.grey; // Cinza para outros status
    }
  }

  // Função para obter cor da fase
  Color _getFaseColor(String? tipoFase) {
    if (tipoFase == null) return Colors.grey;
    
    switch (tipoFase) {
      case 'INICIAR_VIAGEM':
        return Colors.orange;
      case 'DEIXAR_VEICULO':
        return Colors.blue;
      case 'SERVICO_FINALIZADO':
        return Colors.lightGreen;
      case 'RETORNO_VEICULO':
        return Colors.deepOrange;
      case 'VEICULO_ENTREGUE':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Função para obter ícone da fase
  IconData _getFaseIcon(String? tipoFase) {
    if (tipoFase == null) return Icons.help_outline;
    
    switch (tipoFase) {
      case 'INICIAR_VIAGEM':
        return Icons.directions_car;
      case 'DEIXAR_VEICULO':
        return Icons.garage;
      case 'SERVICO_FINALIZADO':
        return Icons.build_circle;
      case 'RETORNO_VEICULO':
        return Icons.keyboard_return;
      case 'VEICULO_ENTREGUE':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  // Função para exibir o texto de status correto
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'aprovada':
        return 'Em Andamento';
      case 'reprovada':
        return 'Reprovada';
      case 'concluída':
        return 'Concluída';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manutenções'),
        backgroundColor: const Color(0xFF0C7E3D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchManutencoes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs de filtro
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _filtroAtivo = 'aprovada';
                      });
                      _fetchManutencoes();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _filtroAtivo == 'aprovada'
                            ? const Color(0xFF0C7E3D)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Em Andamento',
                          style: TextStyle(
                            color: _filtroAtivo == 'aprovada'
                                ? Colors.white
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _filtroAtivo = 'concluída';
                      });
                      _fetchManutencoes();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _filtroAtivo == 'concluída'
                            ? const Color(0xFF0C7E3D)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Concluídas',
                          style: TextStyle(
                            color: _filtroAtivo == 'concluída'
                                ? Colors.white
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _filtroAtivo = 'reprovada';
                      });
                      _fetchManutencoes();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _filtroAtivo == 'reprovada'
                            ? const Color(0xFF0C7E3D)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Reprovadas',
                          style: TextStyle(
                            color: _filtroAtivo == 'reprovada'
                                ? Colors.white
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Exibir indicador de carregamento, erro ou lista de manutenções
          _isLoading
              ? const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0C7E3D),
                    ),
                  ),
                )
              : _errorMessage != null
                  ? Expanded(
                      child: Center(
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
                              child: const Text(
                                'Tentar novamente',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _manutencoes.isEmpty
                      ? Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.build_circle_outlined,
                                  color: Colors.grey[400],
                                  size: 60,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhuma manutenção ${_getStatusText(_filtroAtivo).toLowerCase()} encontrada',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Expanded(
                          child: RefreshIndicator(
                            onRefresh: _fetchManutencoes,
                            color: const Color(0xFF0C7E3D),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _manutencoes.length,
                              itemBuilder: (context, index) {
                                final manutencao = _manutencoes[index];
                                final veiculo = manutencao['veiculo'];
                                final status = manutencao['status'] ?? 'Desconhecido';
                                final faseAtual = manutencao['faseAtual'];
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ManutencaoDetailScreen(
                                            manutencao: manutencao,
                                            oficina: manutencao['oficina'],
                                          ),
                                        ),
                                      );
                                      
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
                                                'Manutenção #${manutencao['id']}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(status).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  _getStatusText(status),
                                                  style: TextStyle(
                                                    color: _getStatusColor(status),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          // NOVA SEÇÃO: Mostrar fase atual
                                          if (faseAtual != null) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: _getFaseColor(faseAtual['tipoFase']).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: _getFaseColor(faseAtual['tipoFase']).withOpacity(0.3),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    _getFaseIcon(faseAtual['tipoFase']),
                                                    color: _getFaseColor(faseAtual['tipoFase']),
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'Fase Atual: ${faseAtual['descricaoFase'] ?? faseAtual['tipoFase']}',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.w500,
                                                            color: _getFaseColor(faseAtual['tipoFase']),
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                        if (faseAtual['emAndamento'] == true)
                                                          Text(
                                                            'Em andamento desde ${_formatDate(faseAtual['dataInicio'])}',
                                                            style: const TextStyle(
                                                              fontSize: 11,
                                                              color: Colors.grey,
                                                            ),
                                                          ),
                                                        if (faseAtual['responsavel'] != null)
                                                          Text(
                                                            'Responsável: ${faseAtual['responsavel']['nome']}',
                                                            style: const TextStyle(
                                                              fontSize: 11,
                                                              color: Colors.grey,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (faseAtual['emAndamento'] == true)
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: BoxDecoration(
                                                        color: Colors.green,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],

                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              const Icon(Icons.directions_car, size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text('Veículo: ${veiculo['placa']} - ${veiculo['marca']} ${veiculo['modelo']}'),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.build, size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Problema: ${manutencao['descricaoProblema']?.length > 50 ? '${manutencao['descricaoProblema']?.substring(0, 50)}...' : manutencao['descricaoProblema'] ?? 'Não especificado'}',
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text('Data: ${_formatDate(manutencao['dataSolicitacao'])}'),
                                            ],
                                          ),
                                          
                                          if (status.toLowerCase() == 'reprovada' && manutencao['motivoReprovacao'] != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.red[50],
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: Colors.red.shade200),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Motivo da reprovação:',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.red,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      manutencao['motivoReprovacao'],
                                                      style: const TextStyle(fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 16),
                                          Center(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF0C7E3D),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                minimumSize: const Size(200, 40),
                                              ),
                                              onPressed: () async {
                                                final result = await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ManutencaoDetailScreen(
                                                      manutencao: manutencao,
                                                      oficina: manutencao['oficina'],
                                                    ),
                                                  ),
                                                );
                                                
                                                if (result == true) {
                                                  _fetchManutencoes();
                                                }
                                              },
                                              child: const Text(
                                                'Ver detalhes',
                                                style: TextStyle(color: Colors.white),
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
                        ),
        ],
      ),
    );
  }
}