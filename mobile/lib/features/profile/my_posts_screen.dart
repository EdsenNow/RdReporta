import 'package:flutter/material.dart';
import '../../core/networking/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/incident_card.dart';
import '../../shared/widgets/request_state.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});
  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final _posts = <PostModel>[];
  bool _loading = true;
  bool _more = false;
  int _page = 0;
  String? _error;
  final _deleting = <String>{};

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false, bool isRefresh = false}) async {
    if (!isRefresh && _posts.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }
    try {
      final page = reset ? 1 : _page + 1;
      final posts = await ApiClient().getMyPosts(page: page);
      if (mounted) {
        setState(() {
          if (reset) {
            _posts.clear();
          }
          _posts.addAll(posts);
          _page = page;
          _more = posts.length == 20;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deletePost(PostModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar reporte?'),
        content: Text(
          '“${post.title}” se eliminará de forma permanente. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: context.loveColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting.add(post.id));
    try {
      await ApiClient().deletePost(post.id);
      if (!mounted) return;
      await _load(reset: true, isRefresh: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte eliminado.')),
      );
    } catch (error) {
      if (mounted) {
        final message =
            error is Exception && error.toString().startsWith('Exception: ')
                ? error.toString().replaceFirst('Exception: ', '')
                : ApiClient.errorMessage(error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting.remove(post.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis reportes')),
      body: _loading && _posts.isEmpty
          ? Center(child: CircularProgressIndicator(color: context.loveColor))
          : RefreshIndicator(
              color: context.loveColor,
              backgroundColor: context.surfaceColor,
              displacement: 40.0,
              onRefresh: () => _load(reset: true, isRefresh: true),
              child: _error != null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.55,
                          child: RequestState(
                            message: _error!,
                            onRetry: () => _load(reset: true, isRefresh: true),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: _posts.isEmpty ? 1 : _posts.length + (_more ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_posts.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'Todavía no has publicado reportes. Tus aportes aparecerán aquí.',
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        if (index < _posts.length) {
                          final p = _posts[index];
                          return IncidentCard(
                            key: ValueKey(p.id),
                            post: p,
                            onDelete: () => _deletePost(p),
                            deleting: _deleting.contains(p.id),
                          );
                        }
                        return TextButton(
                          onPressed: _loading ? null : () => _load(),
                          child: Text(
                            _loading ? 'Cargando…' : 'Ver más reportes',
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
