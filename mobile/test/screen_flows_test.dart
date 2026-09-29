import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rdreporta/core/networking/api_client.dart';
import 'package:rdreporta/core/theme/app_theme.dart';
import 'package:rdreporta/features/feed/feed_screen.dart';
import 'package:rdreporta/features/feed/post_detail_screen.dart';
import 'package:rdreporta/features/home/home_screen.dart';
import 'package:rdreporta/features/map/map_screen.dart';
import 'package:rdreporta/features/popular_and_profile_screens.dart';
import 'package:rdreporta/features/posts/create_post_screen.dart';
import 'api_client_test.dart' show FakeAdapter, jsonResponse;

void main() {
  late Map<String, dynamic> post;
  var confirmations = 0;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(
        {'jwt_token': 'test-token', 'refresh_token': 'test-refresh'});
    confirmations = 0;
    post = {
      'id': 'post-1',
      'userId': 'author-1',
      'authorUsername': 'vecino_de_san_pedro_de_macoris',
      'authorReputation': 'ColaboradorConfiable',
      'categoryId': 1,
      'categoryName': 'Servicios Públicos y Alumbrado',
      'categoryIcon': 'road',
      'categoryColor': '#31748F',
      'title': 'Luminaria averiada frente al centro comunitario',
      'description': 'La calle permanece sin iluminación durante la noche.',
      'latitude': 18.48,
      'longitude': -69.93,
      'province': 'San Pedro de Macorís',
      'municipality': 'San Pedro de Macorís',
      'status': 'Active',
      'viewsCount': 12345,
      'reactionsCount': 1234,
      'confirmationsCount': 1234,
      'images': <String>[],
      'createdAt': '2026-09-28T12:00:00Z',
      'userHasConfirmed': false,
    };
    ApiClient.useForTesting(ApiClient.forTesting(FakeAdapter((options) {
      final Object data;
      if (options.path == '/categories') {
        data = [
          {
            'id': 1,
            'name': post['categoryName'],
            'slug': 'servicios-publicos',
            'iconName': 'road',
            'colorHex': '#31748F',
            'displayOrder': 1
          }
        ];
      } else if (options.path == '/posts/stats') {
        data = {
          'activePosts': 12345,
          'resolvedPosts': 9876,
          'totalConfirmations': 123456
        };
      } else if (options.path == '/posts/map') {
        data = [post];
      } else if (options.path == '/users/me') {
        data = {
          'id': 'viewer-1',
          'username': 'ciudadano_de_santo_domingo',
          'email': 'ciudadano@example.test',
          'province': 'Santo Domingo',
          'municipality': 'Santo Domingo Este',
          'reputationScore': 12345,
          'reputationLevel': 'ColaboradorConfiable',
          'totalPosts': 1234,
          'totalConfirmationsReceived': 12345,
          'memberSince': '2025-01-01T00:00:00Z'
        };
      } else if (options.path == '/posts/post-1') {
        data = post;
      } else if (options.path.endsWith('/confirm')) {
        confirmations++;
        post['userHasConfirmed'] = !(post['userHasConfirmed'] as bool);
        data = post['userHasConfirmed'];
      } else {
        data = {
          'items': [post],
          'totalCount': 1
        };
      }
      return jsonResponse(200, {'success': true, 'data': data});
    })));
  });
  tearDown(() => ApiClient.useForTesting(null));

  Future<void> render(WidgetTester tester, Widget screen,
      {double width = 360}) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester
        .pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: screen));
    await tester.pumpAndSettle();
  }

  for (final entry in <String, Widget>{
    'feed': const FeedScreen(),
    'radar': const MapScreen(),
    'popular': const PopularScreen(),
    'profile': const ProfileScreen(),
    'create': const CreatePostScreen(),
    'detail': const PostDetailScreen(postId: 'post-1'),
    'home': const HomeScreen(),
  }.entries) {
    testWidgets(
        '${entry.key} accommodates long labels and large counts on a phone',
        (tester) async {
      await render(tester, entry.value);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('confirmation becomes available again after a successful request',
      (tester) async {
    await render(tester, const PostDetailScreen(postId: 'post-1'), width: 800);
    await tester.tap(
        find.widgetWithText(ElevatedButton, 'Confirmar Incidencia (1234)'));
    await tester.pumpAndSettle();
    expect(confirmations, 1);
    await tester
        .tap(find.widgetWithText(ElevatedButton, 'Confirmado por ti (1235)'));
    await tester.pumpAndSettle();
    expect(confirmations, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('guest publishing opens a sign-in invitation', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await render(tester, const HomeScreen(), width: 800);
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Participa en tu comunidad'), findsOneWidget);
    expect(find.byType(CreatePostScreen), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
