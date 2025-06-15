import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class ManutencaoDetailScreen extends StatefulWidget {
  final dynamic manutencao;
  final dynamic oficina;

  const ManutencaoDetailScreen({
    Key? key,
    required this.manutencao,
    this.oficina,
  }) : super(key: key);

  @override
  _ManutencaoDetailScreenState createState() => _ManutencaoDetailScreenState();
}

class _ManutencaoDetailScreenState extends State<ManutencaoDetailScreen> {
  final _secureStorage = const FlutterSecureStorage();
  final _motivoController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingOficinas = false;
  String? _errorMessage;
  String? _successMessage;
  final MapController _mapController = MapController();
  DateTime? _dataSelecionada;
  TimeOfDay? _horarioSelecionado;
  final _dataController = TextEditingController();
  final _horarioController = TextEditingController();
  
  // Variáveis para armazenar dados de localização
  String _enderecoCompleto = 'Carregando endereço...';
  bool _isLoadingAddress = true;
  
  // Lista de oficinas
  List<dynamic> _oficinas = [];
  List<dynamic> _oficinasFiltradas = [];
  dynamic _oficinasSelecionada;
  
  // Filtros
  String _filtroNome = '';
  String _filtroCidade = '';
  bool _showFilterOptions = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.oficina != null) {
      _oficinasSelecionada = widget.oficina;
    }
    // Obter o endereço a partir das coordenadas quando a tela é iniciada
    _obterEndereco();
    // Carregar lista de oficinas
    _carregarOficinas();
  }
  
  // Função para carregar oficinas
  Future<void> _carregarOficinas() async {
    setState(() {
      _isLoadingOficinas = true;
    });

    try {
      final token = await _secureStorage.read(key: 'auth_token');
      
      if (token == null) {
        setState(() {
          _isLoadingOficinas = false;
          _errorMessage = 'Sessão expirada. Por favor, faça login novamente.';
        });
        return;
      }

      final url = Uri.parse('http://localhost:4040/api/garage');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Verifica se o resultado é um array ou um objeto
        List<dynamic> data = [];
        if (responseData is List) {
          // Se for uma lista, use diretamente
          data = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          // Se for um objeto com uma propriedade 'data' que é uma lista
          data = responseData['data'] is List ? responseData['data'] : [];
        } else if (responseData is Map) {
          // Se for um objeto simples, converta os valores em uma lista
          data = [responseData];
        }
        
        setState(() {
          _oficinas = data;
          _oficinasFiltradas = data;
          _isLoadingOficinas = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoadingOficinas = false;
          _errorMessage = 'Sessão expirada. Por favor, faça login novamente.';
        });
      } else {
        setState(() {
          _isLoadingOficinas = false;
          _errorMessage = 'Erro ao carregar oficinas: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingOficinas = false;
        _errorMessage = 'Erro de conexão: ${e.toString()}';
      });
    }
  }
  
  Future<void> _selecionarData() async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now().add(const Duration(days: 1)), // Amanhã como padrão
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 365)), // Até 1 ano
    locale: const Locale('pt', 'BR'),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: const Color(0xFF0C7E3D),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      );
    },
  );
  
  if (picked != null && picked != _dataSelecionada) {
    setState(() {
      _dataSelecionada = picked;
      _dataController.text = DateFormat('dd/MM/yyyy').format(picked);
    });
  }
}

// Função para selecionar horário
Future<void> _selecionarHorario() async {
  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: const TimeOfDay(hour: 9, minute: 0), // 09:00 como padrão
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: const Color(0xFF0C7E3D),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      );
    },
  );
  
  if (picked != null && picked != _horarioSelecionado) {
    setState(() {
      _horarioSelecionado = picked;
      _horarioController.text = picked.format(context);
    });
  }
}

