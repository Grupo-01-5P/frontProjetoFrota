import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart';

class ViewInoperative extends StatefulWidget {
  const ViewInoperative({super.key});

  @override
  State<ViewInoperative> createState() => _ViewInoperativeState();
}

class _ViewInoperativeState extends State<ViewInoperative> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  List<int> buttonStates = [0, 0, 0, 0];

  String userFuncao = '';
  String userNome = '';
  String userEmail = '';

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
    "Serviço finalizado",
    "Serviço em andamento",
    "Chegada no destino de origem",
  ];

  final List<String> descriptionsAnalista = [
    "O veículo saiu do ponto inicial. Acompanhe o trajeto.",
    "A manutenção foi realizada. Aguardando retorno.",
    "O serviço está sendo executado conforme cronograma.",
    "O veículo retornou à origem com sucesso.",
  ];

  @override
  void initState() {
    super.initState();
    loadUserInfo();
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
    int state = buttonStates[index];
    String buttonText;
    Color buttonColor;

    switch (state) {
      case 0:
        buttonText = "Iniciar";
        buttonColor = Colors.grey;
        break;
      case 1:
        buttonText = "Finalizar";
        buttonColor = Colors.amber;
        break;
      case 2:
        buttonText = "Concluído";
        buttonColor = Colors.green;
        break;
      default:
        buttonText = "Iniciar";
        buttonColor = Colors.grey;
    }

    bool isActive = (index == 0) || (buttonStates[index - 1] == 2);

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
                onPressed: (isActive && state < 2)
                    ? () {
                        setState(() {
                          buttonStates[index]++;
                        });
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Responsável: $userNome",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  descriptionsAnalista[index],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                child: const Text("Concluído"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
