import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:front_projeto_flutter/screens/supervisor/maintenences/solicitar_manutencao.dart';
// Placeholder screen for vehicle details or maintenance request
class VehicleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> vehicle;

  const VehicleDetailScreen({Key? key, required this.vehicle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar veiculo'),
        backgroundColor: const Color(0xFF0C7E3D),
        
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Placa: ${vehicle['placa']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Marca: ${vehicle['marca']}', style: const TextStyle(fontSize: 16)),
            Text('Modelo: ${vehicle['modelo']}', style: const TextStyle(fontSize: 16)),
            Text('Ano: ${vehicle['anoFabricacao']}/${vehicle['anoModelo']}', style: const TextStyle(fontSize: 16)),
            Text('Cor: ${vehicle['cor']}', style: const TextStyle(fontSize: 16)),
            Text('Empresa: ${vehicle['empresa']}', style: const TextStyle(fontSize: 16)),
            Text('Departamento: ${vehicle['departamento']}', style: const TextStyle(fontSize: 16)),
            // Add more vehicle details as needed
          ],
        ),
      ),
    );
  }
}

class VeiculosDisponiveisScreen extends StatefulWidget {
  const VeiculosDisponiveisScreen({Key? key}) : super(key: key);

  @override
  _VeiculosDisponiveisScreenState createState() => _VeiculosDisponiveisScreenState();
}

class _VeiculosDisponiveisScreenState extends State<VeiculosDisponiveisScreen> {
  final _secureStorage = const FlutterSecureStorage();
  bool _isLoading = true;
  List<dynamic> _veiculos = [];
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredVeiculos = []; // To store filtered vehicles

  @override
  void initState() {
    super.initState();
    _fetchVeiculos();
    _searchController.addListener(_filterVeiculos);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterVeiculos);
    _searchController.dispose();
    super.dispose();
  }

  // Function to filter vehicles based on search query
  void _filterVeiculos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredVeiculos = _veiculos.where((veiculo) {
        final placa = veiculo['placa']?.toLowerCase() ?? '';
        final marca = veiculo['marca']?.toLowerCase() ?? '';
        final modelo = veiculo['modelo']?.toLowerCase() ?? '';
        final empresa = veiculo['empresa']?.toLowerCase() ?? '';
        final departamento = veiculo['departamento']?.toLowerCase() ?? '';

        return placa.contains(query) ||
            marca.contains(query) ||
            modelo.contains(query) ||
            empresa.contains(query) ||
            departamento.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchVeiculos() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final token = await _secureStorage.read(key: 'auth_token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sessão expirada. Por favor, faça login novamente.';
        });
        return;
      }

      final url = Uri.parse('http://localhost:4040/api/veiculos/available?_limit=100');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _veiculos = data['veiculosDisponiveis'];
          _filteredVeiculos = _veiculos; // Initialize filtered list with all vehicles
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sessão expirada. Por favor, faça login novamente.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao carregar dados: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro de conexão: ${e.toString()}';
      });
    }
  }

  // Helper function to get button text and color based on vehicle 'status' (simulated from image)
  // In a real scenario, the API response for 'available' vehicles might not have a 'status' field,
  // or it might only have 'available'. For the image, we simulate different states.
  Widget _buildActionButton(Map<String, dynamic> vehicle) {
    // This is a simulation based on the image's various buttons.
    // In a real 'available' endpoint, you'd likely just have 'Encaminhar veículo'.
    // I'm using a simple heuristic to mimic the image.
    final placa = vehicle['placa'] ?? '';
    Color buttonColor = const Color(0xFF0C7E3D); // Default to green for 'Encaminhar'
    String buttonText = 'Solicitar manutencão';
    VoidCallback? onPressed;

    
      onPressed = () async { // Make it async to await the result from the next screen
        // Navigate to the MaintenanceRequestScreen, passing the vehicle data
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MaintenanceRequestScreen(vehicle: vehicle),
          ),
        );

        // If the MaintenanceRequestScreen pops with 'true', refresh the list
        if (result == true) {
          _fetchVeiculos(); // Re-fetch vehicles to update statuses if needed
        }
      };

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      onPressed: onPressed,
      child: Text(
        buttonText,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar veiculo'),
        backgroundColor: const Color(0xFF0C7E3D),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchVeiculos,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Buscar veículo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sort, color: Colors.grey), // Assuming this is a sort/filter icon
                      onPressed: () {
                        // Handle sort/filter
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Digite a placa do veículo',
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _isLoading
              ? const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0C7E3D),
                    ),
                  ),
                )
              : _errorMessage != null
                  ? Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red[300],
                              size: 60,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0C7E3D),
                              ),
                              onPressed: _fetchVeiculos,
                              child: const Text('Tentar novamente', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _filteredVeiculos.isEmpty
                      ? Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.directions_car_filled,
                                  color: Colors.grey[400],
                                  size: 60,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'Nenhum veículo disponível encontrado.'
                                      : 'Nenhum veículo encontrado para "${_searchController.text}".',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Expanded(
                          child: RefreshIndicator(
                            onRefresh: _fetchVeiculos,
                            color: const Color(0xFF0C7E3D),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredVeiculos.length,
                              itemBuilder: (context, index) {
                                final veiculo = _filteredVeiculos[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          veiculo['placa'] ?? 'N/A',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          veiculo['cor'] ?? 'N/A',
                                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${veiculo['empresa'] ?? 'N/A'}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        Text(
                                          '${veiculo['departamento'] ?? 'N/A'}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${veiculo['marca'] ?? 'N/A'} ${veiculo['modelo'] ?? 'N/A'} ${veiculo['anoFabricacao'] ?? ''}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            _buildActionButton(veiculo),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
        ],
      ),
    );
  }
}