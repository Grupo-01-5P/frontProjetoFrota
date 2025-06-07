import 'package:flutter/material.dart';

class MecanicasPage extends StatelessWidget {
  const MecanicasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mecânicas'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Card para "Cadastrar uma nova mecânica"
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.add_business, size: 40),
                title: const Text(
                  'Cadastrar uma nova mecânica',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  // Ação para cadastrar mecânica
                },
              ),
            ),
            const SizedBox(height: 16),
            // Card para "Visualizar mecânicas"
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.store, size: 40),
                title: const Text(
                  'Visualizar mecânicas',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  // Ação para visualizar mecânicas
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}