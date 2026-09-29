import 'package:flutter/material.dart';
import '../../core/networking/api_client.dart';
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
  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mis reportes')),
        body: _loading && _posts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? RequestState(
                    message: _error!, onRetry: () => _load(reset: true))
                : RefreshIndicator(
                    onRefresh: () => _load(reset: true),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        if (_posts.isEmpty)
                          const Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                  'Todavía no has publicado reportes. Tus aportes aparecerán aquí.',
                                  textAlign: TextAlign.center)),
                        ..._posts.map((p) => Column(children: [
                              Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 16, 20, 0),
                                  child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Chip(
                                          label: Text(const {
                                                'Active': 'Activa',
                                                'Resolved': 'Resuelta',
                                                'Hidden':
                                                    'Retirada por moderación',
                                                'Archived': 'Archivada'
                                              }[p.status] ??
                                              p.status)))),
                              IncidentCard(key: ValueKey(p.id), post: p),
                            ])),
                        if (_more)
                          TextButton(
                              onPressed: _loading ? null : () => _load(),
                              child: Text(
                                  _loading ? 'Cargando…' : 'Ver más reportes')),
                      ],
                    )),
      );
}
