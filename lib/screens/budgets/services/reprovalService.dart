import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BudgetReprovalService {
  final String _baseUrl = 'http://localhost:4040/api/budgets'; // AJUSTE ESTA URL

  Future<void> reproveBudget(int budgetId, bool reciveNewBudget, String description) async {
    final _secureStorage = const FlutterSecureStorage();
    final token = await _secureStorage.read(key: 'auth_token');
    final String reproveUrl = '$_baseUrl/$budgetId';

    print("Reprovando orçamento (BudgetReprovalService) em: $reproveUrl");
    print(reciveNewBudget);
    print(description);
    
    try {
      final response = await http.delete(
        Uri.parse(reproveUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'reciveNewBudget': reciveNewBudget,
          'description': description,
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