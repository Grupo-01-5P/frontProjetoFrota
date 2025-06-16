import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BudgetDetailsService {
  final String _baseUrl = 'http://localhost:4040/orcamento'; // AJUSTE ESTA URL

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

  final String _orcamentoProdutosBaseUrl = 'http://localhost:4040/orcamento';

  Future<void> removeProductFromBudget(int orcamentoProdutoId) async {
    final _secureStorage = const FlutterSecureStorage();
    final token = await _secureStorage.read(key: 'auth_token');
    final String deleteUrl = '$_orcamentoProdutosBaseUrl/$orcamentoProdutoId';

    print(
      "Removendo produto do orçamento (BudgetDetailsService) em: $deleteUrl",
    );

    try {
      final response = await http.delete(
        Uri.parse(deleteUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 204 No Content também é sucesso para DELETE
        print('Produto removido do orçamento com sucesso.');
      } else {
        throw Exception(
          'Falha ao remover produto do orçamento: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao remover produto do orçamento: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllProducts() async {
    final _secureStorage = const FlutterSecureStorage();
    final token = await _secureStorage.read(key: 'auth_token');
    // Lembre-se de usar 10.0.2.2 para o emulador Android ao invés de localhost
    final response = await http.get(
      Uri.parse('http://localhost:4040/api/products'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decodedBody = json.decode(utf8.decode(response.bodyBytes));

      // A API está retornando um objeto (Map) que envolve a lista.
      // A chave que contém a lista pode variar. Em APIs com paginação,
      // é comum ser a chave "content".
      final List<dynamic> productList;
      if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('data')) {
        // Extrai a lista de dentro da chave 'content'
        productList = decodedBody['data'] as List<dynamic>;
      } else if (decodedBody is List<dynamic>) {
        // Caso a API retorne a lista diretamente (sem o objeto em volta)
        productList = decodedBody;
      } else {
        // Se a estrutura não for a esperada, lança um erro claro.
        throw Exception('Formato de resposta da API inesperado. Esperava uma lista ou um objeto com a chave "content".');
      }
      
      return productList.map((product) => product as Map<String, dynamic>).toList();
    } else {
      throw Exception('Falha ao carregar a lista de produtos. Status: ${response.statusCode}');
    }
  }

  /// NOVO: Adiciona um produto a um orçamento existente.
  Future<void> addProductToBudget(
    int budgetId,
    Map<String, dynamic> data,
  ) async {
    final _secureStorage = const FlutterSecureStorage();
    final token = await _secureStorage.read(key: 'auth_token');
    // ATUALIZADO: Usando a variável _baseUrl para consistência
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

    // 201 Created é o status de sucesso esperado para um POST que cria um recurso.
    if (response.statusCode != 201) {
      throw Exception(
        'Falha ao adicionar produto. Status: ${response.statusCode}',
      );
    }
  }
}
