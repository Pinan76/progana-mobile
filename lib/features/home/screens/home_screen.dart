import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/screens/login_screen.dart';
import '../../quinielas/screens/lista_quinielas_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.verdeMexicano,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.blanco,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bienvenido',
                            style: TextStyle(
                              color: AppColors.grisMedio,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            user?.email ?? 'Usuario',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.verdeMexicano,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Próximamente',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.verdeMexicano,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ListaQuinielasScreen(),
                  ),
                );
              },
              child: _buildFeatureCard(
                icon: Icons.sports_soccer,
                title: 'Quinielas del Mundial',
                subtitle: 'Ver todas las quinielas disponibles',
                comingSoon: false,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: Icons.leaderboard,
              title: 'Ranking',
              subtitle: 'Compite con miles de usuarios',
              comingSoon: true,
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: Icons.group,
              title: 'Ligas privadas',
              subtitle: 'Crea liga con amigos',
              comingSoon: true,
            ),
            const Spacer(),
            const Center(
              child: Text(
                '🇲🇽⚽ Mundial 2026 ⚽🇲🇽',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.grisMedio,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                AppConstants.appOperadora,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.grisMedio,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    bool comingSoon = false,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.verdeMexicano.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.verdeMexicano),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: comingSoon
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.dorado,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PRONTO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grisOscuro,
                  ),
                ),
              )
            : const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}