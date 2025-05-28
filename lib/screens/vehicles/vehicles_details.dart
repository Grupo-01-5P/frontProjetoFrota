import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_page.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_listage.dart';
import 'package:front_projeto_flutter/screens/budgets/budgets_reproval.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicles_page.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicle_service.dart';
import 'package:front_projeto_flutter/screens/vehicles/vehicles_details.dart';

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
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadVehicleDetails();
  }

  Future<void> _loadVehicleDetails() async {
    try {
      print('🔍 Buscando detalhes do veículo ID: ${widget.vehicleId}');
      final response = await _vehicleService.getVehicleDetails(
        widget.vehicleId,
      );

      setState(() {
        _veiculo = response;
        _isLoading = false;
      });
      print('✅ Dados carregados: $_veiculo');
    } catch (e) {
      setState(() {
        _errorMessage = _parseError(e);
        _isLoading = false;
      });
      print('❌ Erro: $_errorMessage');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _parseError(dynamic error) {
    if (error.toString().contains('404')) {
      return 'Veículo não encontrado';
    } else if (error.toString().contains('401')) {
      return 'Acesso não autorizado (token inválido/expirado)';
    } else {
      return 'Erro ao carregar detalhes: ${error.toString()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Veículo'),
        actions: [
          if (_veiculo != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadVehicleDetails,
            ),
        ],
      ),
      body: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadVehicleDetails,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildVehicleCard(),
          const SizedBox(height: 16),
          _buildSupervisorCard(),
          const SizedBox(height: 16),
          _buildMaintenanceSection(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    return Card(
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
            _buildDetailRow('Placa', _veiculo!['placa']),
            _buildDetailRow('Marca', _veiculo!['marca']),
            _buildDetailRow('Modelo', _veiculo!['modelo']),
            _buildDetailRow(
              'Ano Fabricação',
              _veiculo!['anoFabricacao'].toString(),
            ),
            _buildDetailRow('Ano Modelo', _veiculo!['anoModelo'].toString()),
            _buildDetailRow('Cor', _veiculo!['cor']),
            _buildDetailRow('RENAVAM', _veiculo!['renavam']),
            _buildDetailRow('Chassi', _veiculo!['chassi']),
            _buildDetailRow('Empresa', _veiculo!['empresa']),
            _buildDetailRow('Departamento', _veiculo!['departamento']),
            _buildDetailRow('Tipo', _veiculo!['tipoVeiculo']),
          ],
        ),
      ),
    );
  }

  Widget _buildSupervisorCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Supervisor Responsável',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildDetailRow('Nome', _veiculo!['supervisor']['nome']),
            _buildDetailRow('Email', _veiculo!['supervisor']['email']),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Histórico de Manutenções',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (_veiculo!['manutencoes'].isEmpty)
              const Text(
                'Nenhuma manutenção registrada',
                style: TextStyle(color: Colors.grey),
              ),
            ..._veiculo!['manutencoes']
                .map<Widget>(
                  (manutencao) => ListTile(
                    title: Text(manutencao['tipo']),
                    subtitle: Text(manutencao['data']),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Editar'),
            onPressed: () => _handleEdit(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('Excluir', style: TextStyle(color: Colors.red)),
            onPressed: () => _handleDelete(),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.red,
              backgroundColor: Colors.red.withOpacity(0.1),
            ),
          ),
        ),
      ],
    );
  }

  void _handleEdit() {
    // Implementar edição
    print('Editar veículo ID: ${_veiculo!['id']}');
  }

  void _handleDelete() {
    // Implementar exclusão
    print('Excluir veículo ID: ${_veiculo!['id']}');
  }

  Widget _buildDetailRow(String label, String value) {
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
          Expanded(child: Text(value.isNotEmpty ? value : '--')),
        ],
      ),
    );
  }
}
