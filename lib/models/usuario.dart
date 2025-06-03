class Usuario {
  final int id;
  final String nome;
  final String email;
  final String login;
  final String funcao;
  bool ativo;
  
  Usuario({
    required this.id,
    required this.nome,
    required this.email, 
    required this.login,
    required this.funcao,
    this.ativo = true,
  });
  
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      login: json['login'],
      funcao: json['funcao'],
      ativo: json['ativo'] ?? true,
    );
  }
}