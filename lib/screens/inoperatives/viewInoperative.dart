import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ViewInoperative extends StatefulWidget {
  final int inoperanteId;

  const ViewInoperative({super.key, required this.inoperanteId});

  @override
  State<ViewInoperative> createState() => _ViewInoperativeState();
}

class _ViewInoperativeState extends State<ViewInoperative> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool isLoading = true;
  Map<String, dynamic>? inoperanteData;
  String? faseAtual;
  bool faseIniciada = false;  // Novo controle para saber se a fase foi iniciada

  String userFuncao = '';
  String userNome = '';
  String userEmail = '';

  // Enum para controle das fases
  final Map<String, int> fasesEnum = {
    'FASE1': 0,
    'FASE2': 1,
    'FASE3': 2,
    'FASE4': 3,
    'FASE5': 4, // Fase fantasma para controle de conclusão
  };

  // Novo mapa para controlar o estado de cada fase
  final Map<String, String> estadoFases = {
    'FASE1': 'nao_iniciada',  // nao_iniciada -> iniciada -> concluida
    'FASE2': 'nao_iniciada',
    'FASE3': 'nao_iniciada',
    'FASE4': 'nao_iniciada',
  };

  final List<String> titles = [
    "Iniciar viagem até a mecânica",
    "Deixar veículo para manutenção",
    "Serviço finalizado",
    "Retorno com veículo",
    "", // Título vazio para FASE5
  ];

  final List<String> addresses = [
    "Clique em iniciar para registrar o percurso até a mecânica",
    "Inicie e conclua esta etapa quando o veículo for deixado na mecânica",
    "Inicie e conclua esta etapa quando a manutenção do veículo for finalizada",
    "Clique em iniciar para registrar o percurso até o ponto de origem",
    "", // Descrição vazia para FASE5
  ];

  final List<String> titlesAnalista = [
    "Ponto de partida",
    "Serviço em andamento",
    "Serviço finalizado",
    "Chegada no destino de origem",
    "", // Título vazio para FASE5
  ];

  final List<String> descriptionsAnalista = [
    "O veículo saiu do ponto inicial. Acompanhe o trajeto.",
    "O serviço está sendo executado conforme cronograma.",
    "A manutenção foi realizada. Aguardando retorno.",
    "O veículo retornou à origem com sucesso.",
    "", // Descrição vazia para FASE5
  ];

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    fetchInoperanteDetails();
    fetchPhaseInfo();
  }

  Future<void> fetchInoperanteDetails() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      
      if (token == null || token.isEmpty) {
        print('Token não encontrado');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro de autenticação. Por favor, faça login novamente.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('Token: $token');
      print('URL: http://localhost:4040/inoperative/${widget.inoperanteId}');

      final response = await http.get(
        Uri.parse(
          'http://localhost:4040/inoperative/${widget.inoperanteId}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Status code detalhes: ${response.statusCode}');
      print('Resposta detalhes: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            inoperanteData = responseData['data'];
            isLoading = false;
          });
        } else {
          throw Exception(responseData['message'] ?? 'Erro desconhecido');
        }
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sessão expirada. Por favor, faça login novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veículo não encontrado'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? 'Erro ao carregar detalhes do veículo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Erro ao buscar detalhes: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> fetchPhaseInfo() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      
      if (token == null || token.isEmpty) {
        print('Token não encontrado');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro de autenticação. Por favor, faça login novamente.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('Token: $token');
      print('URL: http://localhost:4040/inoperative/${widget.inoperanteId}/phase');

      final response = await http.get(
        Uri.parse(
          'http://localhost:4040/inoperative/${widget.inoperanteId}/phase',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Status code fase: ${response.statusCode}');
      print('Resposta fase: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            faseAtual = responseData['data']['faseAtual'];
            
            // Inicializa os estados das fases anteriores como concluídas
            for (var fase in fasesEnum.keys) {
              if (fasesEnum[fase]! < fasesEnum[faseAtual]!) {
                estadoFases[fase] = 'concluida';
              }
            }

            // Configura o estado da fase atual
            if (faseAtual == 'FASE2') {
              estadoFases[faseAtual!] = 'iniciada';
            } else if (faseAtual == 'FASE4' && userFuncao == 'supervisor') {
              // Garante que a Fase 4 comece como não iniciada para o supervisor
              estadoFases[faseAtual!] = 'nao_iniciada';
            } else {
              // Se não houver estado definido, inicializa como não iniciada
              estadoFases[faseAtual!] ??= 'nao_iniciada';
            }

            isLoading = false;
          });
          print('Fase atual atualizada: $faseAtual');
          print('Estados das fases: $estadoFases');
        } else {
          print('Resposta inválida: $responseData');
          throw Exception(responseData['message'] ?? 'Resposta inválida do servidor');
        }
      } else if (response.statusCode == 401) {
        print('Erro de autenticação');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sessão expirada. Por favor, faça login novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        print('Erro na requisição: ${errorData['message']}');
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? 'Erro ao carregar fase atual'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Erro ao buscar fase: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao buscar fase: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> updatePhase(String novaFase, {bool isInicio = false}) async {
    try {
      setState(() {
        isLoading = true;
      });

      final token = await _secureStorage.read(key: 'auth_token');
      
      if (token == null || token.isEmpty) {
        print('Token não encontrado');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro de autenticação. Por favor, faça login novamente.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Se for início de fase, apenas atualiza o estado local
      // Apenas para Fase 1 e Fase 4
      if (isInicio && (faseAtual == 'FASE1' || faseAtual == 'FASE4')) {
        setState(() {
          faseIniciada = true;
          estadoFases[faseAtual!] = 'iniciada';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fase iniciada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      print('Token: $token');
      print('URL: http://localhost:4040/inoperative/${widget.inoperanteId}/phase');
      print('Dados enviados: ${json.encode({'fase': novaFase})}');

      final response = await http.put(
        Uri.parse(
          'http://localhost:4040/inoperative/${widget.inoperanteId}/phase',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'fase': novaFase}),
      );

      print('Status code atualização: ${response.statusCode}');
      print('Resposta atualização: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            // Marca a fase atual como concluída
            estadoFases[faseAtual!] = 'concluida';
            
            // Se estiver concluindo a FASE4, avança para FASE5
            if (faseAtual == 'FASE4' && !isInicio) {
              novaFase = 'FASE5';
            }
            
            // Atualiza para a nova fase
            faseAtual = novaFase;
            // Reset do estado de início para a nova fase
            faseIniciada = false;
            
            // Se a próxima fase for a Fase 2, já começa como iniciada
            if (novaFase == 'FASE2') {
              estadoFases[novaFase] = 'iniciada';
            }
            
            isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Fase atualizada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );

          // Atualiza os detalhes do veículo após mudar a fase
          await fetchInoperanteDetails();
          await fetchPhaseInfo();
        } else {
          throw Exception(responseData['message'] ?? 'Erro desconhecido');
        }
      } else if (response.statusCode == 401) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sessão expirada. Por favor, faça login novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? 'Erro ao atualizar fase do veículo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Erro ao atualizar fase: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar fase: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método auxiliar para confirmar mudança de fase
  Future<void> confirmarMudancaFase(String novaFase, {bool isInicio = false}) async {
    String titulo;
    String mensagem;

    // Personaliza as mensagens de acordo com a fase
    switch (faseAtual) {
      case 'FASE1':
        if (isInicio) {
          titulo = 'Iniciar viagem';
          mensagem = 'Deseja iniciar a viagem até a mecânica?';
        } else {
          titulo = 'Confirmar chegada';
          mensagem = 'Confirma que chegou à mecânica?';
        }
        break;
      case 'FASE2':
        titulo = 'Confirmar entrega';
        mensagem = 'Confirma que o veículo foi entregue para manutenção?';
        break;
      case 'FASE3':
        titulo = 'Confirmar finalização';
        mensagem = 'Confirma que o serviço foi finalizado?';
        break;
      case 'FASE4':
        if (isInicio) {
          titulo = 'Iniciar retorno';
          mensagem = 'Deseja iniciar o retorno com o veículo?';
        } else {
          titulo = 'Confirmar conclusão';
          mensagem = 'Confirma que o veículo retornou ao ponto de origem?';
        }
        break;
      default:
        titulo = isInicio ? 'Iniciar fase' : 'Confirmar mudança de fase';
        mensagem = isInicio ? 'Deseja iniciar esta fase?' : 'Deseja realmente concluir esta fase?';
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(isInicio ? 'Iniciar' : 'Confirmar'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await updatePhase(novaFase, isInicio: isInicio);
    }
  }

  Future<void> loadUserInfo() async {
    userNome = await _secureStorage.read(key: 'user_name') ?? '';
    userEmail = await _secureStorage.read(key: 'user_email') ?? '';
    userFuncao = await _secureStorage.read(key: 'user_function') ?? '';

    print('Usuário logado - Nome: $userNome');
    print('Usuário logado - Email: $userEmail');
    print('Usuário logado - Função: $userFuncao');

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color.fromARGB(250, 250, 250, 250),
      drawer: CustomDrawer(
        headerColor: const Color(0xFF148553),
        useCustomIcons: true,
      ),
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
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    if (userFuncao == 'supervisor') {
                      return buildVehicleCard(index);
                    } else {
                      return buildAnalistaCard(index);
                    }
                  },
                ),
              ),
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
                  // Manutenções
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
                  label: 'Inoperantes',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildVehicleCard(int index) {
    // Não exibe o card da FASE5
    if (index == 4) return Container();

    // Inicialização com valores padrão
    String buttonText = "Aguardando";
    Color buttonColor = Colors.grey;
    bool buttonEnabled = false;

    // Verifica se é a fase atual
    bool isFaseAtual = faseAtual != null && fasesEnum[faseAtual] == index;
    // Verifica se é uma fase anterior à atual
    bool isFaseAnterior = faseAtual != null && fasesEnum[faseAtual]! > index;

    // Define o estado do botão baseado na fase atual e se foi iniciada
    if (isFaseAnterior) {
      buttonText = "Concluído";
      buttonColor = Colors.green;
      buttonEnabled = false;
    } else if (isFaseAtual) {
      // Comportamento específico para cada fase
      switch (index) {
        case 0: // Fase 1 - comportamento original
          if (estadoFases[faseAtual!] == 'nao_iniciada') {
            buttonText = "Iniciar";
            buttonColor = Colors.blue;
            buttonEnabled = true;
          } else {
            buttonText = "Concluir";
            buttonColor = Colors.amber;
            buttonEnabled = true;
          }
          break;
        
        case 1: // Fase 2 - começa com Concluir
          buttonText = "Concluir";
          buttonColor = Colors.amber;
          buttonEnabled = true;
          break;
        
        case 2: // Fase 3 - Aguardando e bloqueado para supervisor
          buttonText = "Aguardando";
          buttonColor = Colors.grey;
          buttonEnabled = false; // Sempre desabilitado para supervisor
          break;
        
        case 3: // Fase 4 - mesmo modelo da fase 1
          if (estadoFases[faseAtual!] == 'nao_iniciada') {
            buttonText = "Iniciar";
            buttonColor = Colors.blue;
            buttonEnabled = true;
          } else {
            buttonText = "Concluir";
            buttonColor = Colors.amber;
            buttonEnabled = true;
          }
          break;
      }
    }

    bool isActive = index == 0 || (faseAtual != null && fasesEnum[faseAtual]! >= index - 1);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      elevation: 4,
      color: isActive ? Colors.white : Colors.grey[300],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 8),
            Text(
              addresses[index],
              style: TextStyle(
                fontSize: 16,
                color: isActive ? Colors.black : Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: (buttonEnabled && userFuncao == 'supervisor')
                    ? () {
                        if (buttonText == "Iniciar") {
                          confirmarMudancaFase(faseAtual!, isInicio: true);
                        } else if (buttonText == "Concluir") {
                          String proximaFase = 'FASE${index + 2}';
                          confirmarMudancaFase(proximaFase);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: buttonColor,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAnalistaCard(int index) {
    // Não exibe o card da FASE5
    if (index == 4) return Container();

    // Verifica se é a fase atual
    bool isFaseAtual = faseAtual != null && fasesEnum[faseAtual] == index;
    // Verifica se é uma fase anterior à atual
    bool isFaseAnterior = faseAtual != null && fasesEnum[faseAtual]! > index;

    // Inicialização com valores padrão
    String buttonText = "Aguardando";
    Color buttonColor = Colors.grey;
    bool buttonEnabled = false;

    if (isFaseAnterior) {
      buttonText = "Concluído";
      buttonColor = Colors.green;
    } else if (isFaseAtual) {
      // Comportamento específico para cada fase
      switch (index) {
        case 0: // Fase 1
          if (estadoFases[faseAtual!] == 'nao_iniciada') {
            buttonText = "Aguardando Início";
            buttonColor = Colors.grey;
          } else if (estadoFases[faseAtual!] == 'iniciada') {
            buttonText = "Em Andamento";
            buttonColor = Colors.amber;
          } else {
            buttonText = "Concluído";
            buttonColor = Colors.green;
          }
          break;
        
        case 1: // Fase 2 - começa com Em Andamento
          if (estadoFases[faseAtual!] == 'concluida') {
            buttonText = "Concluído";
            buttonColor = Colors.green;
          } else {
            buttonText = "Em Andamento";
            buttonColor = Colors.amber;
          }
          break;
        
        case 2: // Fase 3 - Analista pode concluir
          if (estadoFases[faseAtual!] == 'concluida') {
            buttonText = "Concluído";
            buttonColor = Colors.green;
          } else {
            buttonText = "Concluir";
            buttonColor = Colors.amber;
            buttonEnabled = true; // Apenas o analista pode concluir esta fase
          }
          break;
        
        case 3: // Fase 4
          buttonText = "Em Andamento";
          buttonColor = Colors.amber;
          break;
      }
    }

    // Atualiza a descrição baseada no estado atual da fase
    String descricaoAtual = descriptionsAnalista[index];
    if (isFaseAtual) {
      switch (estadoFases[faseAtual!]) {
        case 'nao_iniciada':
          descricaoAtual = "Aguardando início da fase.";
          break;
        case 'iniciada':
          descricaoAtual = descriptionsAnalista[index];
          break;
        case 'concluida':
          descricaoAtual = "Fase concluída com sucesso.";
          break;
        default:
          descricaoAtual = descriptionsAnalista[index];
      }
    } else if (isFaseAnterior) {
      descricaoAtual = "Fase concluída com sucesso.";
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      elevation: 4,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titlesAnalista[index],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isFaseAtual ? Colors.black : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Responsável: $userNome",
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  descricaoAtual,
                  style: TextStyle(
                    fontSize: 16,
                    color: isFaseAtual ? Colors.black : Colors.black54,
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: ElevatedButton(
                onPressed: buttonEnabled && index == 2 && isFaseAtual
                    ? () {
                        String proximaFase = 'FASE${index + 2}';
                        confirmarMudancaFase(proximaFase);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
