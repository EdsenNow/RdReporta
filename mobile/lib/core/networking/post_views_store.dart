import 'dart:async';
import 'package:flutter/widgets.dart';

/// Shared counters for every copy of a report, with one live connection.
class PostViewsStore with WidgetsBindingObserver {
  PostViewsStore(this.connect);

  final Stream<Map<String, dynamic>> Function(List<String>) connect;
  final Map<String, ValueNotifier<int>> _counts = {};
  final Map<String, int> _watchers = {};
  StreamSubscription<Map<String, dynamic>>? _subscription;
  Timer? _reconnect;
  bool _foreground = true;
  int _generation = 0;

  ValueNotifier<int> watch(String id, int initialCount) {
    final counter = _counts.putIfAbsent(id, () => ValueNotifier(initialCount));
    // A stale feed response must not replace a newer live counter.
    scheduleMicrotask(() => update(id, initialCount));
    if (_watchers.isEmpty) {
      WidgetsBinding.instance.addObserver(this);
      _foreground = WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    }
    _watchers[id] = (_watchers[id] ?? 0) + 1;
    _scheduleConnection();
    return counter;
  }

  void unwatch(String id) {
    final count = _watchers[id] ?? 0;
    if (count > 1) {
      _watchers[id] = count - 1;
      return;
    }
    _watchers.remove(id);
    if (_watchers.isEmpty) {
      WidgetsBinding.instance.removeObserver(this);
      _stop();
    } else {
      _scheduleConnection();
    }
  }

  void update(String id, int count) {
    final counter = _counts.putIfAbsent(id, () => ValueNotifier(count));
    if (count > counter.value) counter.value = count;
  }

  void _stop() {
    _generation++;
    _reconnect?.cancel();
    _reconnect = null;
    _subscription?.cancel();
    _subscription = null;
  }

  void _scheduleConnection(
      {Duration delay = const Duration(milliseconds: 250)}) {
    _stop();
    if (!_foreground || _watchers.isEmpty) return;
    _reconnect = Timer(delay, _open);
  }

  void _open() {
    _reconnect = null;
    final generation = _generation;
    _subscription = connect(_watchers.keys.toList()).listen((event) {
      if (generation != _generation) return;
      final id = event['postId'];
      final count = event['viewsCount'];
      if (id is String && count is int && count >= 0) update(id, count);
    }, onError: (Object error) {
      if (generation == _generation) {
        _scheduleConnection(delay: const Duration(seconds: 3));
      }
    }, onDone: () {
      if (generation == _generation) {
        _scheduleConnection(delay: const Duration(seconds: 3));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _scheduleConnection();
    } else {
      _stop();
    }
  }
}
