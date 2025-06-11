import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_page.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_details.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicles_page.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicle_service.dart';
import 'package:flutter/services.dart';

final List<int> supervisorIds = [3];

class VehiclesRegister extends StatefulWidget {
  const VehiclesRegister({super.key});

  @override
  _VehiclesRegisterState createState() => _VehiclesRegisterState();
}

enum TipoVeiculo {
  carro('carro'),
  moto('moto'),
  caminhao('caminhão'),
  onibus('ônibus'),
  van('van');

  final String value;
  const TipoVeiculo(this.value);
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
  TipoVeiculo? _selectedTipo;
  int? _selectedSupervisorId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Cabeçalho do menu
            UserAccountsDrawerHeader(
              accountName: const Text('Kelvin'),
              accountEmail: const Text('Editar minhas informações'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.person, size: 40, color: Colors.grey),
              ),
              decoration: const BoxDecoration(color: Colors.green),
            ),

            // Itens do menu
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
              onTap: () {
                // Ação para Visualizar manutenções
              },
            ),
            _buildDrawerItem(
              icon: Icons.warning,
              text: 'Veículos inoperantes',
              onTap: () {
                // Ação para Veículos inoperantes
              },
            ),
            _buildDrawerItem(
              icon: Icons.bar_chart,
              text: 'Dashboards',
              onTap: () {
                // Ação para Dashboards
              },
            ),
            _buildDrawerItem(
              icon: Icons.store,
              text: 'Mecânicas',
              onTap: () {
                // Ação para Mecânicas
              },
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
              onTap: () {
                // Ação para Configurações
              },
            ),
            _buildDrawerItem(
              icon: Icons.exit_to_app,
              text: 'Sair',
              iconColor: Colors.red,
              onTap: () {
                // Ação para Sair
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
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
                        _buildStandardField(
                          'Placa do Veículo',
                          _placaController,
                        ),
                        _buildStandardField('Marca', _marcaController),
                        _buildStandardField('Modelo', _modeloController),
                        _buildAnoField('Ano de Fabricação', _anoFabController),
                        _buildAnoField('Ano do Modelo', _anoModController),
                        _buildStandardField('Cor', _corController),
                        _buildRenevamField(),
                        _buildChassiField(),
                        _buildStandardField('Empresa', _empresaController),
                        _buildStandardField(
                          'Departamento',
                          _departamentoController,
                        ),
                        _buildTipoVeiculoDropdown(),
                        _buildSupervisorDropdown(),

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

          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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

  Widget _buildStandardField(
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
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Campo obrigatório';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnoField(String label, TextEditingController controller) {
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
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              hintText: 'Ex: 2023',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Campo obrigatório';
              final ano = int.tryParse(value);
              if (ano == null) return 'Digite um ano válido';
              if (ano <= 1900) return 'Ano deve ser > 1900';
              if (ano > 2026) return 'Ano deve ser ≤ 2026';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTipoVeiculoDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo de Veículo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          DropdownButtonFormField<TipoVeiculo>(
            value: _selectedTipo,
            items:
                TipoVeiculo.values.map((tipo) {
                  return DropdownMenuItem<TipoVeiculo>(
                    value: tipo,
                    child: Text(tipo.value),
                  );
                }).toList(),
            onChanged: (TipoVeiculo? newValue) {
              setState(() => _selectedTipo = newValue);
            },
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) => value == null ? 'Selecione um tipo' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildRenevamField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RENAVAM',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: _renevamController,
            keyboardType: TextInputType.number,
            maxLength: 11,
            inputFormatters: [LengthLimitingTextInputFormatter(11)],
            decoration: InputDecoration(
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              hintText: '11 dígitos',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Campo obrigatório';
              if (value.length != 11) return 'Deve ter 11 dígitos';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChassiField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chassi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: _chassiController,
            keyboardType: TextInputType.text,
            maxLength: 17,
            inputFormatters: [LengthLimitingTextInputFormatter(17)],
            decoration: InputDecoration(
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              hintText: '17 caracteres alfanuméricos',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Campo obrigatório';
              if (value.length != 17) return 'Deve ter 17 caracteres';
              if (!RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(value)) {
                return 'Formato inválido';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Supervisor',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          DropdownButtonFormField<int>(
            value: _selectedSupervisorId,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items:
                supervisorIds.map((int id) {
                  return DropdownMenuItem<int>(
                    value: id,
                    child: Text('Supervisor $id'),
                  );
                }).toList(),
            onChanged: (int? newId) {
              setState(() => _selectedSupervisorId = newId);
            },
            validator:
                (value) => value == null ? 'Selecione um supervisor' : null,
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
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Sucesso!'),
            content: const Text('Veículo cadastrado com sucesso.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearForm();
                },
                child: const Text('Novo Cadastro'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => VehiclesPage()),
                  );
                },
                child: const Text('Ver Veículos'),
              ),
            ],
          ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Verifica se a placa já existe
        final placa = _placaController.text;
        final placaExiste = await VehicleService().checkPlacaExistente(placa);
        final anoFabricacao = int.parse(_anoFabController.text);
        final anoModelo = int.parse(_anoModController.text);

        if (anoFabricacao <= 1900 || anoModelo <= 1900) {
          throw Exception('Ano deve ser maior que 1900');
        }
        if (anoFabricacao > 2026 || anoModelo > 2026) {
          throw Exception('Ano deve ser menor ou igual a 2026');
        }

        if (placaExiste) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Esta placa já está cadastrada no sistema'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        // Se a placa não existe, continua com o cadastro
        final payload = {
          "placa": placa,
          "marca": _marcaController.text,
          "modelo": _modeloController.text,
          "anoFabricacao": anoFabricacao,
          "anoModelo": anoModelo,
          "cor": _corController.text,
          "renavam": _renevamController.text,
          "chassi": _chassiController.text,
          "empresa": _empresaController.text,
          "departamento": _departamentoController.text,
          "tipoVeiculo": _selectedTipo?.value ?? 'carro',
          "supervisorId": _selectedSupervisorId ?? 1,
        };

        final response = await VehicleService().createVehicle(payload);

        if (response['id'] != null) {
          _showSuccessDialog();
          _clearForm();
        } else {
          throw Exception('Erro ao cadastrar veículo');
        }
      } on FormatException {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: Verifique os campos numéricos'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        String errorMessage = e.toString();

        // Tratamento especial para erro 500 (placa existente)
        if (errorMessage.contains('500') ||
            errorMessage.contains('já existe')) {
          errorMessage = 'Esta placa já está cadastrada no sistema';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearForm() {
    _placaController.clear();
    _marcaController.clear();
    _modeloController.clear();
    _anoFabController.clear();
    _anoModController.clear();
    _corController.clear();
    _renevamController.clear();
    _chassiController.clear();
    _empresaController.clear();
    _departamentoController.clear();
    setState(() {
      _selectedTipo = null;
      _selectedSupervisorId = null;
    });
  }
}
