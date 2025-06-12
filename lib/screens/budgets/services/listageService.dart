import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BudgetService {
  final String _baseUrl = 'http://localhost:4040/orcamento'; 
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