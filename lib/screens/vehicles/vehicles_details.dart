import 'package:flutter/material.dart';
import 'package:front_projeto_flutter/components/custom_drawer.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicle_service.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicles_listage.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VehiclesDetails extends StatefulWidget {
  final int vehicleId;

  const VehiclesDetails({Key? key, required this.vehicleId}) : super(key: key);

  @override
  State<VehiclesDetails> createState() => _VehiclesDetailsState();
}

class _VehiclesDetailsState extends State<VehiclesDetails> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final VehicleService _vehicleService = VehicleService();
  final _secureStorage = const FlutterSecureStorage();
  
  Map<String, dynamic>? _veiculo;
  bool _isLoading = true;
  bool _isEditing = false;
  String? _errorMessage;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controladores para os campos editáveis
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
  String? _selectedTipo;
  int? _selectedSupervisorId;
  
  // Lista de supervisores
  List<Map<String, dynamic>> _supervisores = [];
  bool _isLoadingSupervisores = false;

  @override
  void initState() {
    super.initState();
    _loadVehicleDetails();
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

  Future<void> _loadVehicleDetails() async {
    setState(() {
      _isLoading = true;
      _isEditing = false;
      _errorMessage = null;
    });

    try {
      final response = await _vehicleService.getVehicleDetails(widget.vehicleId);

      setState(() {
        _veiculo = response;
        // Preenche os controladores com os dados atuais
        _placaController.text = _veiculo!['placa'] ?? '';
        _marcaController.text = _veiculo!['marca'] ?? '';
        _modeloController.text = _veiculo!['modelo'] ?? '';
        _anoFabController.text = _veiculo!['anoFabricacao']?.toString() ?? '';
        _anoModController.text = _veiculo!['anoModelo']?.toString() ?? '';
        _corController.text = _veiculo!['cor'] ?? '';
        _renevamController.text = _veiculo!['renavam'] ?? '';
        _chassiController.text = _veiculo!['chassi'] ?? '';
        _empresaController.text = _veiculo!['empresa'] ?? '';
        _departamentoController.text = _veiculo!['departamento'] ?? '';
        _selectedTipo = _veiculo!['tipoVeiculo'] ?? 'carro';
        _selectedSupervisorId = _veiculo!['supervisorId'] ?? _veiculo!['supervisor']?['id'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar detalhes: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final updatedData = {
          "placa": _placaController.text,
          "marca": _marcaController.text,
          "modelo": _modeloController.text,
          "anoFabricacao": int.parse(_anoFabController.text),
          "anoModelo": int.parse(_anoModController.text),
          "cor": _corController.text,
          "renavam": _renevamController.text,
          "chassi": _chassiController.text,
          "empresa": _empresaController.text,
          "departamento": _departamentoController.text,
          "tipoVeiculo": _selectedTipo,
          "supervisorId": _selectedSupervisorId,
        };

        await _vehicleService.updateVehicle(widget.vehicleId, updatedData);
        await _loadVehicleDetails(); // Recarrega os dados atualizados

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veículo atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } on FormatException {
        setState(() {
          _errorMessage = 'Erro: Verifique os campos numéricos';
          _isLoading = false;
        });
      } catch (e) {
        String errorMessage = e.toString();
        if (errorMessage.contains('500') || errorMessage.contains('já existe')) {
          errorMessage = 'Esta placa já está cadastrada no sistema';
        }

        setState(() {
          _errorMessage = 'Erro: $errorMessage';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este veículo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await _vehicleService.deleteVehicle(widget.vehicleId);

        if (mounted) {
          Navigator.pop(context, true); // Retorna true para indicar que houve alteração
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Erro ao excluir: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isNotEmpty ? value : '--',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int? maxLength,
    String? hintText,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            validator: validator,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
    String? Function(String?)? validator,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorDropdownField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supervisor',
            style: const TextStyle(
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
      ),
    );
  }

  // Função para encontrar o nome do supervisor pelo ID
  String _getSupervisorName(int? supervisorId) {
    if (supervisorId == null) return 'N/A';
    
    final supervisor = _supervisores.firstWhere(
      (sup) => sup['id'] == supervisorId,
      orElse: () => <String, dynamic>{},
    );
    
    if (supervisor.isNotEmpty) {
      return '${supervisor['nome']} (${supervisor['email']})';
    }
    
    // Fallback para quando o supervisor não está na lista ou ainda está carregando
    return _veiculo?['supervisor']?['nome'] ?? 'N/A';
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
              Navigator.pop(context, true); // Retorna true para indicar que pode ter havido alterações
            },
          ),
        ),
        title: Text(
          _isEditing ? 'Editar Veículo' : 'Detalhes do Veículo',
          style: const TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_veiculo != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black54),
              onPressed: _loadVehicleDetails,
            ),
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0C7E3D),
              ),
            )
          : SingleChildScrollView(
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

                      if (_isEditing) ...[
                        // Campos editáveis
                        _buildEditableField(
                          'Placa do Veículo',
                          _placaController,
                          hintText: 'ABC1234',
                          validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
                        ),
                        
                        _buildEditableField(
                          'Marca',
                          _marcaController,
                          hintText: 'Ford',
                          validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
                        ),
                        
                        _buildEditableField(
                          'Modelo',
                          _modeloController,
                          hintText: 'Fiesta',
                          validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
                        ),
                        
                        _buildEditableField(
                          'Ano de Fabricação',
                          _anoFabController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          hintText: '2023',
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Campo obrigatório';
                            final ano = int.tryParse(value!);
                            if (ano == null) return 'Digite um ano válido';
                            if (ano <= 1900) return 'Ano deve ser > 1900';
                            if (ano > 2026) return 'Ano deve ser ≤ 2026';
                            return null;
                          },
                        ),
                        
                        _buildEditableField(
                          'Ano do Modelo',
                          _anoModController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          hintText: '2023',
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Campo obrigatório';
                            final ano = int.tryParse(value!);
                            if (ano == null) return 'Digite um ano válido';
                            if (ano <= 1900) return 'Ano deve ser > 1900';
                            if (ano > 2026) return 'Ano deve ser ≤ 2026';
                            return null;
                          },
                        ),
                        
                        _buildEditableField(
                          'Cor',
                          _corController,
                          hintText: 'Prata',
                          validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
                        ),
                        
                        _buildEditableField(
                          'RENAVAM',
                          _renevamController,
                          keyboardType: TextInputType.number,
                          maxLength: 11,
                          hintText: '11 dígitos',
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Campo obrigatório';
                            if (value!.length != 11) return 'Deve ter 11 dígitos';
                            return null;
                          },
                        ),
                        
                        _buildEditableField(
                          'Chassi',
                          _chassiController,
                          maxLength: 17,
                          hintText: '17 caracteres alfanuméricos',
                          inputFormatters: [LengthLimitingTextInputFormatter(17)],
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Campo obrigatório';
                            if (value!.length != 17) return 'Deve ter 17 caracteres';
                            if (!RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(value)) {
                              return 'Formato inválido';
                            }
                            return null;
                          },
                        ),
                        
                        _buildEditableField(
                          'Empresa',
                          _empresaController,
                          hintText: 'Empresa X',
                          validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
                        ),
                        
                        _buildEditableField(
                          'Departamento',
                          _departamentoController,
                          hintText: 'Logística',
                          validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
                        ),
                        
                        _buildDropdownField(
                          'Tipo de Veículo',
                          _selectedTipo,
                          ['carro', 'moto', 'caminhão', 'ônibus', 'van'],
                          (value) => setState(() => _selectedTipo = value),
                          (value) => value == null ? 'Selecione um tipo' : null,
                        ),
                        
                        _buildSupervisorDropdownField(),
                      ] else ...[
                        // Campos apenas para visualização
                        _buildInfoField('Placa', _placaController.text),
                        _buildInfoField('Marca', _marcaController.text),
                        _buildInfoField('Modelo', _modeloController.text),
                        _buildInfoField('Ano de Fabricação', _anoFabController.text),
                        _buildInfoField('Ano do Modelo', _anoModController.text),
                        _buildInfoField('Cor', _corController.text),
                        _buildInfoField('RENAVAM', _renevamController.text),
                        _buildInfoField('Chassi', _chassiController.text),
                        _buildInfoField('Empresa', _empresaController.text),
                        _buildInfoField('Departamento', _departamentoController.text),
                        _buildInfoField('Tipo de Veículo', _selectedTipo ?? ''),
                        _buildInfoField('Supervisor', _getSupervisorName(_selectedSupervisorId)),
                      ],

                      const SizedBox(height: 30),

                      // Botões de ação
                      if (_isEditing) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                    _loadVehicleDetails();
                                  });
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
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveChanges,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4EB699),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Salvar',
                                  style: TextStyle(fontSize: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _handleDelete,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF67E7E),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Excluir',
                                  style: TextStyle(fontSize: 16, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => setState(() => _isEditing = true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4EB699),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Editar',
                                  style: TextStyle(fontSize: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}