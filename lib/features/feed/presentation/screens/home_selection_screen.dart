import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeSelectionScreen extends StatelessWidget {
  const HomeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('¿Qué estás buscando?'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _SelectionCard(
                title: 'Busco compañero',
                subtitle: 'Tengo una habitación libre en mi piso',
                icon: Icons.meeting_room,
                color: Colors.teal.shade100,
                // Usamos context.push y pasamos el valor 'true' al extra
                onTap: () => context.push('/feed', extra: true),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _SelectionCard(
                title: 'Busco piso',
                subtitle: 'Necesito una habitación o apartamento',
                icon: Icons.search,
                color: Colors.blue.shade100,
                // Pasamos el valor 'false' al extra
                onTap: () => context.push('/feed', extra: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: theme.colorScheme.onSurface),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}