// Função para mostrar diálogo de aprovação com data e horário
void _mostrarDialogoAprovacao() {
  // Resetar seleções
  _dataSelecionada = null;
  _horarioSelecionado = null;
  _dataController.clear();
  _horarioController.clear();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Aprovar Manutenção'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_oficinasSelecionada != null) ...[
                    Text(
                      'Oficina: ${_oficinasSelecionada!['nome']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  const Text(
                    'Selecione a data e horário para levar o veículo à mecânica:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  
                  // Campo de data
                  TextField(
                    controller: _dataController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Data *',
                      hintText: 'Selecione a data',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _dataSelecionada = null;
                            _dataController.clear();
                          });
                        },
                      ),
                    ),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: const Color(0xFF0C7E3D),
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      
                      if (picked != null) {
                        setState(() {
                          _dataSelecionada = picked;
                          _dataController.text = DateFormat('dd/MM/yyyy').format(picked);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Campo de horário
                  TextField(
                    controller: _horarioController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Horário (opcional)',
                      hintText: 'Selecione o horário',
                      prefixIcon: const Icon(Icons.access_time),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _horarioSelecionado = null;
                            _horarioController.clear();
                          });
                        },
                      ),
                    ),
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 9, minute: 0),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: const Color(0xFF0C7E3D),
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      
                      if (picked != null) {
                        setState(() {
                          _horarioSelecionado = picked;
                          _horarioController.text = picked.format(context);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'A data é obrigatória. O horário é opcional e pode ser definido posteriormente.',
                            style: TextStyle(fontSize: 14, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text(
                  'Aprovar',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  if (_dataSelecionada == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor, selecione uma data.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).pop();
                  _aprovarManutencao();
                },
              ),
            ],
          );
        },
      );
    },
  );
}

  // Função para filtrar oficinas
  void _filtrarOficinas() {
    setState(() {
      _oficinasFiltradas = _oficinas.where((oficina) {
        final nomeMatch = _filtroNome.isEmpty || 
            oficina['nome'].toString().toLowerCase().contains(_filtroNome.toLowerCase());
        
        final cidadeMatch = _filtroCidade.isEmpty || 
            oficina['cidade'].toString().toLowerCase().contains(_filtroCidade.toLowerCase());
        
        return nomeMatch && cidadeMatch;
      }).toList();
    });
  }
  
  // Função para obter o endereço a partir de latitude e longitude
  Future<void> _obterEndereco() async {
  final bool hasCoordinates = 
      widget.manutencao['latitude'] != null && 
      widget.manutencao['longitude'] != null;
  
  if (!hasCoordinates) {
    setState(() {
      _enderecoCompleto = 'Localização não disponível';
      _isLoadingAddress = false;
    });
    return;
  }
  
  // Converter coordenadas para double
  final latitude = double.tryParse(widget.manutencao['latitude'].toString()) ?? 0.0;
  final longitude = double.tryParse(widget.manutencao['longitude'].toString()) ?? 0.0;
  
  if (latitude == 0.0 && longitude == 0.0) {
    setState(() {
      _enderecoCompleto = 'Coordenadas inválidas';
      _isLoadingAddress = false;
    });
    return;
  }
  
  try {
    // Construir a URL para a API geocode.xyz
    final url = 'https://geocode.xyz/$latitude,$longitude?geoit=json';
    
    print('Fazendo requisição para: $url');
    
    // Fazer a requisição HTTP
    final response = await http.get(Uri.parse(url));
    
    print('Status da resposta: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      // Decodificar a resposta JSON
      final data = json.decode(response.body);
      
      
      // Extrair os dados relevantes
      String? rua = data['staddress'];
      String? numero = data['stnumber'];
      String? cidade = data['city'];
      String? estado = data['prov'];
      
      // Construir o endereço completo
      List<String> partes = [];
      
      // Adicionar rua e número se disponíveis
      if (rua != null && rua.isNotEmpty) {
        if (numero != null && numero.isNotEmpty) {
          partes.add('$rua, $numero');
        } else {
          partes.add(rua);
        }
      }
      
      // Adicionar cidade se disponível
      if (cidade != null && cidade.isNotEmpty) {
        partes.add(cidade);
      }
      
      // Adicionar estado se disponível
      if (estado != null && estado.isNotEmpty) {
        partes.add(estado);
      }
      
      // Juntar todas as partes com vírgula e espaço
      final endereco = partes.join(', ');
      
      setState(() {
        _enderecoCompleto = endereco.isNotEmpty ? endereco : 'Endereço não encontrado';
        _isLoadingAddress = false;
      });
    } else {
      print('Erro na resposta da API: ${response.body}');
      setState(() {
        _enderecoCompleto = 'Erro ao obter o endereço: ${response.statusCode}';
        _isLoadingAddress = false;
      });
    }
  } catch (e) {
    print('Erro ao obter endereço: $e');
    setState(() {
      _enderecoCompleto = 'Não foi possível obter o endereço: ${e.toString()}';
      _isLoadingAddress = false;
    });
  }
}
  
  
  // Função para formatar a data
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Data não disponível';
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Função para mostrar diálogo de seleção de oficina
  void _mostrarDialogoSelecionarOficina() {
    // Resetar filtros
    _filtroNome = '';
    _filtroCidade = '';
    final oficinasData = _oficinas[0]['oficinas'] as List;
    _oficinasFiltradas = List.from(oficinasData);
    _searchController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Selecionar Oficina'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Campo de pesquisa
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Pesquisar oficina...',
                        suffixIcon: IconButton(
                          icon: Icon(_showFilterOptions 
                              ? Icons.filter_list_off 
                              : Icons.filter_list),
                          onPressed: () {
                            setState(() {
                              _showFilterOptions = !_showFilterOptions;
                            });
                          },
                        ),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _filtroNome = value;
                          this._filtrarOficinas();
                        });
                      },
                    ),
                    
                    // Opções de filtro expandidas
                    if (_showFilterOptions) ...[
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Filtrar por cidade...',
                          prefixIcon: const Icon(Icons.location_city),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _filtroCidade = value;
                            this._filtrarOficinas();
                          });
                        },
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Lista de oficinas
                    Expanded(
                      child: _isLoadingOficinas
                        ? const Center(child: CircularProgressIndicator())
                        : _oficinasFiltradas.isEmpty
                          ? const Center(child: Text('Nenhuma oficina encontrada.'))
                          : ListView.builder(
                              itemCount: _oficinasFiltradas.length,
                              itemBuilder: (context, index) {
                                final oficina = _oficinasFiltradas[index];
                                return ListTile(
                                  title: Text(oficina['nome']),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${oficina['cidade']} - ${oficina['estado']}'),
                                      Text(oficina['telefone']),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    setState(() {
                                      this._oficinasSelecionada = oficina;
                                    });
                                    this.setState(() {
                                      _oficinasSelecionada = oficina;
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Função para aprovar manutenção
  Future<void> _aprovarManutencao() async {
  // Verificar se uma oficina foi selecionada
  if (_oficinasSelecionada == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Por favor, selecione uma oficina antes de aprovar a manutenção.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Verificar se uma data foi selecionada
  if (_dataSelecionada == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Por favor, selecione uma data para levar o veículo à mecânica.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
  });

  try {
    final token = await _secureStorage.read(key: 'auth_token');
    
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sessão expirada. Por favor, faça login novamente.';
      });
      return;
    }

    final url = Uri.parse('http://localhost:4040/api/maintenance/${widget.manutencao['id']}/aprovar');
    
    // Preparar o corpo da requisição
    final requestBody = {
      'oficinaId': _oficinasSelecionada['id'],
      'dataEnviarMecanica': DateFormat('yyyy-MM-dd').format(_dataSelecionada!),
    };

    // Adicionar horário se foi selecionado
    if (_horarioSelecionado != null) {
      requestBody['horarioEnviarMecanica'] = 
          '${_horarioSelecionado!.hour.toString().padLeft(2, '0')}:${_horarioSelecionado!.minute.toString().padLeft(2, '0')}';
    }
    
    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 204) {
      setState(() {
        _isLoading = false;
        _successMessage = 'Manutenção aprovada com sucesso!';
      });
      
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context, true);
      });
    } else if (response.statusCode == 401) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sessão expirada. Por favor, faça login novamente.';
      });
    } else {
      try {
        final errorData = jsonDecode(response.body);
        setState(() {
          _isLoading = false;
          _errorMessage = errorData['error'] ?? 'Erro ao aprovar manutenção.';
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao aprovar manutenção: ${response.statusCode}';
        });
      }
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
      _errorMessage = 'Erro de conexão: ${e.toString()}';
    });
  }
}

  // Função para reprovar manutenção
  Future<void> _reprovarManutencao(String motivo) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final token = await _secureStorage.read(key: 'auth_token');
      
      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sessão expirada. Por favor, faça login novamente.';
        });
        return;
      }

      final url = Uri.parse('http://localhost:4040/api/maintenance/${widget.manutencao['id']}/reprovar');
      
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'motivoReprovacao': motivo}),
      );

      if (response.statusCode == 204) {
        setState(() {
          _isLoading = false;
          _successMessage = 'Manutenção reprovada com sucesso!';
        });
        
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context, true);
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sessão expirada. Por favor, faça login novamente.';
        });
      } else {
        try {
          final errorData = jsonDecode(response.body);
          setState(() {
            _isLoading = false;
            _errorMessage = errorData['error'] ?? 'Erro ao reprovar manutenção.';
          });
        } catch (e) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Erro ao reprovar manutenção: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro de conexão: ${e.toString()}';
      });
    }
  }

  // Função para mostrar diálogo de reprovação
  void _mostrarDialogoReprovacao() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reprovar Manutenção'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Por favor, informe o motivo da reprovação:'),
              const SizedBox(height: 16),
              TextField(
                controller: _motivoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Digite o motivo da reprovação',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Reprovar', style: TextStyle(color: Colors.white),),
              onPressed: () {
                if (_motivoController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, informe o motivo da reprovação.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop();
                _reprovarManutencao(_motivoController.text.trim());
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _motivoController.dispose();
    _searchController.dispose();
    _dataController.dispose();  // Adicione esta linha
    _horarioController.dispose();  // Adicione esta linha
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final veiculo = widget.manutencao['veiculo'];
    
    // Verificar se existem coordenadas
    final bool hasCoordinates = 
        widget.manutencao['latitude'] != null && 
        widget.manutencao['longitude'] != null;
    
    // Converter coordenadas para double (se existirem)
    final latitude = hasCoordinates ? 
        double.tryParse(widget.manutencao['latitude'].toString()) ?? 0.0 : 0.0;
    final longitude = hasCoordinates ? 
        double.tryParse(widget.manutencao['longitude'].toString()) ?? 0.0 : 0.0;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(veiculo['placa'] ?? 'Detalhe da Manutenção'),
        backgroundColor: const Color(0xFF0C7E3D),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Recarregar dados do endereço
              setState(() {
                _isLoadingAddress = true;
                _enderecoCompleto = 'Carregando endereço...';
                _oficinasSelecionada = null;
              });
              _obterEndereco();
              _carregarOficinas();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mensagens de erro ou sucesso
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[900]),
                    ),
                  ),
                
                if (_successMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _successMessage!,
                      style: TextStyle(color: Colors.green[900]),
                    ),
                  ),
                
                // Informações do veículo
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            veiculo['placa'] ?? 'Placa não informada',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(widget.manutencao['status']),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Status: ${_getStatusText(widget.manutencao['status'] ?? "Desconhecido")}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Marca: ${veiculo['marca'] ?? ''} ${veiculo['modelo'] ?? ''} ${veiculo['anoModelo'] ?? ''}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chassi: ${veiculo['chassi'] ?? 'Não informado'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'Supervisor: ',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            widget.manutencao['supervisor'] != null && widget.manutencao['supervisor']['nome'] != null
                                ? widget.manutencao['supervisor']['nome']
                                : 'Não informado',
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (widget.manutencao['supervisor'] != null && widget.manutencao['supervisor']['nome'] != null) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.message,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Data e Horário
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 18),
                                    SizedBox(width: 4),
                                    Text('Data:'),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(_formatDate(widget.manutencao['dataSolicitacao'])),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.access_time, size: 18),
                                    SizedBox(width: 4),
                                    Text('Horário:'),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.manutencao['dataSolicitacao'] != null
                                      ? DateFormat('HH:mm').format(
                                          DateTime.parse(widget.manutencao['dataSolicitacao'])
                                        )
                                      : 'Horário não disponível',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Oficina selecionada (se houver)
                if (_oficinasSelecionada != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Oficina Selecionada:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              if (widget.manutencao['status']?.toLowerCase() == 'pendente')
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                  onPressed: _mostrarDialogoSelecionarOficina,
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(_oficinasSelecionada['nome'] ?? 'Nome não disponível', style: const TextStyle(fontSize: 16)),
                          Text('${_oficinasSelecionada['rua'] ?? ''}, ${_oficinasSelecionada['bairro'] ?? ''}'),
                          Text('${_oficinasSelecionada['cidade'] ?? ''} - ${_oficinasSelecionada['estado'] ?? ''}'),
                          Text('Tel: ${_oficinasSelecionada['telefone'] ?? 'Não informado'}'),
                          Text('Email: ${_oficinasSelecionada['email'] ?? 'Não informado'}'),
                          Text(
                            'Data para levar: ${_formatDate(widget.manutencao['dataEnviarMecanica']) ?? 'Não informado'} - ${DateFormat('HH:mm').format(DateTime.parse(widget.manutencao['dataSolicitacao']))}',
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Motivo da reprovação (se aplicável)
                if (widget.manutencao['status']?.toLowerCase() == 'reprovada' && 
                    widget.manutencao['motivoReprovacao'] != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Motivo da reprovação:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(widget.manutencao['motivoReprovacao']),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Descrição do problema
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Problema:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.manutencao['descricaoProblema'] ?? 'Sem descrição do problema',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 250,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: hasCoordinates
                        ? FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              center: LatLng(latitude, longitude),
                              zoom: 15,
                              interactiveFlags: InteractiveFlag.all,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                                userAgentPackageName: 'com.example.app',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(latitude, longitude),
                                    width: 80,
                                    height: 80,
                                    builder: (context) => const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.location_off,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Localização não disponível',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                
                // Endereço em vez das coordenadas
                if (hasCoordinates)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: Colors.red),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Localização:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    _isLoadingAddress
                                        ? const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.blue,
                                            ),
                                          )
                                        : const SizedBox(),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _enderecoCompleto,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Botões de ação (apenas mostrar se o status for pendente)
                (widget.manutencao['status']?.toLowerCase() == 'pendente')
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Botão de seleção de oficina
                            if (_oficinasSelecionada == null)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 16),
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.store, color: Colors.white),
                                  label: const Text(
                                    'Selecionar Oficina',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: _mostrarDialogoSelecionarOficina,
                                ),
                              ),
                            
                            // Botões de aprovar/reprovar
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[400],
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: _isLoading ? null : _mostrarDialogoReprovacao,
                                    child: const Text(
                                      'Reprovar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: _oficinasSelecionada == null || _isLoading 
                                        ? null 
                                        : _mostrarDialogoAprovacao, // Mudança aqui!
                                    child: const Text(
                                      'Aprovar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(height: 16),
                
                // Mapa com OpenStreetMap
                
                
                const SizedBox(height: 24),
              ],
            ),
          ),
          
          // Indicador de carregamento
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Função para obter cor baseada no status
  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    switch (status.toLowerCase()) {
      case 'pendente':
        return Colors.orange;
      case 'aprovada':
        return Colors.green;
      case 'reprovada':
        return Colors.red;
      case 'concluída':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  // Função para obter texto do status
  String _getStatusText(String? status) {
    if (status == null) return 'Desconhecido';
    
    switch (status.toLowerCase()) {
      case 'pendente':
        return 'Pendente';
      case 'aprovada':
        return 'Em Andamento';
      case 'reprovada':
        return 'Reprovada';
      case 'concluída':
        return 'Concluída';
      default:
        return status;
    }
  }
}