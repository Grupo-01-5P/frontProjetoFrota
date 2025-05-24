import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_page.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_details.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicles_page.dart';

class VehiclesRegister extends StatefulWidget {
  const VehiclesRegister({super.key});

  @override
  _VehiclesRegisterState createState() => _VehiclesRegisterState();
}

class _VehiclesRegisterState extends State<VehiclesRegister> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _placaController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _anoFabController = TextEditingController();
  final TextEditingController _anoModController = TextEditingController();
  final TextEditingController _corController = TextEditingController();
  final TextEditingController _renevamController = TextEditingController();
  final TextEditingController _chassiController = TextEditingController();
  final TextEditingController _empresaController = TextEditingController();
  final TextEditingController _departamentoController = TextEditingController();
  final TextEditingController _tipoController = TextEditingController();
  final TextEditingController _supervisorController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('Kelvin'),
              accountEmail: const Text('Editar minhas informações'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.person, size: 40, color: Colors.grey),
              ),
              decoration: const BoxDecoration(color: Colors.green),
            ),
            _buildDrawerItem(
              icon: Icons.request_quote,
              text: 'Orçamentos',
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => BudgetsPage()));
              },
            ),
            _buildDrawerItem(
              icon: Icons.build,
              text: 'Visualizar manutenções',
              onTap: () {},
            ),
            _buildDrawerItem(
              icon: Icons.warning,
              text: 'Veículos inoperantes',
              onTap: () {},
            ),
            _buildDrawerItem(
              icon: Icons.bar_chart,
              text: 'Dashboards',
              onTap: () {},
            ),
            _buildDrawerItem(
              icon: Icons.store,
              text: 'Mecânicas',
              onTap: () {},
            ),
            _buildDrawerItem(
              icon: Icons.directions_car,
              text: 'Veículos',
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => VehiclesPage()));
              },
            ),
            _buildDrawerItem(
              icon: Icons.settings,
              text: 'Configurações',
              onTap: () {},
            ),
            _buildDrawerItem(
              icon: Icons.exit_to_app,
              text: 'Sair',
              iconColor: Colors.red,
              onTap: () {},
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Conteúdo principal com formulário
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 70, bottom: 80),
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _buildLabelAndField(
                          'Placa do Veículo',
                          _placaController,
                        ),
                        _buildLabelAndField('Marca', _marcaController),
                        _buildLabelAndField('Modelo', _modeloController),
                        _buildLabelAndField(
                          'Ano de Fabricação',
                          _anoFabController,
                          TextInputType.number,
                        ),
                        _buildLabelAndField(
                          'Ano do Modelo',
                          _anoModController,
                          TextInputType.number,
                        ),
                        _buildLabelAndField('Cor', _corController),
                        _buildLabelAndField('Renevam', _renevamController),
                        _buildLabelAndField('Chassi', _chassiController),
                        _buildLabelAndField('Empresa', _empresaController),
                        _buildLabelAndField(
                          'Departamento',
                          _departamentoController,
                        ),
                        _buildLabelAndField('Tipo', _tipoController),
                        _buildLabelAndField(
                          'Supervisor',
                          _supervisorController,
                        ),

                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _submitForm,
                            child: const Text(
                              'Cadastrar Veículo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // AppBar personalizada
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Ícone do menu em círculo branco
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                  ),

                  // Ícone de notificação em círculo branco
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
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
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Manutenções',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'lib/assets/images/_2009906610368.svg',
              width: 24,
              height: 24,
              color: Colors.green,
            ),
            label: 'Orçamentos',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Inoperante',
          ),
        ],
        selectedItemColor: Colors.green,
      ),
    );
  }

  Widget _buildLabelAndField(
    String label,
    TextEditingController controller, [
    TextInputType? keyboardType,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo obrigatório';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color iconColor = Colors.green,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(text),
      onTap: onTap,
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Impede que o modal feche ao clicar fora
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Cadastro realizado!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Veículo cadastrado com sucesso.'),
          actions: [
            TextButton(
              child: const Text('Cadastrar outro'),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o dialog
                // Limpa os campos (já está no seu _submitForm)
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Ir para veículos'),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o dialog
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => VehiclesPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Modifique seu método _submitForm para chamar o dialog
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Processar os dados do formulário

      // Limpar o formulário após o cadastro
      _placaController.clear();
      _modeloController.clear();
      _anoFabController.clear();
      _corController.clear();
      _empresaController.clear();
      _tipoController.clear();
      _chassiController.clear();
      _renevamController.clear();
      _supervisorController.clear();
      _marcaController.clear();
      _anoModController.clear();
      _departamentoController.clear();

      // Mostra o dialog de sucesso
      _showSuccessDialog();
    }
  }
}
