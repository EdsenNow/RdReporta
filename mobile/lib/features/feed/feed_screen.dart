import 'package:flutter/material.dart';
import '../../core/networking/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/incident_card.dart';
import '../posts/create_post_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _apiClient = ApiClient();
  
  List<PostModel> _recentPosts = [];
  List<PostModel> _nearbyPosts = [];
  List<CategoryModel> _categories = [];
  int? _selectedCategory;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _apiClient.getRecentPosts(categoryId: _selectedCategory),
      _apiClient.getNearbyPosts(latitude: 18.4861, longitude: -69.9312, categoryId: _selectedCategory),
      _apiClient.getCategories(),
    ]);

    if (mounted) {
      setState(() {
        _recentPosts = results[0] as List<PostModel>;
        _nearbyPosts = results[1] as List<PostModel>;
        _categories = results[2] as List<CategoryModel>;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RDReporta',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: context.loveColor,
          ),
        ),
        actions: [
          // FinanzApp style rounded squarish Theme Switcher button
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.loveColor.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: context.loveColor,
                size: 20,
              ),
              tooltip: isDark ? 'Cambiar a Rosé Pine Dawn (Claro)' : 'Cambiar a Rosé Pine (Oscuro)',
              onPressed: () {
                AppTheme.toggleTheme();
              },
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 2.5,
          indicatorColor: context.loveColor,
          labelColor: context.loveColor,
          unselectedLabelColor: context.mutedColor,
          tabs: const [
            Tab(text: 'Para Ti'),
            Tab(text: 'Cerca de Mí'),
            Tab(text: 'Recientes'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Category chips filter
          if (_categories.isNotEmpty)
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isAll = _selectedCategory == null;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Todas'),
                        selected: isAll,
                        showCheckmark: false,
                        backgroundColor: context.overlayColor,
                        selectedColor: context.loveColor.withValues(alpha: 0.2),
                        side: BorderSide(
                          color: isAll ? context.loveColor : context.borderColor,
                        ),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isAll ? FontWeight.bold : FontWeight.normal,
                          color: isAll ? context.loveColor : context.textPrimaryColor,
                        ),
                        onSelected: (_) {
                          setState(() => _selectedCategory = null);
                          _loadInitialData();
                        },
                      ),
                    );
                  }
                  final cat = _categories[index - 1];
                  final isSelected = _selectedCategory == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat.name),
                      selected: isSelected,
                      showCheckmark: false,
                      backgroundColor: context.overlayColor,
                      selectedColor: context.loveColor.withValues(alpha: 0.2),
                      side: BorderSide(
                        color: isSelected ? context.loveColor : context.borderColor,
                      ),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? context.loveColor : context.textPrimaryColor,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedCategory = isSelected ? null : cat.id);
                        _loadInitialData();
                      },
                    ),
                  );
                },
              ),
            ),

          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: context.loveColor,
                      strokeWidth: 2.5,
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPostList(_recentPosts),
                      _buildPostList(_nearbyPosts),
                      _buildPostList(_recentPosts),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostList(List<PostModel> posts) {
    return RefreshIndicator(
      color: context.loveColor,
      onRefresh: _loadInitialData,
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 90),
        children: [
          // 1. FinanzApp style Metric Summary Cards
          _buildSummaryCards(),

          // 2. Section divider & count
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: Row(
              children: [
                Text(
                  'REPORTES CIUDADANOS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: context.subtleColor,
                  ),
                ),
                const Spacer(),
                if (posts.isNotEmpty)
                  Text(
                    '${posts.length} incidencias',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.mutedColor,
                    ),
                  ),
              ],
            ),
          ),

          // 3. Post items or Empty State
          if (posts.isEmpty)
            _buildEmptyStateCard()
          else
            ...posts.map((post) => IncidentCard(post: post)),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalPosts = _recentPosts.length;
    final totalConfirmations = _recentPosts.fold<int>(0, (sum, p) => sum + p.confirmationsCount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Card 1: INCIDENCIAS ACTIVAS (FinanzApp Ingresos style)
          _buildFinanzCard(
            icon: Icons.arrow_upward_rounded,
            iconColor: context.successColor,
            header: 'INCIDENCIAS REPORTADAS',
            value: '$totalPosts Activas',
            subtext: totalPosts > 0 ? 'Actualizado en tiempo real' : 'Comunidad lista para monitorear',
          ),
          const SizedBox(height: 12),

          // Card 2: VALIDACIONES CIUDADANAS (FinanzApp Gastos style)
          _buildFinanzCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: context.loveColor,
            header: 'CONFIRMACIONES DE VECINOS',
            value: '$totalConfirmations Validadas',
            subtext: 'Verificación comunitaria sin intermediarios',
          ),
          const SizedBox(height: 12),

          // Card 3: RADAR CIUDADANO (FinanzApp Balance style)
          _buildFinanzCard(
            icon: Icons.balance_rounded,
            iconColor: context.irisColor,
            header: 'COBERTURA TERRITORIAL',
            value: 'República Dominicana',
            subtext: 'Monitoreo geolocalizado en todo el país',
          ),
        ],
      ),
    );
  }

  Widget _buildFinanzCard({
    required IconData icon,
    required Color iconColor,
    required String header,
    required String value,
    required String subtext,
  }) {
    final isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0x1AFFFFFF) : context.borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(
                header,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: context.overlayColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              subtext,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: context.subtleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.isDarkMode ? const Color(0x1AFFFFFF) : context.borderColor,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: context.overlayColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 28,
              color: context.subtleColor,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Zona sin incidencias registradas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay reportes para esta categoría en este momento. Si observas un incidente en tu sector, puedes reportarlo con fotos y coordenadas GPS.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: context.subtleColor,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreatePostScreen()),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Crear Nuevo Reporte'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.loveColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
