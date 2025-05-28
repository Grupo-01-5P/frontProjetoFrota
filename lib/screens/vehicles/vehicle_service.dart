import 'dart:convert';
import 'package:http/http.dart' as http;

class VehicleService {
  // Configuração temporária - substitua com suas informações
  static const String baseUrl = 'http://localhost:4040';
  static const String temporaryJwt =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MywiZW1haWwiOiJ1c2VyQGV4YW1wbGUuY29tIiwiZnVuY2FvIjoic3VwZXJ2aXNvciIsImlhdCI6MTc0ODM4NzYwOSwiZXhwIjoxNzQ4NDMwODA5fQ.QvMlblzB72HLrIh2C5QElNrzSjsY90O-FIUnIE3PyjQ'; // Seu JWT completo aqui

  Future<Map<String, String>> _getHeaders() async {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $temporaryJwt', // JWT fixo temporário
    };
  }

  Future<List<dynamic>> getVehicles() async {
    try {
      final headers = await _getHeaders();
      print('Enviando requisição para: $baseUrl/veiculos'); // Debug
      print('Com headers: $headers'); // Debug

      final response = await http.get(
        Uri.parse('$baseUrl/veiculos'),
        headers: headers,
      );

      print('Resposta recebida: ${response.statusCode}'); // Debug
      print('Corpo da resposta: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['data'];
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erro na requisição: $e'); // Debug
      throw Exception('Erro na conexão: $e');
    }
  }

  /*class VehicleService {
  static const String baseUrl = 'http://localhost:4040';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Método para obter o token JWT do armazenamento seguro
  Future<String?> _getToken() async {
    // Implementação real - busca o token salvo durante o login
    return await _storage.read(key: 'jwt_token');
    
    // Para debug durante desenvolvimento:
    // return 'eyJhbGciOiJIUzI1NiIs...'; // JWT temporário
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token JWT não encontrado - usuário não autenticado');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> getVehicles() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/veiculos'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['data'];
      } else if (response.statusCode == 401) {
        throw Exception('Acesso não autorizado - token inválido/expirado');
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro na conexão: $e');
    }
  }*/

  Future<Map<String, dynamic>> getVehicleDetails(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/veiculos/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $temporaryJwt',
      },
    );

    print('Resposta bruta: ${response.body}'); // Debug

    if (response.statusCode == 200) {
      return json.decode(
        response.body,
      ); // Diretamente o objeto, sem extrair 'data'
    } else {
      throw Exception('Erro ${response.statusCode}: ${response.body}');
    }
  }

  Future<List<dynamic>> searchVehicleByPlate(String plate) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/veiculos/busca?placa=$plate'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Falha na busca: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na busca: $e');
    }
  }
}
