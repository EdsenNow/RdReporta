import 'package:flutter/material.dart';
import '../core/networking/api_client.dart';
import '../core/theme/app_theme.dart';
import '../shared/models/models.dart';
import 'feed/post_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = ApiClient();
  List<NotificationModel> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool isRefresh = false, bool more = false}) async {
    if (_loadingMore || (more && _loading)) return;
    if (more) setState(() => _loadingMore = true);
    if (!isRefresh && _items.isEmpty) {
      setState(() => _loading = true);
    }
    final page = more ? _page + 1 : 1;
    try {
      final items = await _api.getNotifications(page: page);
      if (mounted) {
        setState(() {
          _items = more
              ? [
                  ..._items,
                  ...items
                      .where((item) => !_items.any((old) => old.id == item.id))
                ]
              : items;
          _page = page;
          _hasMore = items.length == 50;
          _error = null;
          _loading = false;
        });
        // Acknowledge only the batch actually loaded; newer arrivals stay unread.
        try {
          await _api.markNotificationsRead(items
              .where((item) => !item.isRead)
              .map((item) => item.id)
              .toList());
        } catch (_) {
          if (mounted) {
            setState(() => _error =
                'No se pudieron marcar como leídas. Desliza para reintentar.');
          }
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = ApiClient.errorMessage(error);
        });
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.loveColor))
          : RefreshIndicator(
              color: context.loveColor,
              backgroundColor: context.surfaceColor,
              displacement: 40.0,
              onRefresh: () => _load(isRefresh: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Text(_error!,
                            style: TextStyle(color: context.subtleColor)),
                        TextButton(
                            onPressed: () => _load(isRefresh: true),
                            child: const Text('Reintentar')),
                      ]),
                    ),
                  if (_items.isEmpty && _error == null)
                    Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 48,
                            color: context.mutedColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Todavía no tienes notificaciones.',
                            style: TextStyle(color: context.subtleColor),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._items.map(
                      (n) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: n.isRead
                                ? context.borderColor
                                : context.loveColor,
                            width: 2,
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.campaign_rounded,
                            color: context.loveColor,
                          ),
                          title: Text(n.message),
                          subtitle: Text(
                            '${n.createdAt.toLocal().day}/${n.createdAt.toLocal().month}/${n.createdAt.toLocal().year}',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: n.postId == null
                              ? null
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PostDetailScreen(
                                        postId: n.postId!,
                                      ),
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  if (_hasMore)
                    TextButton(
                      onPressed: _loadingMore ? null : () => _load(more: true),
                      child:
                          Text(_loadingMore ? 'Cargando…' : 'Ver anteriores'),
                    ),
                ],
              ),
            ),
    );
  }
}
