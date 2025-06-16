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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });

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

      // --- LÓGICA ATUALIZADA ---
      // Passo 1: Tenta criar o orçamento.
      final bool budgetCreated = await _budgetCreateService.createBudget(budgetData);

      if (budgetCreated) {
        // Passo 2: Se o orçamento foi criado, tenta atualizar o status da manutenção.
        // O ! é seguro aqui, pois o formulário já foi validado.
        final bool statusUpdated = await _budgetCreateService.updateMaintenanceStatus(_selectedMaintenanceId!);
        
        if (mounted) { // Verifica se o widget ainda está na tela
          if (statusUpdated) {
            // Sucesso total
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Orçamento criado e status da manutenção atualizado!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Sucesso parcial
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Orçamento criado, mas falha ao atualizar o status da manutenção.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          Navigator.of(context).pop();
        }

      } else {
        // Falha na criação do orçamento
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Falha ao criar orçamento. Verifique os dados e a conexão.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      // Garante que o indicador de progresso seja desativado
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... O resto do seu widget build permanece exatamente o mesmo ...
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Novo Orçamento'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildMaintenanceDropdown(),
              const SizedBox(height: 20),
              _buildGarageDropdown(),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Descrição do Serviço',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a descrição do serviço.';
                  }
                  return null;
                },
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(
                  labelText: 'Valor da Mão de Obra (R\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: 'Ex: 80,50'
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
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar Orçamento'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // --- O resto dos seus widgets (_buildMaintenanceDropdown, _buildGarageDropdown) não precisam de alterações ---
  Widget _buildMaintenanceDropdown() {
    return FutureBuilder<List<dynamic>>(
      future: _maintenancesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Erro ao carregar manutenções: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('Nenhuma manutenção disponível para orçamento.');
        }

        final maintenances = snapshot.data!;
        return DropdownButtonFormField<int>(
          decoration: const InputDecoration(
            labelText: 'Manutenção (Veículo - Placa)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.build),
          ),
          value: _selectedMaintenanceId,
          hint: const Text('Selecione uma manutenção'),
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
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Erro ao carregar oficinas: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('Nenhuma oficina encontrada.');
        }

        final garages = snapshot.data!;
        return DropdownButtonFormField<int>(
          decoration: const InputDecoration(
            labelText: 'Oficina',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.store),
          ),
          value: _selectedGarageId,
          hint: const Text('Selecione uma oficina'),
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