import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bienvenue',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Veuillez sélectionner votre espace pour vous connecter à l\'application.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 1. ESPACE EMPLOYÉ
                  _buildRoleCard(
                    context: context,
                    title: 'Espace Employé',
                    subtitle: 'Faire une demande de congé et consulter vos demandes',
                    icon: Icons.person_outline_rounded,
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.pushNamed(context, '/login', arguments: '/employee');
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. ESPACE MANAGER
                  _buildRoleCard(
                    context: context,
                    title: 'Espace Manager',
                    subtitle: 'Valider ou refuser les demandes de votre équipe',
                    icon: Icons.supervisor_account_outlined,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pushNamed(context, '/login', arguments: '/manager');
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. ESPACE RH
                  _buildRoleCard(
                    context: context,
                    title: 'Espace RH',
                    subtitle: 'Gestion globale des congés et des soldes',
                    icon: Icons.admin_panel_settings_outlined,
                    color: Colors.deepOrange,
                    onTap: () {
                      Navigator.pushNamed(context, '/login', arguments: '/rh');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}