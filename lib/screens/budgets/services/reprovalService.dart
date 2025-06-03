import 'dart:convert';
import 'package:http/http.dart' as http;

class BudgetReprovalService {
  final String _baseUrl = 'http://localhost:3001/orcamento'; // AJUSTE ESTA URL

  Future<void> reproveBudget(int budgetId) async {
    final String reproveUrl = '$_baseUrl/$budgetId';

    print("Reprovando orçamento (BudgetReprovalService) em: $reproveUrl");

    try {
      final response = await http.put(
        Uri.parse(reproveUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'status': 'reproved', // Conforme especificado, apenas o status muda
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) { // 204 No Content também é sucesso
        print('Orçamento reprovado com sucesso.');
      } else {
        throw Exception(
            'Falha ao reprovar orçamento (BudgetReprovalService): ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception(
          'Erro ao reprovar orçamento (BudgetReprovalService): $e');
    }
  }
}