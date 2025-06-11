import 'dart:convert';
import 'package:http/http.dart' as http;

class VehicleService {
  // Configuração temporária - substitua com suas informações
  static const String baseUrl = 'http://localhost:4040';
  static const String temporaryJwt =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MywiZW1haWwiOiJ1c2VyQGV4YW1wbGUuY29tIiwiZnVuY2FvIjoic3VwZXJ2aXNvciIsImlhdCI6MTc0OTA1MDk0NiwiZXhwIjoxNzQ5MDk0MTQ2fQ.2DbHcELyfFdV_KuTwnfEDkH-O2rqAejlJG8K4C5-7Fk'; // Seu JWT completo aqui

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

  Future<List<Map<String, dynamic>>> searchVehicleByPlate(String plate) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/veiculos?placa=$plate',
        ), // Adapte para seu endpoint real
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $temporaryJwt',
        },
      );

      print(
        'Resposta da busca: ${response.statusCode} - ${response.body}',
      ); // Debug

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Adapte conforme a estrutura da sua API:
        if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        throw Exception('Formato de resposta inválido');
      } else {
        throw Exception('Erro na busca: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro na busca por placa: $e');
      throw Exception('Falha ao buscar veículos');
    }
  }

  Future<Map<String, dynamic>> createVehicle(
    Map<String, dynamic> vehicleData,
  ) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/veiculos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $temporaryJwt',
      },
      body: json.encode(vehicleData),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Erro ${response.statusCode}: ${response.body}');
    }
  }

  Future<bool> checkPlacaExistente(String placa) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/veiculos/verifica-placa/$placa'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $temporaryJwt',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['existe'] ?? false;
      }
      return false;
    } catch (e) {
      print('Erro ao verificar placa: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> updateVehicle(
    int id,
    Map<String, dynamic> vehicleData,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/veiculos/$id'),
        headers: headers,
        body: json.encode(vehicleData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData == null) {
          throw Exception('Resposta da API é nula');
        }
        return responseData;
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erro ao atualizar veículo: $e');
      throw Exception('Falha ao atualizar veículo: $e');
    }
  }

  Future<void> deleteVehicle(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/veiculos/$id'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erro ao excluir veículo: $e');
      throw Exception('Falha ao excluir veículo');
    }
  }
}
