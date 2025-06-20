import 'package:flutter/material.dart';

// Definindo constantes de estilo
const kPrimaryColor = Color(0xFF148553);

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;
  final bool isSupervisor; // Novo parâmetro para identificar o perfil

  const CustomBottomNavigation({
    Key? key,
    required this.currentIndex,
    this.onTap,
    this.isSupervisor = false, // Valor padrão é false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: onTap,
              elevation: 0,
              backgroundColor: Colors.transparent,
              selectedItemColor: kPrimaryColor,
              unselectedItemColor: Colors.grey[400],
              type: BottomNavigationBarType.fixed,
              items: isSupervisor 
                ? _getSupervisorItems() 
                : _getMechanicItems(),
            ),
          ),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _getSupervisorItems() {
    return [
      BottomNavigationBarItem(
        icon: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset(
            'lib/assets/images/iconManutencoes.png',
            color: Colors.grey[400],
          ),
        ),
        activeIcon: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset(
            'lib/assets/images/iconManutencoes.png',
            color: kPrimaryColor,
          ),
        ),
        label: 'Manutenções',
      ),
      BottomNavigationBarItem(
        icon: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset(
            'lib/assets/images/iconHome.png',
            color: Colors.grey[400],
          ),
        ),
        activeIcon: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset(
            'lib/assets/images/iconHome.png',
            color: kPrimaryColor,
          ),
        ),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset(
            'lib/assets/images/iconInoperantes.png',
            color: Colors.grey[400],
          ),
        ),
        activeIcon: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset(
            'lib/assets/images/iconInoperantes.png',
            color: kPrimaryColor,
          ),
        ),
        label: 'Inoperantes',
      ),
    ];
  }

  List<BottomNavigationBarItem> _getMechanicItems() {
    return [
      BottomNavigationBarItem(
        icon: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset(
            'lib/assets/images/iconManutencoes.png',
            color: Colors.grey[400],
          ),
        ),
        activeIcon: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset(
            'lib/assets/images/iconManutencoes.png',
            color: kPrimaryColor,
          ),
        ),
        label: 'Manutenções',
      ),
      BottomNavigationBarItem(
        icon: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset(
            'lib/assets/images/iconTerceirize.png',
            color: Colors.grey[400],
          ),
        ),
        activeIcon: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset(
            'lib/assets/images/iconTerceirize.png',
            color: kPrimaryColor,
          ),
        ),
        label: 'Orçamentos',
      ),
      BottomNavigationBarItem(
        icon: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset(
            'lib/assets/images/iconInoperantes.png',
            color: Colors.grey[400],
          ),
        ),
        activeIcon: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset(
            'lib/assets/images/iconInoperantes.png',
            color: kPrimaryColor,
          ),
        ),
        label: 'Inoperantes',
      ),
    ];
  }
} 
