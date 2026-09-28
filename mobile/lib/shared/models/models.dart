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
  final String? authorAvatarUrl;
  final String authorReputation;
  final int categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String province;
  final String municipality;
  final String? addressReference;
  final String status;
  final int viewsCount;
  int reactionsCount;
  int confirmationsCount;
  final List<String> images;
  final DateTime createdAt;
  final double? distanceInMeters;
  bool userHasConfirmed;
  String? userReaction;

  PostModel({
    required this.id,
    required this.userId,
    required this.authorUsername,
    this.authorAvatarUrl,
    required this.authorReputation,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.province,
    required this.municipality,
    this.addressReference,
    required this.status,
    required this.viewsCount,
    required this.reactionsCount,
    required this.confirmationsCount,
    required this.images,
    required this.createdAt,
    this.distanceInMeters,
    this.userHasConfirmed = false,
    this.userReaction,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      authorUsername: json['authorUsername'] as String? ?? 'Ciudadano',
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      authorReputation: json['authorReputation']?.toString() ?? 'Ciudadano',
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String? ?? 'Incidencia',
      categoryIcon: json['categoryIcon'] as String? ?? 'alert',
      categoryColor: json['categoryColor'] as String? ?? '#E53935',
      title: json['title'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      province: json['province'] as String,
      municipality: json['municipality'] as String,
      addressReference: json['addressReference'] as String?,
      status: json['status']?.toString() ?? 'Active',
      viewsCount: json['viewsCount'] as int? ?? 0,
      reactionsCount: json['reactionsCount'] as int? ?? 0,
      confirmationsCount: json['confirmationsCount'] as int? ?? 0,
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      distanceInMeters: (json['distanceInMeters'] as num?)?.toDouble(),
      userHasConfirmed: json['userHasConfirmed'] as bool? ?? false,
      userReaction: json['userReaction']?.toString(),
    );
  }
}

class PostMapPinModel {
  final String id;
  final double latitude;
  final double longitude;
  final int categoryId;
  final String categoryName;
  final String categoryColor;
  final String title;
  final String? thumbnailUrl;
  final int confirmationsCount;
  final DateTime createdAt;

  PostMapPinModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.title,
    this.thumbnailUrl,
    required this.confirmationsCount,
    required this.createdAt,
  });

  factory PostMapPinModel.fromJson(Map<String, dynamic> json) {
    return PostMapPinModel(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
      categoryColor: json['categoryColor'] as String? ?? '#E53935',
      title: json['title'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      confirmationsCount: json['confirmationsCount'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class UserModel {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;
  final String? province;
  final String? municipality;
  final int reputationScore;
  final String reputationLevel;
  final int totalPosts;
  final int totalConfirmations;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.province,
    this.municipality,
    required this.reputationScore,
    required this.reputationLevel,
    required this.totalPosts,
    required this.totalConfirmations,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      province: json['province'] as String?,
      municipality: json['municipality'] as String?,
      reputationScore: json['reputationScore'] as int? ?? 100,
      reputationLevel: json['reputationLevel']?.toString() ?? 'Ciudadano',
      totalPosts: json['totalPosts'] as int? ?? 0,
      totalConfirmations: json['totalConfirmations'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
