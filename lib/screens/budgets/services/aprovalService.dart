import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BudgetApprovalService {
  // Ajuste esta URL base para o endpoint de orçamentos da sua API
  // Exemplo: Se o endpoint para atualizar um orçamento é 'https://suaapi.com/api/orcamentos/{id}'
  // A URL base seria 'https://suaapi.com/api/orcamentos'
  final String _baseUrl = 'http://localhost:4040/orcamento'; // AJUSTE ESTA URL

  Future<void> approveBudget(int budgetId) async {
    final _secureStorage = const FlutterSecureStorage();
    final token = await _secureStorage.read(key: 'auth_token');
    final String approveUrl = '$_baseUrl/$budgetId';

    print("Aprovando orçamento (BudgetApprovalService) em: $approveUrl");

    try {
      final response = await http.put(
        Uri.parse(approveUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, String>{
          'status': 'aprovado', // Ou o valor que sua API espera para "aprovado"
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) { // 204 No Content também é sucesso
        print('Orçamento aprovado com sucesso.');
      } else {
        throw Exception(
            'Falha ao aprovar orçamento (BudgetApprovalService): ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception(
          'Erro ao aprovar orçamento (BudgetApprovalService): $e');
    }
  }
}