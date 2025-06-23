import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BudgetDetailsService {
  final String _baseUrl = 'http://localhost:4040/api/budgets'; 

  Future<Map<String, dynamic>> fetchBudgetDetails(int budgetId) async {
    final _secureStorage = const FlutterSecureStorage();
    final token = await _secureStorage.read(key: 'auth_token');
    final String detailUrl = '$_baseUrl/$budgetId';

    print(
      "Buscando detalhes do orçamento (BudgetDetailsService) em: $detailUrl",
    );

    try {
      final response = await http.get(
        Uri.parse(detailUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> budgetDetails = json.decode(response.body);
        return budgetDetails;
      } else {
        throw Exception(
          'Falha ao carregar detalhes do orçamento (BudgetDetailsService): ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception(
        'Erro ao buscar detalhes do orçamento (BudgetDetailsService): $e',
      );
    }
  }

  final String _orcamentoProdutosBaseUrl = 'http://localhost:4040/api/budgets';

  Future<void> removeProductFromBudget(int budgetId, int productId) async {
    final _secureStorage = const FlutterSecureStorage();
    final token = await _secureStorage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/$budgetId/produtos/$productId');
    print('DELETE: $url'); 

    try {
      final response = await http.delete(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        print('Falha ao remover produto: ${response.statusCode}');
        print('Corpo da resposta: ${response.body}');
        throw Exception('Falha ao remover produto do orçamento. Código: ${response.statusCode}');
      }
      print('Produto removido com sucesso!');

    } catch (e) {
      print('Erro de rede ou conexão em removeProductFromBudget: $e');
      throw Exception('Erro de conexão ao remover o produto.');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllProducts() async {
    final _secureStorage = const FlutterSecureStorage();
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await http.get(
      Uri.parse('http://localhost:4040/api/products'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decodedBody = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> productList;
      if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('data')) {
        productList = decodedBody['data'] as List<dynamic>;
      } else if (decodedBody is List<dynamic>) {
        productList = decodedBody;
      } else {
        throw Exception('Formato de resposta da API inesperado. Esperava uma lista ou um objeto com a chave "content".');
      }
      
      return productList.map((product) => product as Map<String, dynamic>).toList();
    } else {
      throw Exception('Falha ao carregar a lista de produtos. Status: ${response.statusCode}');
    }
  }

  Future<void> addProductToBudget(
    int budgetId,
    Map<String, dynamic> data,
  ) async {
    final _secureStorage = const FlutterSecureStorage();
    final token = await _secureStorage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/$budgetId/produtos');
    print(data);
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Falha ao adicionar produto. Status: ${response.statusCode}',
      );
    }
  }
}
