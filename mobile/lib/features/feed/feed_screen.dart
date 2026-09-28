import 'package:flutter/material.dart';
import '../../core/networking/api_client.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/incident_card.dart';

import '../../core/theme/app_theme.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RDReporta',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: theme.colorScheme.primary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 2.5,
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
              height: 50,
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
                      color: theme.colorScheme.primary,
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
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feed_outlined, size: 54, color: context.mutedColor),
            const SizedBox(height: 12),
            Text(
              'No hay reportes en esta sección',
              style: TextStyle(
                fontSize: 15,
                color: context.subtleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: _loadInitialData,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: posts.length,
        itemBuilder: (context, index) => IncidentCard(post: posts[index]),
      ),
    );
  }
}
