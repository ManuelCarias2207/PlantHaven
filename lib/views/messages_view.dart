import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MessagesView extends StatelessWidget {
  const MessagesView({super.key});

  @override
  Widget build(BuildContext context) {
    final authenticated = context.watch<AuthController>().isAuthenticated;
    if (!authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.login);
      });
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mensajes')),
      body: const Center(child: Text('Tus conversaciones apareceran aqui.')),
      bottomNavigationBar: const _MessagesNavigationBar(),
    );
  }
}

class _MessagesNavigationBar extends StatelessWidget {
  const _MessagesNavigationBar();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 2,
      onTap: (index) {
        if (index == 0) context.go(AppRoutes.home);
        if (index == 1) context.push(AppRoutes.publishPlant);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          activeIcon: Icon(Icons.add_circle),
          label: 'Publicar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.forum_outlined),
          activeIcon: Icon(Icons.forum),
          label: 'Mensajes',
        ),
      ],
    );
  }
}
