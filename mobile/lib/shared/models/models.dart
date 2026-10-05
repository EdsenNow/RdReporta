class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String iconName;
  final String colorHex;
  final int displayOrder;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.iconName,
    required this.colorHex,
    required this.displayOrder,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      iconName: json['iconName'] as String? ?? 'alert-circle',
      colorHex: json['colorHex'] as String? ?? '#E53935',
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }
}

class PostModel {
  final String id;
  final String userId;
  final String authorUsername;
  final String authorDisplayName;
  final String? authorAvatarUrl;
  final String authorReputation;
  final bool authorIsVerified;
  final int categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final String title;
  final String description;
  final double? latitude;
  final double? longitude;
  final String province;
  final String municipality;
  final String? neighborhood;
  final String? addressReference;
  final String status;
  int viewsCount;
  int reactionsCount;
  final List<String> images;
  final String? videoUrl;
  final DateTime createdAt;
  final double? distanceInMeters;
  String? userReaction;
  Map<String, int> reactionCounts;

  PostModel({
    required this.id,
    required this.userId,
    required this.authorUsername,
    required this.authorDisplayName,
    this.authorAvatarUrl,
    required this.authorReputation,
    this.authorIsVerified = false,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.title,
    required this.description,
    this.latitude,
    this.longitude,
    required this.province,
    required this.municipality,
    this.neighborhood,
    this.addressReference,
    required this.status,
    required this.viewsCount,
    required this.reactionsCount,
    required this.images,
    this.videoUrl,
    required this.createdAt,
    this.distanceInMeters,
    this.userReaction,
    Map<String, int>? reactionCounts,
  }) : reactionCounts = reactionCounts != null
            ? Map<String, int>.from(reactionCounts)
            : <String, int>{};

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      authorUsername: json['authorUsername'] as String? ?? 'Ciudadano',
      authorDisplayName: json['authorDisplayName'] as String? ??
          json['authorUsername'] as String? ??
          'Ciudadano',
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      authorReputation: json['authorReputation']?.toString() ?? 'Ciudadano',
      authorIsVerified: json['authorIsVerified'] as bool? ?? false,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String? ?? 'Incidencia',
      categoryIcon: json['categoryIcon'] as String? ?? 'alert',
      categoryColor: json['categoryColor'] as String? ?? '#E53935',
      title: json['title'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      province: json['province'] as String,
      municipality: json['municipality'] as String,
      neighborhood: json['neighborhood'] as String?,
      addressReference: json['addressReference'] as String?,
      status: json['status']?.toString() ?? 'Active',
      viewsCount: json['viewsCount'] as int? ?? 0,
      reactionsCount: json['reactionsCount'] as int? ?? 0,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      videoUrl: json['videoUrl'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      distanceInMeters: (json['distanceInMeters'] as num?)?.toDouble(),
      userReaction: json['userReaction']?.toString(),
      reactionCounts: (json['reactionCounts'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          ) ??
          {},
    );
  }
}

class PostMapPinModel {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final int categoryId;
  final String categoryName;
  final String categoryColor;
  final String title;
  final String? thumbnailUrl;
  final List<String> images;
  final String? videoUrl;
  final String province;
  final String municipality;
  final String? neighborhood;
  final String? addressReference;
  final DateTime createdAt;

  PostMapPinModel({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.title,
    this.thumbnailUrl,
    this.images = const [],
    this.videoUrl,
    required this.province,
    required this.municipality,
    this.neighborhood,
    this.addressReference,
    required this.createdAt,
  });

  factory PostMapPinModel.fromJson(Map<String, dynamic> json) {
    final imgs = (json['images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final thumb = json['thumbnailUrl'] as String?;
    if (imgs.isEmpty && thumb != null && thumb.trim().isNotEmpty) {
      imgs.add(thumb);
    }

    return PostMapPinModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
      categoryColor: json['categoryColor'] as String? ?? '#E53935',
      title: json['title'] as String,
      thumbnailUrl: thumb,
      images: imgs,
      videoUrl: json['videoUrl'] as String?,
      province: json['province'] as String? ?? '',
      municipality: json['municipality'] as String? ?? '',
      neighborhood: json['neighborhood'] as String?,
      addressReference: json['addressReference'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class UserModel {
  final String id;
  final String username;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String? province;
  final String? municipality;
  final int reputationScore;
  final String reputationLevel;
  final int totalPosts;
  final DateTime createdAt;
  final DateTime? usernameCanChangeAt;
  final bool isVerified;
  int followersCount;
  final int followingCount;
  bool isFollowing;

  UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.province,
    this.municipality,
    required this.reputationScore,
    required this.reputationLevel,
    required this.totalPosts,
    required this.createdAt,
    this.usernameCanChangeAt,
    required this.isVerified,
    required this.followersCount,
    required this.followingCount,
    required this.isFollowing,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String? ?? json['username'] as String,
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      province: json['province'] as String?,
      municipality: json['municipality'] as String?,
      reputationScore: json['reputationScore'] as int? ?? 100,
      reputationLevel: json['reputationLevel']?.toString() ?? 'Ciudadano',
      totalPosts: json['totalPosts'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['memberSince']?.toString() ?? '') ??
          DateTime.now(),
      usernameCanChangeAt:
          DateTime.tryParse(json['usernameCanChangeAt']?.toString() ?? ''),
      isVerified: json['isVerified'] as bool? ?? false,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      isFollowing: json['isFollowing'] as bool? ?? false,
    );
  }
}

class NotificationModel {
  final String id;
  final String actorUserId;
  final String? postId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        actorUserId = json['actorUserId'] as String,
        postId = json['postId'] as String?,
        message = json['message'] as String,
        isRead = json['isRead'] as bool? ?? false,
        createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now();
}
