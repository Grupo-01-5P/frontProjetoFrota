import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VehicleService {
  // Configuração da API
  static const String baseUrl = 'http://localhost:4040/api';
  static const _secureStorage = FlutterSecureStorage();

  // Método para obter headers com token dinâmico
  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

   Future<Map<String, dynamic>> getVehiclesWithStatus(String statusFilter) async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      
      if (token == null) {
        throw Exception('Token de autenticação não encontrado');
      }

      // Construir URL com filtro se necessário
      String url = '$baseUrl/veiculos';
      if (statusFilter != 'todos') {
        url += '?status=$statusFilter';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Sessão expirada. Por favor, faça login novamente.');
      } else {
        throw Exception('Erro ao carregar veículos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: ${e.toString()}');
    }
  }

  // Obter lista de veículos
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
        return jsonData['data'] ?? [];
      } else if (response.statusCode == 401) {
        throw Exception('Token de autenticação inválido ou expirado');
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erro na requisição: $e'); // Debug
      throw Exception('Erro na conexão: $e');
    }
  }

  // Obter detalhes de um veículo específico
  Future<Map<String, dynamic>> getVehicleDetails(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/veiculos/$id'),
        headers: headers,
      );

      print('Resposta bruta: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Token de autenticação inválido ou expirado');
      } else if (response.statusCode == 404) {
        throw Exception('Veículo não encontrado');
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erro ao obter detalhes do veículo: $e');
      throw Exception('Falha ao carregar detalhes do veículo: $e');
    }
  }

  // Buscar veículo por placa
  Future<List<Map<String, dynamic>>> searchVehicleByPlate(String plate) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/veiculos?placa=$plate'),
        headers: headers,
      );

      print('Resposta da busca: ${response.statusCode} - ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Adapte conforme a estrutura da sua API:
        if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Token de autenticação inválido ou expirado');
      } else {
        throw Exception('Erro na busca: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro na busca por placa: $e');
      throw Exception('Falha ao buscar veículos: $e');
    }
  }

  // Criar novo veículo
  Future<Map<String, dynamic>> createVehicle(Map<String, dynamic> vehicleData) async {
    try {
      final headers = await _getHeaders();
      print('Criando veículo com dados: ${json.encode(vehicleData)}'); // Debug

      final response = await http.post(
        Uri.parse('$baseUrl/veiculos'),
        headers: headers,
        body: json.encode(vehicleData),
      );

      print('Resposta do cadastro: ${response.statusCode} - ${response.body}'); // Debug

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Token de autenticação inválido ou expirado');
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Dados inválidos');
      } else if (response.statusCode == 409) {
        throw Exception('Placa já cadastrada no sistema');
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erro ao criar veículo: $e');
      throw Exception('Falha ao cadastrar veículo: $e');
    }
  }

  // Verificar se placa já existe
  Future<bool> checkPlacaExistente(String placa) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/veiculos/verifica-placa/$placa'),
        headers: headers,
      );

      print('Verificação de placa: ${response.statusCode} - ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['existe'] ?? false;
      } else if (response.statusCode == 401) {
        throw Exception('Token de autenticação inválido ou expirado');
      }
      return false;
    } catch (e) {
      print('Erro ao verificar placa: $e');
      // Em caso de erro, retorna false para não bloquear o cadastro
      return false;
    }
  }

  // Atualizar veículo
  Future<Map<String, dynamic>> updateVehicle(int id, Map<String, dynamic> vehicleData) async {
    try {
      final headers = await _getHeaders();
      print('Atualizando veículo $id com dados: ${json.encode(vehicleData)}'); // Debug

      final response = await http.put(
        Uri.parse('$baseUrl/veiculos/$id'),
        headers: headers,
        body: json.encode(vehicleData),
      );

      print('Resposta da atualização: ${response.statusCode} - ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData == null) {
          throw Exception('Resposta da API é nula');
        }
        return responseData;
      } else if (response.statusCode == 401) {
        throw Exception('Token de autenticação inválido ou expirado');
      } else if (response.statusCode == 404) {
        throw Exception('Veículo não encontrado');
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Dados inválidos');
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erro ao atualizar veículo: $e');
      throw Exception('Falha ao atualizar veículo: $e');
    }
  }

  // Excluir veículo
  Future<void> deleteVehicle(int id) async {
    try {
      final headers = await _getHeaders();
      print('Excluindo veículo: $id'); // Debug

      final response = await http.delete(
        Uri.parse('$baseUrl/veiculos/$id'),
        headers: headers,
      );

      print('Resposta da exclusão: ${response.statusCode} - ${response.body}'); // Debug

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Sucesso na exclusão
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Token de autenticação inválido ou expirado');
      } else if (response.statusCode == 404) {
        throw Exception('Veículo não encontrado');
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erro ao excluir veículo: $e');
      throw Exception('Falha ao excluir veículo: $e');
    }
  }

  // Método para obter veículos sem supervisor (para cadastro de usuários)
  Future<List<Map<String, dynamic>>> getVehiclesWithoutSupervisor({int page = 1, int limit = 200}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/veiculos/withoutSupervisior?_page=$page&_limit=$limit'),
        headers: headers,
      );

      print('Veículos sem supervisor: ${response.statusCode} - ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Token de autenticação inválido ou expirado');
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erro ao obter veículos sem supervisor: $e');
      throw Exception('Falha ao carregar veículos sem supervisor: $e');
    }
  }

  // Método para validar conectividade com a API
  Future<bool> testConnection() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/veiculos?_page=1&_limit=1'),
        headers: headers,
      );
      return response.statusCode == 200 || response.statusCode == 401;
    } catch (e) {
      print('Erro de conectividade: $e');
      return false;
    }
  }
}