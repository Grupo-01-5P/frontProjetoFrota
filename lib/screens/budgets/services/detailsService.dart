import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BudgetDetailsService {
  final String _baseUrl = 'http://localhost:4040/orcamento'; // AJUSTE ESTA URL

  Future<Map<String, dynamic>> fetchBudgetDetails(int budgetId) async {
    final _secureStorage = const FlutterSecureStorage();
    final token = await _secureStorage.read(key: 'auth_token');
    final String detailUrl = '$_baseUrl/$budgetId';

    print("Buscando detalhes do orçamento (BudgetDetailsService) em: $detailUrl"); 

    try {
      final response = await http.get(Uri.parse(detailUrl),
      headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },);

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

  final String _orcamentoProdutosBaseUrl = 'http://localhost:4040/orcamento';

  Future<void> removeProductFromBudget(int orcamentoProdutoId) async {
    // orcamentoProdutoId é o ID da entrada específica do produto NAQUELE orçamento
    // (o 'id' que está dentro de cada objeto na lista 'produtos' do orçamento)
    final _secureStorage = const FlutterSecureStorage();
    final token = await _secureStorage.read(key: 'auth_token');
    final String deleteUrl = '$_orcamentoProdutosBaseUrl/$orcamentoProdutoId';

    print("Removendo produto do orçamento (BudgetDetailsService) em: $deleteUrl");

    try {
      final response = await http.delete(
        Uri.parse(deleteUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) { // 204 No Content também é sucesso para DELETE
        print('Produto removido do orçamento com sucesso.');
      } else {
        throw Exception(
            'Falha ao remover produto do orçamento: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception(
          'Erro ao remover produto do orçamento: $e');
    }
  }
}

  