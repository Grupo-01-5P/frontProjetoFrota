import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart'; // Import geolocator

class MaintenanceRequestScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const MaintenanceRequestScreen({Key? key, required this.vehicle})
    : super(key: key);

  @override
  _MaintenanceRequestScreenState createState() =>
      _MaintenanceRequestScreenState();
}

class _MaintenanceRequestScreenState extends State<MaintenanceRequestScreen> {
  final _secureStorage = const FlutterSecureStorage();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedUrgency; // For the urgency dropdown
  bool _isLoading = false;
  String? _currentLatitude;
  String? _currentLongitude;

  final List<String> _urgencyOptions = ['baixa', 'média', 'alta'];

  @override
  void initState() {
    super.initState();
    _determinePosition(); // Get location on screen load
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      _showSnackBar(
        'Serviços de localização desabilitados. Por favor, habilite-os.',
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        _showSnackBar('Permissão de localização negada.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      _showSnackBar(
        'Permissão de localização negada permanentemente. Por favor, vá nas configurações do app para permitir.',
      );
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLatitude = position.latitude.toString();
        _currentLongitude = position.longitude.toString();
      });
      _showSnackBar('Localização obtida com sucesso.');
    } catch (e) {
      _showSnackBar('Erro ao obter localização: ${e.toString()}');
    }
  }

  void _showSnackBar(String message, {Color color = Colors.black}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _sendMaintenanceRequest() async {
    if (_descriptionController.text.isEmpty) {
      _showSnackBar('Por favor, descreva o problema.', color: Colors.red);
      return;
    }
    if (_selectedUrgency == null) {
      _showSnackBar('Por favor, selecione a urgência.', color: Colors.red);
      return;
    }
    if (_currentLatitude == null || _currentLongitude == null) {
      _showSnackBar(
        'Não foi possível obter sua localização. Tente novamente.',
        color: Colors.red,
      );
      await _determinePosition(); // Try to get location again
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _secureStorage.read(key: 'auth_token');

      if (token == null) {
        _showSnackBar(
          'Sessão expirada. Por favor, faça login novamente.',
          color: Colors.red,
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final veiculoId = widget.vehicle['id'];
      final supervisorId =
          widget
              .vehicle['supervisorId']; // Assuming supervisorId is in vehicle object

      final response = await http.post(
        Uri.parse('http://localhost:4040/api/maintenance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "veiculoId": veiculoId,
          "descricaoProblema": _descriptionController.text,
          "latitude": _currentLatitude,
          "longitude": _currentLongitude,
          "urgencia": _selectedUrgency,
          "supervisorId": supervisorId, // Can be null if not available
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnackBar(
          'Solicitação de manutenção enviada com sucesso!',
          color: Colors.green,
        );
        Navigator.pop(
          context,
          true,
        ); // Pop with true to indicate success/refresh needed
      } else if (response.statusCode == 401) {
        _showSnackBar(
          'Sessão expirada. Por favor, faça login novamente.',
          color: Colors.red,
        );
      } else {
        final errorBody = jsonDecode(response.body);
        _showSnackBar(
          'Erro ao enviar solicitação: ${errorBody['message'] ?? response.statusCode}',
          color: Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('Erro de conexão: ${e.toString()}', color: Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova solicitação de manutenção'),
        backgroundColor: const Color(0xFF0C7E3D),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Icon(
                Icons.delivery_dining,
                size: 60,
                color: Colors.red[700],
              ), // Truck icon
            ),
            Text(
              widget.vehicle['placa'] ?? 'Placa não informada',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'Marca: ${widget.vehicle['marca'] ?? 'N/A'} ${widget.vehicle['modelo'] ?? 'N/A'} ${widget.vehicle['anoFabricacao'] ?? ''}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Chassi: ${widget.vehicle['chassi'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 16),
            ),
            Row(
              children: [
                Text(
                  'Supervisor: ${widget.vehicle['supervisor']?['nome'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 16),
                ),
                if (widget.vehicle['supervisor']?['nome'] != null)
                  const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Problema: Identifique abaixo o motivo da manutenção',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 10,
                minLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Descrição',
                  border: InputBorder.none,
                ),
                keyboardType: TextInputType.multiline,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Urgência da Manutenção:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedUrgency,
              hint: const Text('Selecione a urgência'),
              decoration: InputDecoration(
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
              items:
                  _urgencyOptions.map((String urgency) {
                    return DropdownMenuItem<String>(
                      value: urgency,
                      child: Text(urgency),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedUrgency = newValue;
                });
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Go back to previous screen
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
                    onPressed: _isLoading ? null : _sendMaintenanceRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C7E3D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Enviar',
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
    );
  }
}
