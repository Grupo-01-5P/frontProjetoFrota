import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:front_projeto_flutter/screens/supervisor/maintenences/manutencao_detalhe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class ManutencoesGeralScreenSupervisor extends StatefulWidget {
  const ManutencoesGeralScreenSupervisor({Key? key}) : super(key: key);

  @override
  _ManutencoesGeralScreenSupervisorState createState() =>
      _ManutencoesGeralScreenSupervisorState();
}

class _ManutencoesGeralScreenSupervisorState
    extends State<ManutencoesGeralScreenSupervisor> {
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

      // Construir URL com o filtro apropriado
      // Nota: Ajustar para seu ambiente - usar 10.0.2.2 para emulador Android
      // Se seu backend não suporta filtragem por status diretamente, você precisará
      // implementar a filtragem do lado do cliente
      final url = Uri.parse(
        'http://localhost:4040/api/maintenence/?status=$_filtroAtivo',
      );

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
      case 'localhost':
        return const Color(0xFF0C7E3D); // Verde para aprovada/em andamento
      case 'Reprovada':
        return Colors.red; // Vermelho para Reprovada
      case 'concluída':
        return Colors.blue; // Azul para concluída
      default:
        return Colors.grey; // Cinza para outros status
    }
  }

  // Função para exibir o texto de status correto
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'aprovada':
        return 'Em Andamento';
      case 'Reprovada':
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
                        color:
                            _filtroAtivo == 'aprovada'
                                ? const Color(0xFF0C7E3D)
                                : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Em Andamento',
                          style: TextStyle(
                            color:
                                _filtroAtivo == 'aprovada'
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
                        _filtroAtivo = 'pendente';
                      });
                      _fetchManutencoes();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            _filtroAtivo == 'pendente'
                                ? const Color(0xFF0C7E3D)
                                : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Pendentes',
                          style: TextStyle(
                            color:
                                _filtroAtivo == 'pendente'
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
                        color:
                            _filtroAtivo == 'concluída'
                                ? const Color(0xFF0C7E3D)
                                : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Concluídas',
                          style: TextStyle(
                            color:
                                _filtroAtivo == 'concluída'
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
                        _filtroAtivo = 'Reprovada';
                      });
                      _fetchManutencoes();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            _filtroAtivo == 'Reprovada'
                                ? const Color(0xFF0C7E3D)
                                : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Reprovadas',
                          style: TextStyle(
                            color:
                                _filtroAtivo == 'Reprovada'
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
                  child: CircularProgressIndicator(color: Color(0xFF0C7E3D)),
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
                        style: const TextStyle(fontSize: 16, color: Colors.red),
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
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () async {
                            // Navegar para detalhes da manutenção
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        ManutencaoDetailScreenSupervisor(
                                          manutencao: manutencao,
                                          oficina: manutencao['oficina'],
                                        ),
                              ),
                            );

                            // Recarregar a lista se houver alterações
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                        color: _getStatusColor(
                                          status,
                                        ).withOpacity(0.1),
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
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.directions_car,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Veículo: ${veiculo['placa']} - ${veiculo['marca']} ${veiculo['modelo']}',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.build,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
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
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Localização: ${manutencao['localizacao'] ?? 'Não especificada'}',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Data: ${_formatDate(manutencao['dataSolicitacao'])}',
                                    ),
                                  ],
                                ),
                                if (status.toLowerCase() == 'Reprovada' &&
                                    manutencao['motivoReprovacao'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.red.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
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
                                          builder:
                                              (context) =>
                                                  ManutencaoDetailScreenSupervisor(
                                                    manutencao: manutencao,
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
