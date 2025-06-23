import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ViewMaintenancePhases extends StatefulWidget {
  final int manutencaoId;

  const ViewMaintenancePhases({super.key, required this.manutencaoId});

  @override
  State<ViewMaintenancePhases> createState() => _ViewMaintenancePhasesState();
}

class _ViewMaintenancePhasesState extends State<ViewMaintenancePhases> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool isLoading = true;
  Map<String, dynamic>? manutencaoData;
  List<dynamic> fases = [];
  Map<String, dynamic>? faseAtiva;

  String userFuncao = '';
  String userNome = '';
  String userEmail = '';
  int userId = 0;

  // Mapeamento de responsabilidades por fase
  final Map<String, String> responsavelPorFase = {
    'INICIAR_VIAGEM': 'supervisor',      // Fase 1 - Supervisor
    'DEIXAR_VEICULO': 'supervisor',      // Fase 2 - Supervisor  
    'SERVICO_FINALIZADO': 'analista',    // Fase 3 - Analista
    'RETORNO_VEICULO': 'supervisor',     // Fase 4 - Supervisor
    'VEICULO_ENTREGUE': 'supervisor',    // Fase 5 - Supervisor
  };

  final List<String> titles = [
    "Iniciar viagem até a oficina",
    "Deixar veículo para manutenção", 
    "Serviço finalizado",
    "Retorno com veículo",
    "Veículo entregue",
  ];

  final List<String> descriptions = [
    "Clique em iniciar para registrar o percurso até a oficina",
    "Inicie e conclua esta etapa quando o veículo for deixado na oficina",
    "Inicie e conclua esta etapa quando a manutenção do veículo for finalizada",
    "Clique em iniciar para registrar o percurso até o ponto de origem",
    "Confirme a entrega do veículo",
  ];

  final List<String> descriptionsAnalista = [
    "O supervisor iniciará a viagem até a oficina",
    "O supervisor deixará o veículo na oficina para manutenção",
    "Confirme quando o serviço de manutenção foi finalizado pela oficina",
    "O supervisor retornará com o veículo",
    "O supervisor confirmará a entrega do veículo",
  ];

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    fetchMaintenancePhases();
  }

  Future<void> fetchMaintenancePhases() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) {
        _showErrorMessage('Token de autenticação não encontrado');
        return;
      }

      final response = await http.get(
        Uri.parse(
          'http://localhost:4040/api/phases/maintenance/${widget.manutencaoId}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (data is List) {
            fases = data;
          } else if (data is Map && data.containsKey('data')) {
            fases = data['data'] ?? [];
          } else {
            fases = [];
          }
          
          faseAtiva = fases.firstWhere(
            (fase) => fase['ativo'] == true,
            orElse: () => null,
          );
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          fases = [];
          faseAtiva = null;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorMessage('Erro ao carregar fases da manutenção: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorMessage('Erro de conexão: $e');
      print('Erro completo: $e');
    }
  }

  Future<void> advanceToNextPhase({String? observacoes}) async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) {
        _showErrorMessage('Token de autenticação não encontrado');
        return;
      }

      final response = await http.post(
        Uri.parse(
          'http://localhost:4040/api/phases/maintenance/${widget.manutencaoId}/advance',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          if (observacoes != null && observacoes.isNotEmpty) 
            'observacoes': observacoes,
        }),
      );

      print('Advance phase response: ${response.statusCode}');
      print('Advance phase body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        // Verifica se a manutenção foi finalizada
        if (data['maintenanceCompleted'] == true) {
          _showMaintenanceCompletedDialog();
        } else {
          // Verifica se há informação sobre transição de fases
          String message = 'Fase avançada com sucesso!';
          if (data['previousPhase'] != null && data['nextPhase'] != null) {
            message = 'Fase "${_getPhaseDisplayName(data['previousPhase'])}" finalizada!\n'
                     'Iniciando "${_getPhaseDisplayName(data['nextPhase'])}"';
          }
          _showSuccessMessage(message);
        }
        
        await fetchMaintenancePhases();
      } else {
        try {
          final errorData = json.decode(response.body);
          _showErrorMessage(errorData['message'] ?? 'Erro ao avançar fase');
        } catch (e) {
          _showErrorMessage('Erro ao avançar fase: ${response.statusCode}');
        }
      }
    } catch (e) {
      _showErrorMessage('Erro ao avançar fase: $e');
      print('Erro completo ao avançar: $e');
    }
  }

  Future<void> createPhase(String tipoFase, {String? observacoes}) async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) {
        _showErrorMessage('Token de autenticação não encontrado');
        return;
      }

      final response = await http.post(
        Uri.parse(
          'http://localhost:4040/api/phases/maintenance/${widget.manutencaoId}/phase',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'tipoFase': tipoFase,
          if (observacoes != null && observacoes.isNotEmpty) 
            'observacoes': observacoes,
        }),
      );

      print('Create phase response: ${response.statusCode}');
      print('Create phase body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSuccessMessage('Fase criada com sucesso!');
        await fetchMaintenancePhases();
      } else {
        try {
          final errorData = json.decode(response.body);
          _showErrorMessage(errorData['message'] ?? 'Erro ao criar fase');
        } catch (e) {
          _showErrorMessage('Erro ao criar fase: ${response.statusCode}');
        }
      }
    } catch (e) {
      _showErrorMessage('Erro ao criar fase: $e');
      print('Erro completo ao criar: $e');
    }
  }

  Future<void> updatePhase(int faseId, {String? observacoes, bool? finalizar}) async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) {
        _showErrorMessage('Token de autenticação não encontrado');
        return;
      }

      final response = await http.put(
        Uri.parse('http://localhost:4040/api/phases/$faseId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          if (observacoes != null) 'observacoes': observacoes,
          if (finalizar != null) 'finalizar': finalizar,
        }),
      );

      print('Update phase response: ${response.statusCode}');
      print('Update phase body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _showSuccessMessage('Fase atualizada com sucesso!');
        await fetchMaintenancePhases();
      } else {
        try {
          final errorData = json.decode(response.body);
          _showErrorMessage(errorData['message'] ?? 'Erro ao atualizar fase');
        } catch (e) {
          _showErrorMessage('Erro ao atualizar fase: ${response.statusCode}');
        }
      }
    } catch (e) {
      _showErrorMessage('Erro ao atualizar fase: $e');
      print('Erro completo ao atualizar: $e');
    }
  }

  Future<void> loadUserInfo() async {
    try {
      userNome = await _secureStorage.read(key: 'user_name') ?? '';
      userEmail = await _secureStorage.read(key: 'user_email') ?? '';
      userFuncao = await _secureStorage.read(key: 'user_function') ?? '';
      final userIdStr = await _secureStorage.read(key: 'user_id') ?? '0';
      userId = int.tryParse(userIdStr) ?? 0;

      print('User info loaded: $userNome, $userFuncao, $userId');
      setState(() {});
    } catch (e) {
      print('Erro ao carregar info do usuário: $e');
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showObservationDialog(Function(String?) callback) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Observação'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Digite uma observação (opcional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final observacao = controller.text.trim();
              callback(observacao.isEmpty ? null : observacao);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  // Função para converter nome técnico em nome amigável
  String _getPhaseDisplayName(String tipoFase) {
    const Map<String, String> phaseNames = {
      'INICIAR_VIAGEM': 'Iniciar Viagem',
      'DEIXAR_VEICULO': 'Deixar Veículo',
      'SERVICO_FINALIZADO': 'Serviço Finalizado',
      'RETORNO_VEICULO': 'Retorno com Veículo',
      'VEICULO_ENTREGUE': 'Veículo Entregue',
    };
    return phaseNames[tipoFase] ?? tipoFase;
  }

  // Dialog especial para conclusão da manutenção
  void _showMaintenanceCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Não pode fechar clicando fora
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 32,
              ),
              const SizedBox(width: 12),
              const Text(
                'Manutenção Concluída!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 48,
                      color: Colors.green[600],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Todas as fases foram finalizadas com sucesso!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manutenção #${widget.manutencaoId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.list, color: Colors.white),
              label: const Text(
                'Voltar às Manutenções',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF148553),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o dialog
                Navigator.of(context).pop(); // Volta para a tela anterior
              },
            ),
          ],
        );
      },
    );
  }

  // Verifica se o usuário atual pode interagir com uma fase específica
  bool _podeInteragirComFase(String tipoFase) {
    final responsavelFase = responsavelPorFase[tipoFase];
    return responsavelFase == userFuncao;
  }

  // Verifica se pode iniciar uma fase baseado na sequência e responsabilidade
  bool _podeIniciarFase(int index, String tipoFase) {
    final List<String> tiposFase = [
      'INICIAR_VIAGEM',
      'DEIXAR_VEICULO', 
      'SERVICO_FINALIZADO',
      'RETORNO_VEICULO',
      'VEICULO_ENTREGUE'
    ];

    // Verifica se já existe uma fase deste tipo
    bool faseExiste = fases.any((fase) => fase['tipoFase'] == tipoFase);
    if (faseExiste) return false;

    // Verifica se é o responsável por esta fase
    if (!_podeInteragirComFase(tipoFase)) return false;

    // Se é a primeira fase, sempre pode iniciar
    if (index == 0) return true;

    // Verifica se a fase anterior foi concluída
    String faseAnterior = tiposFase[index - 1];
    bool faseAnteriorConcluida = fases.any((fase) => 
      fase['tipoFase'] == faseAnterior && 
      fase['ativo'] == false && 
      fase['dataFim'] != null
    );

    return faseAnteriorConcluida;
  }

  // Widget para mostrar resumo de progresso no topo
  Widget _buildProgressSummary() {
    if (fases.isEmpty) return const SizedBox.shrink();
    
    int fasesCompletas = fases.where((fase) => 
      fase['ativo'] == false && fase['dataFim'] != null
    ).length;
    
    double progresso = fasesCompletas / 5.0;
    bool manutencaoConcluida = fasesCompletas == 5;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: manutencaoConcluida ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: manutencaoConcluida ? Colors.green[200]! : Colors.blue[200]!
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                manutencaoConcluida ? Icons.check_circle : Icons.timeline,
                color: manutencaoConcluida ? Colors.green[700] : Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                manutencaoConcluida ? 'Manutenção Concluída!' : 'Progresso da Manutenção',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: manutencaoConcluida ? Colors.green[700] : Colors.blue[700],
                ),
              ),
              const Spacer(),
              Text(
                '$fasesCompletas/5 fases',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: manutencaoConcluida ? Colors.green[600] : Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progresso,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              manutencaoConcluida ? Colors.green : Colors.blue
            ),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  // Função helper para obter data de finalização formatada
  String _getDataFinalizacao(String tipoFase) {
    final fase = fases.firstWhere(
      (fase) => fase['tipoFase'] == tipoFase,
      orElse: () => null,
    );
    
    if (fase != null && fase['dataFim'] != null) {
      try {
        final data = DateTime.parse(fase['dataFim']);
        return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        return 'Data inválida';
      }
    }
    
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color.fromARGB(250, 250, 250, 250),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF148553),
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Fases da Manutenção #${widget.manutencaoId}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Carregando fases...'),
                      ],
                    ),
                  ),
                )
              else ...[
                _buildProgressSummary(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: fetchMaintenancePhases,
                    child: ListView.builder(
                      itemCount: 5, // 5 fases possíveis
                      itemBuilder: (context, index) {
                        return buildPhaseCard(index);
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.7),
                  blurRadius: 20.0,
                  spreadRadius: 5.0,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: 2,
              onTap: (index) {
                if (index == 0) {
                  Navigator.pop(context);
                } else if (index == 1) {
                  // Orçamentos
                }
              },
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.black,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              items: [
                BottomNavigationBarItem(
                  icon: SizedBox(
                    width: 30,
                    height: 30,
                    child: Image.asset('lib/assets/images/iconManutencoes.png'),
                  ),
                  label: 'Manutenções',
                ),
                BottomNavigationBarItem(
                  icon: SizedBox(
                    width: 30,
                    height: 30,
                    child: Image.asset('lib/assets/images/iconTerceirize.png'),
                  ),
                  label: 'Orçamentos',
                ),
                BottomNavigationBarItem(
                  icon: SizedBox(
                    width: 30,
                    height: 30,
                    child: Image.asset('lib/assets/images/iconInoperantes.png'),
                  ),
                  label: 'Fases',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPhaseCard(int index) {
    final List<String> tiposFase = [
      'INICIAR_VIAGEM',
      'DEIXAR_VEICULO', 
      'SERVICO_FINALIZADO',
      'RETORNO_VEICULO',
      'VEICULO_ENTREGUE'
    ];
    
    String tipoFaseAtual = tiposFase[index];
    String responsavelFase = responsavelPorFase[tipoFaseAtual] ?? '';
    bool isMinhaResponsabilidade = _podeInteragirComFase(tipoFaseAtual);
    
    // Estados da fase
    bool faseExiste = fases.any((fase) => fase['tipoFase'] == tipoFaseAtual);
    bool faseConcluida = fases.any((fase) => 
      fase['tipoFase'] == tipoFaseAtual && fase['ativo'] == false && fase['dataFim'] != null
    );
    bool isFaseAtiva = faseAtiva != null && faseAtiva!['tipoFase'] == tipoFaseAtual;
    bool podeIniciar = _podeIniciarFase(index, tipoFaseAtual);

    // Determinar estado do botão
    String buttonText;
    Color buttonColor;
    VoidCallback? onPressed;

    if (faseConcluida) {
      buttonText = "Concluído";
      buttonColor = Colors.green;
      onPressed = null;
    } else if (isFaseAtiva && isMinhaResponsabilidade) {
      // Texto especial para a última fase
      if (tipoFaseAtual == 'VEICULO_ENTREGUE') {
        buttonText = "Finalizar Manutenção";
        buttonColor = Colors.green[600]!;
      } else {
        buttonText = "Finalizar";
        buttonColor = Colors.amber;
      }
      onPressed = () => _showObservationDialog((observacao) => advanceToNextPhase(observacoes: observacao));
    } else if (podeIniciar && isMinhaResponsabilidade) {
      buttonText = "Iniciar";
      buttonColor = const Color(0xFF148553);
      onPressed = () => _showObservationDialog((observacao) => createPhase(tipoFaseAtual, observacoes: observacao));
    } else if (isFaseAtiva && !isMinhaResponsabilidade) {
      buttonText = "Em Andamento";
      buttonColor = Colors.orange;
      onPressed = null;
    } else if (!isMinhaResponsabilidade && !faseExiste) {
      buttonText = "Aguardando ${responsavelFase}";
      buttonColor = Colors.grey;
      onPressed = null;
    } else {
      buttonText = "Aguardando";
      buttonColor = Colors.grey;
      onPressed = null;
    }

    // Determinar se o card está ativo
    bool isActive = faseConcluida || isFaseAtiva || podeIniciar;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: isActive ? Colors.white : Colors.grey[100],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com número e responsável
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: faseConcluida 
                        ? Colors.green 
                        : isFaseAtiva 
                            ? Colors.amber 
                            : podeIniciar 
                                ? const Color(0xFF148553) 
                                : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: faseConcluida 
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titles[index],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.black : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isMinhaResponsabilidade 
                              ? const Color(0xFF148553).withOpacity(0.1)
                              : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isMinhaResponsabilidade 
                                ? const Color(0xFF148553) 
                                : Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Responsável: ${responsavelFase.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isMinhaResponsabilidade 
                                ? const Color(0xFF148553) 
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Ícone de status adicional
                if (faseConcluida)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.done_all,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Descrição
            Text(
              userFuncao == 'analista' ? descriptionsAnalista[index] : descriptions[index],
              style: TextStyle(
                fontSize: 16,
                color: isActive ? Colors.black87 : Colors.black54,
              ),
            ),
            
            // Informações da fase se existir
            if (faseExiste) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: faseConcluida ? Colors.green[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: faseConcluida ? Colors.green[200]! : Colors.blue[200]!
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 4),
                        Text(
                          "Executado por: ${_getResponsavelName(tipoFaseAtual)}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: faseConcluida ? Colors.green[700] : Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    if (_getObservacoes(tipoFaseAtual).isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.comment,
                            size: 14,
                            color: faseConcluida ? Colors.green[600] : Colors.blue[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "Observações: ${_getObservacoes(tipoFaseAtual)}",
                              style: TextStyle(
                                fontSize: 13,
                                color: faseConcluida ? Colors.green[600] : Colors.blue[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Mostrar data de conclusão se a fase foi finalizada
                    if (faseConcluida) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.green[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Finalizada: ${_getDataFinalizacao(tipoFaseAtual)}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Botão de ação
            Center(
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: buttonColor,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  elevation: onPressed != null ? 2 : 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tipoFaseAtual == 'VEICULO_ENTREGUE' && isFaseAtiva && isMinhaResponsabilidade) ...[
                      const Icon(Icons.flag, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getResponsavelName(String tipoFase) {
    final fase = fases.firstWhere(
      (fase) => fase['tipoFase'] == tipoFase,
      orElse: () => null,
    );
    
    if (fase != null && fase['responsavel'] != null) {
      return fase['responsavel']['nome'] ?? 'N/A';
    }
    
    return 'N/A';
  }

  String _getObservacoes(String tipoFase) {
    final fase = fases.firstWhere(
      (fase) => fase['tipoFase'] == tipoFase,
      orElse: () => null,
    );
    
    if (fase != null && fase['observacoes'] != null) {
      return fase['observacoes'];
    }
    
    return '';
  }
}