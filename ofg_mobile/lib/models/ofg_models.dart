// lib/models/ofg_models.dart

class OfgUser {
  OfgUser({
    required this.id,
    required this.name,
    required this.email,
    required this.handle,
    this.bio = '',
    this.subscription = 'Free',
  });

  final String id;
  final String name;
  final String email;
  final String handle;
  final String bio;
  final String subscription;

  factory OfgUser.fromJson(Map<String, dynamic> json) {
    return OfgUser(
      id: json['id'].toString(),
      name: (json['name'] ?? 'OFG User').toString(),
      email: (json['email'] ?? '').toString(),
      handle: (json['handle'] ?? '@ofguser').toString(),
      bio: (json['bio'] ?? '').toString(),
      subscription: (json['subscription'] ?? 'Free').toString(),
    );
  }
}

class OfgVideo {
  OfgVideo({
    required this.id,
    required this.title,
    required this.creator,
    required this.creatorId,
    required this.category,
    required this.duration,
    required this.meta,
    required this.description,
    required this.label,
    required this.views,
    required this.likes,
    required this.comments,
    required this.isShort,
    required this.isLive,
    required this.progress,
    required this.liked,
    required this.saved,
    required this.following,
    required this.mediaUrl, 
  });

  final String id;
  final String title;
  final String creator;
  final String creatorId;
  final String category;
  final String duration;
  final String meta;
  final String description;
  final String label;
  final int views;
  final int likes;
  final int comments;
  final bool isShort;
  final bool isLive;
  final double progress;
  final bool liked;
  final bool saved;
  final bool following;
  final String mediaUrl;

  factory OfgVideo.fromJson(Map<String, dynamic> json) {
    return OfgVideo(
      id: json['id'].toString(),
      title: (json['title'] ?? '').toString(),
      creator: (json['creator'] ?? '').toString(),
      creatorId: (json['creatorId'] ?? '').toString(),
      category: (json['category'] ?? 'sermons').toString(),
      duration: (json['duration'] ?? '12:04').toString(),
      meta: (json['meta'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      label: (json['label'] ?? 'video 16:9').toString(),
      views: _asInt(json['views']),
      likes: _asInt(json['likes']),
      comments: _asInt(json['comments']),
      isShort: json['isShort'] == true,
      isLive: json['isLive'] == true,
      progress: _asDouble(json['progress']),
      liked: json['liked'] == true,
      saved: json['saved'] == true,
      following: json['following'] == true,
      mediaUrl: (json['mediaUrl'] ?? '').toString(),
    );
  }
}

class OfgComment {
  OfgComment({
    required this.id,
    required this.user,
    required this.content,
    required this.when,
  });

  final String id;
  final String user;
  final String content;
  final String when;

  factory OfgComment.fromJson(Map<String, dynamic> json) {
    return OfgComment(
      id: json['id'].toString(),
      user: (json['user'] ?? 'OFG User').toString(),
      content: (json['content'] ?? '').toString(),
      when: (json['when'] ?? 'now').toString(),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}