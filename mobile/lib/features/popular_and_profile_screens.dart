import 'package:flutter/material.dart';
import '../../core/networking/api_client.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/incident_card.dart';

class PopularScreen extends StatefulWidget {
  const PopularScreen({super.key});

  @override
  State<PopularScreen> createState() => _PopularScreenState();
}

class _PopularScreenState extends State<PopularScreen> {
  final ApiClient _apiClient = ApiClient();
  List<PostModel> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPopular();
  }

  Future<void> _loadPopular() async {
    setState(() => _loading = true);
    final list = await _apiClient.getPopularPosts();
    setState(() {
      _posts = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Popular esta Semana'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? const Center(
                  child: Text('No hay publicaciones destacadas esta semana todavía.'),
                )
              : RefreshIndicator(
                  onRefresh: _loadPopular,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) => IncidentCard(post: _posts[index]),
                  ),
                ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil Ciudadano'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 46,
              backgroundColor: Color(0xFF002F6C),
              child: Text(
                'RD',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '@ciudadano_rd',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Nivel: Colaborador Confiable',
                style: TextStyle(color: Color(0xFF002F6C), fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),

            // Metrics row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat('Reportes', '14'),
                _buildStat('Confirmaciones', '68'),
                _buildStat('Reputación', '240 pts'),
              ],
            ),
            const SizedBox(height: 32),

            // Options List
            ListTile(
              leading: const Icon(Icons.location_city_outlined),
              title: const Text('Zona habitual: Santo Domingo, D.N.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Normas de la comunidad y Privacidad'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
