import 'dart:convert';
import 'package:http/http.dart' as http;

class BudgetDetailsService {
  final String _baseUrl = 'http://localhost:3001/orcamento'; // AJUSTE ESTA URL

  Future<Map<String, dynamic>> fetchBudgetDetails(int budgetId) async {
    final String detailUrl = '$_baseUrl/$budgetId';

    print("Buscando detalhes do orçamento (BudgetDetailsService) em: $detailUrl"); 

    try {
      final response = await http.get(Uri.parse(detailUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> budgetDetails = json.decode(response.body);
        return budgetDetails;
      } else {
        throw Exception(
            'Falha ao carregar detalhes do orçamento (BudgetDetailsService): ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception(
          'Erro ao buscar detalhes do orçamento (BudgetDetailsService): $e');
    }
  }
}