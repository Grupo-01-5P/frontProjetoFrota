import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_page.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicles_page.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicle_service.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VehiclesRegister extends StatefulWidget {
  const VehiclesRegister({Key? key}) : super(key: key);

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
  final _secureStorage = const FlutterSecureStorage();
  
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
  
  TipoVeiculo? _selectedTipo;
  int? _selectedSupervisorId;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Lista de supervisores
  List<Map<String, dynamic>> _supervisores = [];
  bool _isLoadingSupervisores = false;

  @override
  void initState() {
    super.initState();
    _loadSupervisores();
  }

  @override
  void dispose() {
    _placaController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _anoFabController.dispose();
    _anoModController.dispose();
    _corController.dispose();
    _renevamController.dispose();
    _chassiController.dispose();
    _empresaController.dispose();
    _departamentoController.dispose();
    super.dispose();
  }

  // Carregar supervisores da API
  Future<void> _loadSupervisores() async {
    setState(() {
      _isLoadingSupervisores = true;
    });

    try {
      final token = await _secureStorage.read(key: 'auth_token');
      
      if (token == null) {
        print('Token não encontrado');
        setState(() {
          _isLoadingSupervisores = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:4040/api/users/?_limit=100&funcao=supervisor'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _supervisores = List<Map<String, dynamic>>.from(data['data']);
          _isLoadingSupervisores = false;
        });
      } else {
        print('Erro ao carregar supervisores: ${response.statusCode}');
        setState(() {
          _isLoadingSupervisores = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar supervisores: $e');
      setState(() {
        _isLoadingSupervisores = false;
      });
    }
  }

  Widget _buildSupervisorDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Supervisor',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _isLoadingSupervisores
            ? Container(
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : DropdownButtonFormField<int>(
                value: _selectedSupervisorId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: _supervisores.map((supervisor) {
                  return DropdownMenuItem<int>(
                    value: supervisor['id'],
                    child: Text('${supervisor['nome']} (${supervisor['email']})'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedSupervisorId = value),
                validator: (value) => value == null ? 'Selecione um supervisor' : null,
                hint: const Text('Selecione um supervisor'),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      
      // AppBar padronizado
      appBar: AppBar(
        leading: Container(
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
            icon: const Icon(Icons.arrow_back, color: Colors.black54),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: const Text(
          'Cadastrar Veículo',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      // Ação para notificações
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
      // Body padronizado
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mensagem de erro (se houver)
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),

                // Campo Placa do Veículo
                const Text(
                  'Placa do Veículo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _placaController,
                  decoration: InputDecoration(
                    hintText: 'Informe a placa do veículo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe a placa do veículo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Campo Marca
                const Text(
                  'Marca',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _marcaController,
                  decoration: InputDecoration(
                    hintText: 'Informe a marca do veículo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe a marca do veículo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Campo Modelo
                const Text(
                  'Modelo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _modeloController,
                  decoration: InputDecoration(
                    hintText: 'Informe o modelo do veículo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe o modelo do veículo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Campo Ano de Fabricação
                const Text(
                  'Ano de Fabricação',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _anoFabController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Ex: 2023',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe o ano de fabricação';
                    }
                    final ano = int.tryParse(value);
                    if (ano == null) return 'Digite um ano válido';
                    if (ano <= 1900) return 'Ano deve ser > 1900';
                    if (ano > 2026) return 'Ano deve ser ≤ 2026';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Campo Ano do Modelo
                const Text(
                  'Ano do Modelo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _anoModController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Ex: 2023',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe o ano do modelo';
                    }
                    final ano = int.tryParse(value);
                    if (ano == null) return 'Digite um ano válido';
                    if (ano <= 1900) return 'Ano deve ser > 1900';
                    if (ano > 2026) return 'Ano deve ser ≤ 2026';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Campo Cor
                const Text(
                  'Cor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _corController,
                  decoration: InputDecoration(
                    hintText: 'Informe a cor do veículo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe a cor do veículo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Campo RENAVAM
                const Text(
                  'RENAVAM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _renevamController,
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '11 dígitos',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe o RENAVAM';
                    }
                    if (value.length != 11) return 'Deve ter 11 dígitos';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Campo Chassi
                const Text(
                  'Chassi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _chassiController,
                  keyboardType: TextInputType.text,
                  maxLength: 17,
                  inputFormatters: [LengthLimitingTextInputFormatter(17)],
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '17 caracteres alfanuméricos',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe o chassi';
                    }
                    if (value.length != 17) return 'Deve ter 17 caracteres';
                    if (!RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(value)) {
                      return 'Formato inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Campo Empresa
                const Text(
                  'Empresa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _empresaController,
                  decoration: InputDecoration(
                    hintText: 'Informe a empresa responsável',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe a empresa responsável';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Campo Departamento
                const Text(
                  'Departamento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _departamentoController,
                  decoration: InputDecoration(
                    hintText: 'Informe o departamento responsável',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe o departamento responsável';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Campo Tipo de Veículo (Dropdown)
                const Text(
                  'Tipo de Veículo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<TipoVeiculo>(
                  value: _selectedTipo,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  items: TipoVeiculo.values.map((tipo) {
                    return DropdownMenuItem<TipoVeiculo>(
                      value: tipo,
                      child: Text(tipo.value),
                    );
                  }).toList(),
                  onChanged: (TipoVeiculo? newValue) {
                    setState(() => _selectedTipo = newValue);
                  },
                  validator: (value) => value == null ? 'Selecione um tipo de veículo' : null,
                  hint: const Text('Selecione um tipo'),
                ),
                const SizedBox(height: 20),

                // Campo Supervisor (Dropdown Dinâmico)
                _buildSupervisorDropdownField(),
                const SizedBox(height: 30),

                // Botões de ação
                Row(
                  children: [
                    // Botão Cancelar
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF67E7E),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Botão Cadastrar
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4EB699),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Cadastrar',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
              Navigator.pop(context, true); // Retorna true para indicar que houve alteração
            },
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

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
          setState(() {
            _errorMessage = 'Esta placa já está cadastrada no sistema';
            _isLoading = false;
          });
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
          "supervisorId": _selectedSupervisorId,
        };

        final response = await VehicleService().createVehicle(payload);

        if (response['id'] != null) {
          _showSuccessDialog();
        } else {
          throw Exception('Erro ao cadastrar veículo');
        }
      } on FormatException {
        setState(() {
          _errorMessage = 'Erro: Verifique os campos numéricos';
          _isLoading = false;
        });
      } catch (e) {
        String errorMessage = e.toString();

        // Tratamento especial para erro 500 (placa existente)
        if (errorMessage.contains('500') ||
            errorMessage.contains('já existe')) {
          errorMessage = 'Esta placa já está cadastrada no sistema';
        }

        setState(() {
          _errorMessage = 'Erro: $errorMessage';
          _isLoading = false;
        });
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
      _errorMessage = null;
      _isLoading = false;
    });
  }
}