import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:front_projeto_flutter/screens/maintenences/ViewMaintenancePhases.dart';

class ManutencaoDetailScreenSupervisor extends StatefulWidget {
  final dynamic manutencao;
  final dynamic oficina;

  const ManutencaoDetailScreenSupervisor({
    Key? key,
    required this.manutencao,
    this.oficina,
  }) : super(key: key);

  @override
  _ManutencaoDetailScreenSupervisorState createState() =>
      _ManutencaoDetailScreenSupervisorState();
}

class _ManutencaoDetailScreenSupervisorState
    extends State<ManutencaoDetailScreenSupervisor> {
  final _secureStorage = const FlutterSecureStorage();
  final _motivoController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  final MapController _mapController = MapController();

  // Variáveis para armazenar dados de localização
  String _enderecoCompleto = 'Carregando endereço...';
  bool _isLoadingAddress = true;

  dynamic _oficinasSelecionada;

  @override
  void initState() {
    super.initState();
    if (widget.manutencao['oficina'] != null) {
      _oficinasSelecionada = widget.manutencao['oficina'];
    }
    _obterEndereco();
  }

  // Função para obter o endereço a partir de latitude e longitude
  Future<void> _obterEndereco() async {
    final bool hasCoordinates =
        widget.manutencao['latitude'] != null &&
        widget.manutencao['longitude'] != null;

    if (!hasCoordinates) {
      setState(() {
        _enderecoCompleto = 'Localização não disponível';
        _isLoadingAddress = false;
      });
      return;
    }

    // Converter coordenadas para double
    final latitude = double.tryParse(widget.manutencao['latitude']) ?? 0.0;
    final longitude = double.tryParse(widget.manutencao['longitude']) ?? 0.0;

    if (latitude == 0.0 && longitude == 0.0) {
      setState(() {
        _enderecoCompleto = 'Coordenadas inválidas';
        _isLoadingAddress = false;
      });
      return;
    }

    try {
      // Usar o pacote geocoding para fazer a geocodificação reversa
      print('Coordenadas: $latitude, $longitude');
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String endereco = '';

        // Compor o endereço com as informações disponíveis
        if (place.street != null && place.street!.isNotEmpty) {
          endereco += place.street!;
        }

        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          if (endereco.isNotEmpty) endereco += ', ';
          endereco += place.subLocality!;
        }

        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          if (endereco.isNotEmpty) endereco += ', ';
          endereco += place.subAdministrativeArea!;
        }

        if (place.locality != null && place.locality!.isNotEmpty) {
          if (endereco.isNotEmpty) endereco += ', ';
          endereco += place.locality!;
        }

        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          if (endereco.isNotEmpty) endereco += ', ';
          endereco += place.administrativeArea!;
        }

        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          if (endereco.isNotEmpty) endereco += ' - ';
          endereco += 'CEP: ' + place.postalCode!;
        }

        setState(() {
          _enderecoCompleto =
              endereco.isNotEmpty ? endereco : 'Endereço não encontrado';
          _isLoadingAddress = false;
        });
      } else {
        setState(() {
          _enderecoCompleto = 'Endereço não encontrado';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      print('Erro ao obter endereço: $e');
      setState(() {
        _enderecoCompleto = 'Não foi possível obter o endereço';
        _isLoadingAddress = false;
      });
    }
  }

  // Função para formatar a data
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _navegarParaFases() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewMaintenancePhases(
          manutencaoId: widget.manutencao['id'],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final veiculo = widget.manutencao['veiculo'];

    // Verificar se existem coordenadas
    final bool hasCoordinates =
        widget.manutencao['latitude'] != null &&
        widget.manutencao['longitude'] != null;

    // Converter coordenadas para double (se existirem)
    final latitude =
        hasCoordinates
            ? double.tryParse(widget.manutencao['latitude'].toString()) ?? 0.0
            : 0.0;
    final longitude =
        hasCoordinates
            ? double.tryParse(widget.manutencao['longitude'].toString()) ?? 0.0
            : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(veiculo['placa'] ?? 'Detalhe da Manutenção'),
        backgroundColor: const Color(0xFF0C7E3D),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Recarregar dados do endereço
              setState(() {
                _isLoadingAddress = true;
                _enderecoCompleto = 'Carregando endereço...';
              });
              _obterEndereco();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.manutencao['status']?.toLowerCase() != 'reprovado' && 
                    widget.manutencao['status']?.toLowerCase() != 'pendente')
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.timeline, color: Colors.white),
                      label: const Text(
                        'Ver Fases da Manutenção',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF148553),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _navegarParaFases,
                    ),
                  ),
                // Mensagens de erro ou sucesso
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[900]),
                    ),
                  ),

                if (_successMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _successMessage!,
                      style: TextStyle(color: Colors.green[900]),
                    ),
                  ),

                // Informações do veículo
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            veiculo['placa'] ?? 'Placa não informada',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Marca: ${veiculo['marca']} ${veiculo['modelo']} ${veiculo['anoModelo']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chassi: ${veiculo['chassi']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'Supervisor: ',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            widget.manutencao['supervisor']['nome'],
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.message,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Status da manutenção
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.manutencao['status']),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Status: ${_getStatusText(widget.manutencao['status'] ?? "Desconhecido")}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Descrição do problema
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Problema:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.manutencao['descricaoProblema'] ??
                            'Sem descrição do problema',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

                // Mapa com OpenStreetMap
                Container(
                  height: 250,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        hasCoordinates
                            ? FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                center: LatLng(latitude, longitude),
                                zoom: 15,
                                interactiveFlags: InteractiveFlag.all,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                                  userAgentPackageName: 'com.example.app',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(latitude, longitude),
                                      width: 80,
                                      height: 80,
                                      builder:
                                          (context) => const Icon(
                                            Icons.location_on,
                                            color: Colors.red,
                                            size: 40,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                            : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.location_off,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Localização não disponível',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                  ),
                ),

                // Endereço em vez das coordenadas
                if (hasCoordinates)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Localização:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    _isLoadingAddress
                                        ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.blue,
                                          ),
                                        )
                                        : const SizedBox(),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _enderecoCompleto,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Data e Horário
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.calendar_today, size: 18),
                                SizedBox(width: 4),
                                Text('Data:'),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _formatDate(
                                  widget.manutencao['dataSolicitacao'],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.access_time, size: 18),
                                SizedBox(width: 4),
                                Text('Horário:'),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                DateFormat('HH:mm').format(
                                  DateTime.parse(
                                    widget.manutencao['dataSolicitacao'],
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
                SizedBox(height: 20),
                if (_oficinasSelecionada != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Oficina Selecionada:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _oficinasSelecionada['nome'] ??
                                'Nome não disponível',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            '${_oficinasSelecionada['rua'] ?? ''}, ${_oficinasSelecionada['bairro'] ?? ''}',
                          ),
                          Text(
                            '${_oficinasSelecionada['cidade'] ?? ''} - ${_oficinasSelecionada['estado'] ?? ''}',
                          ),
                          Text(
                            'Tel: ${_oficinasSelecionada['telefone'] ?? 'Não informado'}',
                          ),
                          Text(
                            'Email: ${_oficinasSelecionada['email'] ?? 'Não informado'}',
                          ),
                          Text(
                            'Data para levar: ${_formatDate(widget.manutencao['dataEnviarMecanica']) ?? 'Não informado'} - ${DateFormat('HH:mm').format(DateTime.parse(widget.manutencao['dataSolicitacao']))}',
                          ),
                        ],
                      ),
                    ),
                  ),
                // Motivo da reprovação (se aplicável)
                if (widget.manutencao['status']?.toLowerCase() == 'reprovada' &&
                    widget.manutencao['motivoReprovacao'] != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Motivo da reprovação:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(widget.manutencao['motivoReprovacao']),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Indicador de carregamento
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // Função para obter cor baseada no status
  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;

    switch (status.toLowerCase()) {
      case 'pendente':
        return Colors.orange;
      case 'aprovada':
        return Colors.green;
      case 'reprovada':
        return Colors.red;
      case 'concluída':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Função para obter texto do status
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pendente':
        return 'Pendente';
      case 'aprovada':
        return 'Em Andamento';
      case 'reprovada':
        return 'Reprovada';
      case 'concluída':
        return 'Concluída';
      default:
        return status;
    }
  }
}
