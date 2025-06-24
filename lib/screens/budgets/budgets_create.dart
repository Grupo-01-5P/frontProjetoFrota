import 'package:flutter/material.dart';
import 'package:front_projeto_flutter/screens/budgets/services/createService.dart';

class BudgetCreate extends StatefulWidget {
  @override
  _BudgetCreateState createState() => _BudgetCreateState();
}

class _BudgetCreateState extends State<BudgetCreate> {
  final _formKey = GlobalKey<FormState>();
  final _budgetCreateService = BudgetCreateService();

  // Controladores para os campos do formulário
  final _descController = TextEditingController();
  final _valorController = TextEditingController();

  // Variáveis para armazenar os valores selecionados nos dropdowns
  int? _selectedMaintenanceId;
  int? _selectedGarageId;

  // Futures para carregar os dados dos dropdowns
  late Future<List<dynamic>> _maintenancesFuture;
  late Future<List<dynamic>> _garagesFuture;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  void _loadDropdownData() {
    setState(() {
      _maintenancesFuture = _budgetCreateService.fetchMaintenances();
      _garagesFuture = _budgetCreateService.fetchGarages();
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color color = Colors.black}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      final rawValue = _valorController.text.replaceAll(',', '.');
      final valorMaoObra = double.tryParse(rawValue) ?? 0.0;

      final budgetData = {
        'descricaoServico': _descController.text,
        'valorMaoObra': valorMaoObra,
        'manutencaoId': _selectedMaintenanceId,
        'oficinaId': _selectedGarageId,
        'status': 'pendente',
        'dataEnvio': DateTime.now().toIso8601String(),
      };

      try {
        // Passo 1: Tenta criar o orçamento.
        final bool budgetCreated = await _budgetCreateService.createBudget(budgetData);

        if (budgetCreated) {
          // Passo 2: Se o orçamento foi criado, tenta atualizar o status da manutenção.
          final bool statusUpdated = await _budgetCreateService.updateMaintenanceStatus(_selectedMaintenanceId!);
          
          if (mounted) {
            if (statusUpdated) {
              _showSnackBar(
                'Orçamento criado e status da manutenção atualizado!',
                color: Colors.green,
              );
            } else {
              _showSnackBar(
                'Orçamento criado, mas falha ao atualizar o status da manutenção.',
                color: Colors.orange,
              );
            }
            Navigator.of(context).pop();
          }
        } else {
          if (mounted) {
            _showSnackBar(
              'Falha ao criar orçamento. Verifique os dados e a conexão.',
              color: Colors.red,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar(
            'Erro de conexão: ${e.toString()}',
            color: Colors.red,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Novo Orçamento'),
        backgroundColor: const Color(0xFF0C7E3D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Ícone no canto superior direito
              Align(
                alignment: Alignment.topRight,
                child: Icon(
                  Icons.receipt_long,
                  size: 60,
                  color: Colors.green[700],
                ),
              ),
              
              const Text(
                'Novo Orçamento',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 8),
              
              const Text(
                'Preencha os dados abaixo para criar um novo orçamento',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Dropdown de Manutenção
              const Text(
                'Manutenção:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildMaintenanceDropdown(),
              const SizedBox(height: 16),

              // Dropdown de Oficina
              const Text(
                'Oficina:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildGarageDropdown(),
              const SizedBox(height: 16),

              // Campo de Descrição
              const Text(
                'Descrição do Serviço:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextFormField(
                  controller: _descController,
                  maxLines: 5,
                  minLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Descreva o serviço a ser realizado...',
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.multiline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira a descrição do serviço.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Campo de Valor
              const Text(
                'Valor da Mão de Obra:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _valorController,
                decoration: InputDecoration(
                  hintText: 'Ex: 80,50',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.blueAccent,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o valor.';
                  }
                  final number = double.tryParse(value.replaceAll(',', '.'));
                  if (number == null) {
                    return 'Por favor, insira um número válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Botões de ação
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C7E3D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Salvar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceDropdown() {
    return FutureBuilder<List<dynamic>>(
      future: _maintenancesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Erro ao carregar manutenções: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Nenhuma manutenção disponível para orçamento.'),
          );
        }

        final maintenances = snapshot.data!;
        return DropdownButtonFormField<int>(
          decoration: InputDecoration(
            hintText: 'Selecione uma manutenção',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.blueAccent,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          value: _selectedMaintenanceId,
          isExpanded: true,
          items: maintenances.map((maintenance) {
            final vehicleInfo = maintenance['veiculo']?['placa'] ?? 'Placa não informada';
            return DropdownMenuItem<int>(
              value: maintenance['id'],
              child: Text(
                'ID: ${maintenance['id']} - $vehicleInfo',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedMaintenanceId = value;
            });
          },
          validator: (value) => value == null ? 'Campo obrigatório' : null,
        );
      },
    );
  }

  Widget _buildGarageDropdown() {
    return FutureBuilder<List<dynamic>>(
      future: _garagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Erro ao carregar oficinas: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Nenhuma oficina encontrada.'),
          );
        }

        final garages = snapshot.data!;
        return DropdownButtonFormField<int>(
          decoration: InputDecoration(
            hintText: 'Selecione uma oficina',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.blueAccent,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          value: _selectedGarageId,
          isExpanded: true,
          items: garages.map((garage) {
            return DropdownMenuItem<int>(
              value: garage['id'],
              child: Text(
                garage['nome'] ?? 'Nome não informado',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGarageId = value;
            });
          },
          validator: (value) => value == null ? 'Campo obrigatório' : null,
        );
      },
    );
  }
}