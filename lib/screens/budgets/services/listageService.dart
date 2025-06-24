import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BudgetService {
  final String _baseUrl = 'http://localhost:4040/api/budgets'; 
  final _secureStorage = const FlutterSecureStorage();

  // Método atualizado para suportar paginação
  Future<Map<String, dynamic>> fetchBudgetsWithPagination({
    int page = 1,
    int limit = 10,
    String? sortField,
    String? sortOrder,
    String? status,
  }) async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      
      if (token == null) {
        throw Exception('Token de autenticação não encontrado');
      }

      // Construir parâmetros da query
      final queryParams = <String, String>{
        '_page': page.toString(),
        '_limit': limit.toString(),
      };

      if (sortField != null && sortField.isNotEmpty) {
        queryParams['_sort'] = sortField;
      }

      if (sortOrder != null && sortOrder.isNotEmpty) {
        queryParams['_order'] = sortOrder;
      }

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      print('Request URL: $uri'); // Debug
      print('Response Status: ${response.statusCode}'); // Debug
      print('Response Body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        
        // Verificar se a estrutura da resposta está correta
        if (decodedJson['data'] != null && decodedJson['meta'] != null) {
          return decodedJson;
        } else {
          throw Exception('Formato de resposta inválido: estrutura esperada não encontrada');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Sessão expirada, faça login novamente');
      } else {
        throw Exception('Falha ao carregar orçamentos: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Erro no BudgetService: $e'); // Debug
      throw Exception('Erro ao buscar orçamentos: $e');
    }
  }
  
  Future<List<Map<String, dynamic>>> fetchBudgets() async {
    final _secureStorage = const FlutterSecureStorage();
    final token = await _secureStorage.read(key: 'auth_token');
    try {
      final response = await http.get(Uri.parse(_baseUrl),
      headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> budgetsJson = decodedJson['data'] as List<dynamic>? ?? [];
        
        List<Map<String, dynamic>> budgets = budgetsJson
            .map((jsonItem) => jsonItem as Map<String, dynamic>)
            .toList();
        return budgets;
      } else {
        throw Exception('Falha ao carregar orçamentos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar orçamentos: $e');
    }
  }
}