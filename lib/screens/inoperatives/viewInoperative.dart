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

  String userFuncao = '';
  String userNome = '';
  String userEmail = '';

  // Enum para controle das fases
  final Map<String, int> fasesEnum = {
    'FASE1': 0,
    'FASE2': 1,
    'FASE3': 2,
    'FASE4': 3,
  };

  final List<String> titles = [
    "Iniciar viagem até a mecânica",
    "Deixar veículo para manutenção",
    "Serviço finalizado",
    "Retorno com veículo",
  ];

  final List<String> addresses = [
    "Clique em iniciar para registrar o percurso até a mecânica",
    "Inicie e conclua esta etapa quando o veículo for deixado na mecânica",
    "Inicie e conclua esta etapa quando a manutenção do veículo for finalizada",
    "Clique em iniciar para registrar o percurso até o ponto de origem",
  ];

  final List<String> titlesAnalista = [
    "Ponto de partida",
    "Serviço em andamento",
    "Serviço finalizado",
    "Chegada no destino de origem",
  ];

  final List<String> descriptionsAnalista = [
    "O veículo saiu do ponto inicial. Acompanhe o trajeto.",
    "O serviço está sendo executado conforme cronograma.",
    "A manutenção foi realizada. Aguardando retorno.",
    "O veículo retornou à origem com sucesso.",
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
      final token = await _secureStorage.read(key: 'token');
      final response = await http.get(
        Uri.parse(
          'http://localhost:4040/inoperative/inoperative/${widget.inoperanteId}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          inoperanteData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        // Tratar erro aqui
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Tratar erro aqui
    }
  }

  Future<void> fetchPhaseInfo() async {
    try {
      final token = await _secureStorage.read(key: 'token');
      final response = await http.get(
        Uri.parse(
          'http://localhost:4040/inoperative/${widget.inoperanteId}/phase',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          faseAtual = data['faseAtual'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Erro ao buscar fase: $e');
    }
  }

  Future<void> updatePhase(String novaFase) async {
    try {
      final token = await _secureStorage.read(key: 'token');
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

      if (response.statusCode == 200) {
        setState(() {
          faseAtual = novaFase;
        });
      } else {
        // Tratar erro aqui
        print('Erro ao atualizar fase');
      }
    } catch (e) {
      print('Erro ao atualizar fase: $e');
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
                  itemCount: 4,
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
    String buttonText;
    Color buttonColor;

    // Verifica se é a fase atual
    bool isFaseAtual = faseAtual != null && fasesEnum[faseAtual] == index;
    // Verifica se é uma fase anterior à atual
    bool isFaseAnterior = faseAtual != null && fasesEnum[faseAtual]! > index;

    if (isFaseAnterior) {
      buttonText = "Concluído";
      buttonColor = Colors.green;
    } else if (isFaseAtual) {
      buttonText = "Concluir";
      buttonColor = Colors.amber;
    } else {
      buttonText = "Iniciar";
      buttonColor = Colors.grey;
    }

    bool isActive =
        index == 0 || (faseAtual != null && fasesEnum[faseAtual]! >= index - 1);

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
                onPressed:
                    (isActive && !isFaseAnterior && userFuncao == 'supervisor')
                        ? () {
                          String proximaFase = 'FASE${index + 2}';
                          updatePhase(proximaFase);
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
    // Verifica se é a fase atual
    bool isFaseAtual = faseAtual != null && fasesEnum[faseAtual] == index;
    // Verifica se é uma fase anterior à atual
    bool isFaseAnterior = faseAtual != null && fasesEnum[faseAtual]! > index;
    // Verifica se o supervisor está na fase de serviço finalizado
    bool supervisorEmFase3 = faseAtual == 'FASE3';

    // Define o texto e cor do botão baseado no status
    String buttonText;
    Color buttonColor;

    if (isFaseAnterior) {
      buttonText = "Concluído";
      buttonColor = Colors.green;
    } else if (isFaseAtual) {
      buttonText = "Em Andamento";
      buttonColor = Colors.amber;
    } else {
      buttonText = "Aguardando";
      buttonColor = Colors.grey;
    }

    // Para a fase 3 (índice 2), configuração especial quando está ativa
    if (index == 2 && isFaseAtual) {
      buttonText = "Concluir";
      buttonColor = Colors.amber;
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
                  descriptionsAnalista[index],
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
                onPressed:
                    (index == 2 &&
                            isFaseAtual) // Só habilita o botão na fase 3 quando ativa
                        ? () {
                          String proximaFase = 'FASE${index + 2}';
                          updatePhase(proximaFase);
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
