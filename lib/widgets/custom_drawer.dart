import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Frota Mais',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Início'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navegar para a tela inicial
            },
          ),
          ListTile(
            leading: const Icon(Icons.build),
            title: const Text('Manutenções'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navegar para a tela de manutenções
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Produtos'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navegar para a tela de produtos
            },
          ),
        ],
      ),
    );
  }
}
