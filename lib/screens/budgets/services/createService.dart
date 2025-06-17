import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BudgetCreateService {
  // URL base para a API de oficinas e manutenções
  final String _baseUrl = 'http://localhost:4040/api';
  // URL para a criação de orçamentos
  final String _budgetUrl = 'http://localhost:4040/orcamento';

  /// Busca a lista de manutenções disponíveis.
  Future<List<dynamic>> fetchMaintenances() async {
      final _secureStorage = const FlutterSecureStorage();
      final token = await _secureStorage.read(key: 'auth_token');
    try {
      final response = await http.get(Uri.parse(
        '$_baseUrl/maintenance'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

       if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);

        List<dynamic> allMaintenances;
        // Se a sua API de manutenções usar uma chave diferente, altere a string abaixo.
        const String key = 'manutencoes'; 

        if (decodedData is Map<String, dynamic> && decodedData.containsKey(key)) {
            allMaintenances = decodedData[key] as List<dynamic>;
        }
        else if (decodedData is List) {
            allMaintenances = decodedData;
        }
        else {
            throw Exception('Formato de resposta da API para manutenções é inesperado.');
        }

        // NOVO: Filtra a lista para remover qualquer manutenção com status "Em analise".
        final filteredMaintenances = allMaintenances.where((maintenance) {
          // Acessa o status de forma segura e faz a comparação sem diferenciar maiúsculas/minúsculas.
          final status = (maintenance['status'] as String?)?.toLowerCase() ?? '';
          return status != 'em analise';
        }).toList();
        
        return filteredMaintenances;

      } else {
        throw Exception('Falha ao carregar manutenções: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão ao buscar manutenções: $e');
    }
  }

  /// Busca a lista de oficinas disponíveis.
  Future<List<dynamic>> fetchGarages() async {
    final _secureStorage = const FlutterSecureStorage();
    final token = await _secureStorage.read(key: 'auth_token');
    try {
      final response = await http.get(Uri.parse(
        '$_baseUrl/garage'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        );

     if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);

        // CORREÇÃO: Extrai a lista de dentro da chave "oficinas",
        // conforme a estrutura que você forneceu.
        const String key = 'oficinas'; 
        if (decodedData is Map<String, dynamic> && decodedData.containsKey(key)) {
            return decodedData[key] as List<dynamic>;
        }
        else if (decodedData is List) {
            return decodedData;
        }
        else {
            throw Exception('Formato de resposta da API para oficinas é inesperado.');
        }
        
      } else {
        throw Exception('Falha ao carregar oficinas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão ao buscar oficinas: $e');
    }
  }

  /// Envia os dados do novo orçamento para a API.
  Future<bool> createBudget(Map<String, dynamic> budgetData) async {
    final _secureStorage = const FlutterSecureStorage();
    final token = await _secureStorage.read(key: 'auth_token');
    try {
      print(budgetData);
      final response = await http.post(
        Uri.parse(_budgetUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(budgetData),
      );

      // O código 201 (Created) geralmente indica sucesso na criação.
      if (response.statusCode == 201) {
        return true;
      } else {
        // Imprime o corpo da resposta para ajudar na depuração.
        print('Falha ao criar orçamento. Status: ${response.statusCode}');
        print('Corpo da resposta: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Erro de conexão ao criar orçamento: $e');
      return false;
    }
  }

  Future<bool> updateMaintenanceStatus(int maintenanceId) async {
    final url = Uri.parse('$_baseUrl/maintenance/$maintenanceId');
    final _secureStorage = const FlutterSecureStorage();
    final token = await _secureStorage.read(key: 'auth_token');
    try {
      final response = await http.put(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        // O corpo da requisição contém apenas o campo a ser alterado.
        body: jsonEncode({'status': 'Em analise'}),
      );

      // Um status 200 (OK) ou 204 (No Content) geralmente indica sucesso em um PUT.
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('Falha ao atualizar status. Status: ${response.statusCode}');
        print('Corpo da resposta: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Erro de conexão ao atualizar status: $e');
      return false;
    }
  }
}
