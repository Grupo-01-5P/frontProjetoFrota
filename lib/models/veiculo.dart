// lib/models/veiculo.dart
class Veiculo {
  final String id;
  final String placa;
  final String modelo;
  bool selecionado;

  Veiculo({
    required this.id,
    required this.placa,
    required this.modelo,
    this.selecionado = false,
  });
}