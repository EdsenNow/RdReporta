import 'dart:io';

class ApiConstants {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS simulator, or custom host
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    } else {
      return 'http://localhost:5000/api';
    }
  }

  static String get hostUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000';
    } else {
      return 'http://localhost:5000';
    }
  }

  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  
  static const String usersMe = '/users/me';
  static const String categories = '/categories';
  
  static const String postsRecent = '/posts/recent';
  static const String postsNearby = '/posts/nearby';
  static const String postsPopular = '/posts/popular';
  static const String postsMap = '/posts/map';
  static const String createPost = '/posts';
  static const String uploadImage = '/uploads/image';
  static const String moderationReport = '/moderation/report';
}
