class UserRole {
  static const String athlete = 'athlete';
  static const String recruiter = 'recruiter';
}

class UserModel {
  final String id;
  final String name;
  final String? email;
  final String? role;
  final String? sport;
  final String? position;
  final String? location;
  final String? profileImage;
  final String? bio;
  final List<String> skills;
  final Map<String, dynamic> stats;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final List<String> followers;
  final List<String> following;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.role,
    this.sport,
    this.position,
    this.location,
    this.profileImage,
    this.bio = '',
    this.skills = const [],
    this.stats = const {},
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.followers = const [],
    this.following = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'sport': sport,
        'position': position,
        'location': location,
        'bio': bio,
        'skills': skills,
        'stats': stats,
        'postsCount': postsCount,
        'followersCount': followersCount,
        'followingCount': followingCount,
        'followers': followers,
        'following': following,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      sport: json['sport'] as String?,
      position: json['position'] as String?,
      location: json['location'] as String?,
      profileImage: json['profileImage'] as String?,
      bio: json['bio'] as String? ?? '',
      skills: List<String>.from(json['skills'] ?? []),
      stats: Map<String, dynamic>.from(json['stats'] ?? {}),
      postsCount: json['postsCount'] as int? ?? 0,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
    );
  }
}

// class UserModel {
//   final String id;
//   final String name;
//   final String email;
//   final String role;
//   final String? sport;
//   final String? position;
//   // final String? team;
//   final String? location;
//   final String? profileImage;
//   final String bio;
//   final List<String> skills;
//   final Map<String, dynamic> stats;

//   UserModel({
//     required this.id,
//     required this.name,
//     required this.email,
//     required this.role,
//     this.sport,
//     this.position,
//     // this.team,
//     this.location,
//     this.profileImage,
//     this.bio = '',
//     this.skills = const [],
//     this.stats = const {},
//   });
//   Map<String, dynamic> toJson() => {
//         'id': id,
//         'name': name,
//         'email': email,
//         'role': role,
//         'sport': sport,
//         'position': position,
//         // 'team': team,
//         'location': location,
//         // 'profileImage': profileImage,
//         'bio': bio,
//         'skills': skills,
//         'stats': stats,
//       };

//   factory UserModel.fromJson(Map<String, dynamic> json) {
//     return UserModel(
//       id: json['id'] as String,
//       name: json['name'] as String,
//       email: json['email'] as String,
//       role: json['role'] as String,
//       sport: json['sport'] as String?,
//       position: json['position'] as String?,
//       location: json['location'] as String?,
//       profileImage: json['profileImage'] as String?,
//       bio: json['bio'] as String,
//       skills: List<String>.from(json['skills'] ?? []),
//       stats: Map<String, dynamic>.from(json['stats'] ?? {}),
//     );
//   }

// }
