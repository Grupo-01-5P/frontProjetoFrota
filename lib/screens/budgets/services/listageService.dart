import 'dart:convert';
import 'package:http/http.dart' as http;

class BudgetService {
  final String _baseUrl = 'http://localhost:3001/orcamento'; 
  Future<List<Map<String, dynamic>>> fetchBudgets() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

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