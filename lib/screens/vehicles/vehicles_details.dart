import 'package:flutter/material.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicle_service.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicles_listage.dart';
import 'package:flutter/services.dart';

class VehiclesDetails extends StatefulWidget {
  final int vehicleId;

  const VehiclesDetails({super.key, required this.vehicleId});

  @override
  State<VehiclesDetails> createState() => _VehiclesDetailsState();
}

class _VehiclesDetailsState extends State<VehiclesDetails> {
  final VehicleService _vehicleService = VehicleService();
  Map<String, dynamic>? _veiculo;
  bool _isLoading = true;
  bool _isEditing = false;
  String _errorMessage = '';
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

  @override
  void initState() {
    super.initState();
    _loadVehicleDetails();
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

  Future<void> _loadVehicleDetails() async {
    setState(() {
      _isLoading = true;
      _isEditing = false;
      _errorMessage = '';
    });

    try {
      final response = await _vehicleService.getVehicleDetails(
        widget.vehicleId,
      );

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
        _selectedSupervisorId =
            _veiculo!['supervisorId'] ?? _veiculo!['supervisor']['id'] ?? 1;
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
      try {
        setState(() => _isLoading = true);

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
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: Verifique os campos numéricos'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        String errorMessage = e.toString();

        // Tratamento especial para erro de placa existente
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

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
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
      try {
        setState(() => _isLoading = true);
        await _vehicleService.deleteVehicle(widget.vehicleId);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const VehiclesListage()),
            (route) => false,
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child:
                _isEditing
                    ? TextFormField(
                      controller: controller,
                      keyboardType: keyboardType,
                      maxLength: maxLength,
                      inputFormatters: inputFormatters,
                      validator: validator,
                      decoration: InputDecoration(
                        hintText: hintText,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        counterText: '',
                      ),
                    )
                    : Text(controller.text.isNotEmpty ? controller.text : '--'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnoField(String label, TextEditingController controller) {
    return _buildEditableField(
      label,
      controller,
      keyboardType: TextInputType.number,
      maxLength: 4,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) return 'Campo obrigatório';
        final ano = int.tryParse(value);
        if (ano == null) return 'Digite um ano válido';
        if (ano <= 1900) return 'Ano deve ser > 1900';
        if (ano > 2026) return 'Ano deve ser ≤ 2026';
        return null;
      },
    );
  }

  Widget _buildRenevamField() {
    return _buildEditableField(
      'RENAVAM',
      _renevamController,
      keyboardType: TextInputType.number,
      maxLength: 11,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) return 'Campo obrigatório';
        if (value.length != 11) return 'Deve ter 11 dígitos';
        return null;
      },
    );
  }

  Widget _buildChassiField() {
    return _buildEditableField(
      'Chassi',
      _chassiController,
      maxLength: 17,
      inputFormatters: [LengthLimitingTextInputFormatter(17)],
      validator: (value) {
        if (value == null || value.isEmpty) return 'Campo obrigatório';
        if (value.length != 17) return 'Deve ter 17 caracteres';
        if (!RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(value)) {
          return 'Formato inválido';
        }
        return null;
      },
    );
  }

  Widget _buildTipoVeiculoDropdown() {
    final tipos = ['carro', 'moto', 'caminhão', 'ônibus', 'van'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 150,
            child: Text(
              'Tipo de Veículo',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child:
                _isEditing
                    ? DropdownButtonFormField<String>(
                      value: _selectedTipo,
                      items:
                          tipos.map((tipo) {
                            return DropdownMenuItem<String>(
                              value: tipo,
                              child: Text(tipo),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedTipo = newValue;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        filled: true,
                        fillColor: Color.fromARGB(255, 229, 229, 229),
                      ),
                      validator:
                          (value) => value == null ? 'Selecione um tipo' : null,
                    )
                    : Text(_selectedTipo ?? '--'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorDropdown() {
    final supervisorIds = [1, 2, 3]; // Substitua pelos IDs reais

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 150,
            child: Text(
              'Supervisor',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child:
                _isEditing
                    ? DropdownButtonFormField<int>(
                      value: _selectedSupervisorId,
                      items:
                          supervisorIds.map((id) {
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text('Supervisor $id'),
                            );
                          }).toList(),
                      onChanged: (int? newId) {
                        setState(() {
                          _selectedSupervisorId = newId;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        filled: true,
                        fillColor: Color.fromARGB(255, 229, 229, 229),
                      ),
                      validator:
                          (value) =>
                              value == null ? 'Selecione um supervisor' : null,
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_veiculo?['supervisor']['nome'] ?? '--'),
                        Text(_veiculo?['supervisor']['email'] ?? ''),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    return Form(
      key: _formKey,
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informações do Veículo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              _buildEditableField(
                'Placa',
                _placaController,
                hintText: 'ABC1234',
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Campo obrigatório';
                  return null;
                },
              ),
              _buildEditableField(
                'Marca',
                _marcaController,
                hintText: 'Ford',
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Campo obrigatório';
                  return null;
                },
              ),
              _buildEditableField(
                'Modelo',
                _modeloController,
                hintText: 'Fiesta',
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Campo obrigatório';
                  return null;
                },
              ),
              _buildAnoField('Ano Fabricação', _anoFabController),
              _buildAnoField('Ano Modelo', _anoModController),
              _buildEditableField(
                'Cor',
                _corController,
                hintText: 'Prata',
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Campo obrigatório';
                  return null;
                },
              ),
              _buildRenevamField(),
              _buildChassiField(),
              _buildEditableField(
                'Empresa',
                _empresaController,
                hintText: 'Empresa X',
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Campo obrigatório';
                  return null;
                },
              ),
              _buildEditableField(
                'Departamento',
                _departamentoController,
                hintText: 'Logística',
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Campo obrigatório';
                  return null;
                },
              ),
              _buildTipoVeiculoDropdown(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return _isEditing
        ? Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Salvar'),
                onPressed: _saveChanges,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.cancel),
                label: const Text('Cancelar'),
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _loadVehicleDetails();
                  });
                },
                style: ElevatedButton.styleFrom(foregroundColor: Colors.grey),
              ),
            ),
          ],
        )
        : Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Editar'),
                onPressed: () => setState(() => _isEditing = true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: _handleDelete,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.red,
                  backgroundColor: Colors.red.withOpacity(0.1),
                ),
              ),
            ),
          ],
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Veículo'),
        actions: [
          if (_veiculo != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadVehicleDetails,
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loadVehicleDetails,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildVehicleCard(),
                    const SizedBox(height: 16),
                    _buildSupervisorDropdown(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                  ],
                ),
              ),
    );
  }
}
