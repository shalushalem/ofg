// lib/models/ofg_models.dart
// OFG Connects – all shared model classes

import 'dart:convert';

// ---------------------------------------------------------------------------
// Helper functions
// ---------------------------------------------------------------------------

int _asInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double _asDouble(dynamic v, [double fallback = 0.0]) {
  if (v == null) return fallback;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

bool _asBool(dynamic v, [bool fallback = false]) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }
  return fallback;
}

String _asStr(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  return v.toString();
}

// ---------------------------------------------------------------------------
// OfgUser
// ---------------------------------------------------------------------------

class OfgUser {
  final String id;
  final String name;
  final String email;
  final String handle;
  final String bio;
  final String avatarUrl;
  final String subscription;
  final bool isVerified;
  final bool isAdmin;

  const OfgUser({
    required this.id,
    required this.name,
    required this.email,
    required this.handle,
    required this.bio,
    required this.avatarUrl,
    required this.subscription,
    required this.isVerified,
    required this.isAdmin,
  });

  factory OfgUser.fromJson(Map<String, dynamic> json) {
    // API may wrap the user in a 'user' key
    final m = (json['user'] is Map<String, dynamic>)
        ? json['user'] as Map<String, dynamic>
        : json;
    return OfgUser(
      id: _asStr(m['id'] ?? m['_id']),
      name: _asStr(m['name']),
      email: _asStr(m['email']),
      handle: _asStr(m['handle']),
      bio: _asStr(m['bio']),
      avatarUrl: _asStr(m['avatarUrl'] ?? m['avatar_url'] ?? m['avatar']),
      subscription: _asStr(m['subscription'] ?? m['subscriptionTier'] ?? 'free'),
      isVerified: _asBool(m['isVerified'] ?? m['verified']),
      isAdmin: _asBool(m['isAdmin'] ?? m['admin']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'handle': handle,
        'bio': bio,
        'avatarUrl': avatarUrl,
        'subscription': subscription,
        'isVerified': isVerified,
        'isAdmin': isAdmin,
      };

  String toJsonString() => jsonEncode(toJson());

  OfgUser copyWith({
    String? id,
    String? name,
    String? email,
    String? handle,
    String? bio,
    String? avatarUrl,
    String? subscription,
    bool? isVerified,
    bool? isAdmin,
  }) {
    return OfgUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      handle: handle ?? this.handle,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      subscription: subscription ?? this.subscription,
      isVerified: isVerified ?? this.isVerified,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  @override
  String toString() => 'OfgUser(id: $id, name: $name, email: $email)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is OfgUser && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

// ---------------------------------------------------------------------------
// OfgVideo
// ---------------------------------------------------------------------------

class OfgVideo {
  final String id;
  final String title;
  final String description;
  final String creator;
  final String creatorId;
  final String creatorAvatar;
  final String category;
  final String duration;
  final String meta;
  final String label;
  final String mediaUrl;
  final String thumbnailUrl;
  final String createdAt;
  final int views;
  final int likes;
  final int comments;
  final int shares;
  final bool isShort;
  final bool isLive;
  final bool isFeatured;
  final bool liked;
  final bool saved;
  final bool following;
  final bool creatorVerified;
  final double progress;

  const OfgVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.creator,
    required this.creatorId,
    required this.creatorAvatar,
    required this.category,
    required this.duration,
    required this.meta,
    required this.label,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.createdAt,
    required this.views,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.isShort,
    required this.isLive,
    required this.isFeatured,
    required this.liked,
    required this.saved,
    required this.following,
    required this.creatorVerified,
    required this.progress,
  });

  factory OfgVideo.fromJson(Map<String, dynamic> json) {
    // Resolve creator info – may be nested or flat
    final creatorObj = json['creator'];
    String creatorName;
    String creatorId;
    String creatorAvatar;
    bool creatorVerified;

    if (creatorObj is Map<String, dynamic>) {
      creatorName = _asStr(creatorObj['name']);
      creatorId = _asStr(creatorObj['id'] ?? creatorObj['_id']);
      creatorAvatar = _asStr(
          creatorObj['avatarUrl'] ?? creatorObj['avatar_url'] ?? creatorObj['avatar']);
      creatorVerified = _asBool(creatorObj['isVerified'] ?? creatorObj['verified']);
    } else {
      creatorName = _asStr(creatorObj ?? json['creatorName'] ?? json['creator_name']);
      creatorId = _asStr(json['creatorId'] ?? json['creator_id'] ?? json['userId']);
      creatorAvatar = _asStr(
          json['creatorAvatar'] ?? json['creator_avatar'] ?? json['creatorAvatarUrl']);
      creatorVerified = _asBool(json['creatorVerified'] ?? json['creator_verified']);
    }

    // Build human-readable meta string (e.g. "12K views · 3 hrs ago")
    final rawViews = _asInt(json['views'] ?? json['viewCount'] ?? json['view_count']);
    final rawCreatedAt = _asStr(json['createdAt'] ?? json['created_at']);
    final metaStr = _asStr(json['meta'],
        '${_formatCount(rawViews)} views · ${_timeAgo(rawCreatedAt)}');

    return OfgVideo(
      id: _asStr(json['id'] ?? json['_id']),
      title: _asStr(json['title']),
      description: _asStr(json['description'] ?? json['desc']),
      creator: creatorName,
      creatorId: creatorId,
      creatorAvatar: creatorAvatar,
      category: _asStr(json['category']),
      duration: _asStr(json['duration']),
      meta: metaStr,
      label: _asStr(json['label']),
      mediaUrl: _asStr(json['mediaUrl'] ?? json['media_url'] ?? json['url']),
      thumbnailUrl: _asStr(
          json['thumbnailUrl'] ?? json['thumbnail_url'] ?? json['thumbnail']),
      createdAt: rawCreatedAt,
      views: rawViews,
      likes: _asInt(json['likes'] ?? json['likeCount'] ?? json['like_count']),
      comments:
          _asInt(json['comments'] ?? json['commentCount'] ?? json['comment_count']),
      shares: _asInt(json['shares'] ?? json['shareCount'] ?? json['share_count']),
      isShort: _asBool(json['isShort'] ?? json['is_short'] ?? json['short']),
      isLive: _asBool(json['isLive'] ?? json['is_live'] ?? json['live']),
      isFeatured:
          _asBool(json['isFeatured'] ?? json['is_featured'] ?? json['featured']),
      liked: _asBool(json['liked'] ?? json['isLiked'] ?? json['is_liked']),
      saved: _asBool(json['saved'] ?? json['isSaved'] ?? json['is_saved']),
      following:
          _asBool(json['following'] ?? json['isFollowing'] ?? json['is_following']),
      creatorVerified: creatorVerified,
      progress: _asDouble(json['progress'] ?? json['watchProgress']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'creator': creator,
        'creatorId': creatorId,
        'creatorAvatar': creatorAvatar,
        'category': category,
        'duration': duration,
        'meta': meta,
        'label': label,
        'mediaUrl': mediaUrl,
        'thumbnailUrl': thumbnailUrl,
        'createdAt': createdAt,
        'views': views,
        'likes': likes,
        'comments': comments,
        'shares': shares,
        'isShort': isShort,
        'isLive': isLive,
        'isFeatured': isFeatured,
        'liked': liked,
        'saved': saved,
        'following': following,
        'creatorVerified': creatorVerified,
        'progress': progress,
      };

  OfgVideo copyWith({
    String? id,
    String? title,
    String? description,
    String? creator,
    String? creatorId,
    String? creatorAvatar,
    String? category,
    String? duration,
    String? meta,
    String? label,
    String? mediaUrl,
    String? thumbnailUrl,
    String? createdAt,
    int? views,
    int? likes,
    int? comments,
    int? shares,
    bool? isShort,
    bool? isLive,
    bool? isFeatured,
    bool? liked,
    bool? saved,
    bool? following,
    bool? creatorVerified,
    double? progress,
  }) {
    return OfgVideo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      creator: creator ?? this.creator,
      creatorId: creatorId ?? this.creatorId,
      creatorAvatar: creatorAvatar ?? this.creatorAvatar,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      meta: meta ?? this.meta,
      label: label ?? this.label,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      isShort: isShort ?? this.isShort,
      isLive: isLive ?? this.isLive,
      isFeatured: isFeatured ?? this.isFeatured,
      liked: liked ?? this.liked,
      saved: saved ?? this.saved,
      following: following ?? this.following,
      creatorVerified: creatorVerified ?? this.creatorVerified,
      progress: progress ?? this.progress,
    );
  }

  @override
  String toString() => 'OfgVideo(id: $id, title: $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is OfgVideo && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

// ---------------------------------------------------------------------------
// OfgComment
// ---------------------------------------------------------------------------

class OfgComment {
  final String id;
  final String user;
  final String userHandle;
  final String userAvatar;
  final String content;
  final String when;
  final int likeCount;
  final bool liked;

  const OfgComment({
    required this.id,
    required this.user,
    required this.userHandle,
    required this.userAvatar,
    required this.content,
    required this.when,
    required this.likeCount,
    required this.liked,
  });

  factory OfgComment.fromJson(Map<String, dynamic> json) {
    // Author info may be nested
    final authorObj = json['author'] ?? json['user'];
    String userName;
    String userHandle;
    String userAvatar;

    if (authorObj is Map<String, dynamic>) {
      userName = _asStr(authorObj['name']);
      userHandle = _asStr(authorObj['handle']);
      userAvatar = _asStr(
          authorObj['avatarUrl'] ?? authorObj['avatar_url'] ?? authorObj['avatar']);
    } else {
      userName = _asStr(authorObj ?? json['userName'] ?? json['user_name']);
      userHandle = _asStr(json['userHandle'] ?? json['user_handle'] ?? json['handle']);
      userAvatar = _asStr(
          json['userAvatar'] ?? json['user_avatar'] ?? json['avatarUrl']);
    }

    final rawCreatedAt = _asStr(json['createdAt'] ?? json['created_at']);

    return OfgComment(
      id: _asStr(json['id'] ?? json['_id']),
      user: userName,
      userHandle: userHandle,
      userAvatar: userAvatar,
      content: _asStr(json['content'] ?? json['text'] ?? json['body']),
      when: _asStr(json['when'], _timeAgo(rawCreatedAt)),
      likeCount:
          _asInt(json['likeCount'] ?? json['likes'] ?? json['like_count']),
      liked: _asBool(json['liked'] ?? json['isLiked']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user': user,
        'userHandle': userHandle,
        'userAvatar': userAvatar,
        'content': content,
        'when': when,
        'likeCount': likeCount,
        'liked': liked,
      };

  @override
  String toString() => 'OfgComment(id: $id, user: $user)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is OfgComment && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

// ---------------------------------------------------------------------------
// OfgNotification
// ---------------------------------------------------------------------------

class OfgNotification {
  final String id;
  final String type;
  final String message;
  final String createdAt;
  final String? videoId;
  final String? fromUserId;
  final String? fromUserName;
  final String? fromUserAvatar;
  final bool isRead;

  const OfgNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    this.videoId,
    this.fromUserId,
    this.fromUserName,
    this.fromUserAvatar,
    required this.isRead,
  });

  factory OfgNotification.fromJson(Map<String, dynamic> json) {
    final fromObj = json['from'] ?? json['fromUser'];
    String? fromUserId;
    String? fromUserName;
    String? fromUserAvatar;

    if (fromObj is Map<String, dynamic>) {
      fromUserId = _asStr(fromObj['id'] ?? fromObj['_id']).nullIfEmpty;
      fromUserName = _asStr(fromObj['name']).nullIfEmpty;
      fromUserAvatar = _asStr(
              fromObj['avatarUrl'] ?? fromObj['avatar_url'] ?? fromObj['avatar'])
          .nullIfEmpty;
    } else {
      fromUserId =
          _asStr(json['fromUserId'] ?? json['from_user_id']).nullIfEmpty;
      fromUserName =
          _asStr(json['fromUserName'] ?? json['from_user_name']).nullIfEmpty;
      fromUserAvatar =
          _asStr(json['fromUserAvatar'] ?? json['from_user_avatar']).nullIfEmpty;
    }

    return OfgNotification(
      id: _asStr(json['id'] ?? json['_id']),
      type: _asStr(json['type']),
      message: _asStr(json['message'] ?? json['text'] ?? json['body']),
      createdAt: _asStr(json['createdAt'] ?? json['created_at']),
      videoId: _asStr(json['videoId'] ?? json['video_id']).nullIfEmpty,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      fromUserAvatar: fromUserAvatar,
      isRead:
          _asBool(json['isRead'] ?? json['is_read'] ?? json['read']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'message': message,
        'createdAt': createdAt,
        'videoId': videoId,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'fromUserAvatar': fromUserAvatar,
        'isRead': isRead,
      };

  OfgNotification copyWith({bool? isRead}) {
    return OfgNotification(
      id: id,
      type: type,
      message: message,
      createdAt: createdAt,
      videoId: videoId,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      fromUserAvatar: fromUserAvatar,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  String toString() => 'OfgNotification(id: $id, type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is OfgNotification && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

// ---------------------------------------------------------------------------
// OfgCreatorStats
// ---------------------------------------------------------------------------

class OfgCreatorStats {
  final int views;
  final int videos;
  final int likes;
  final int followers;
  final int following;

  const OfgCreatorStats({
    required this.views,
    required this.videos,
    required this.likes,
    required this.followers,
    required this.following,
  });

  factory OfgCreatorStats.fromJson(Map<String, dynamic> json) {
    return OfgCreatorStats(
      views: _asInt(json['views'] ?? json['viewCount']),
      videos: _asInt(json['videos'] ?? json['videoCount']),
      likes: _asInt(json['likes'] ?? json['likeCount']),
      followers: _asInt(json['followers'] ?? json['followerCount']),
      following: _asInt(json['following'] ?? json['followingCount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'views': views,
        'videos': videos,
        'likes': likes,
        'followers': followers,
        'following': following,
      };

  @override
  String toString() =>
      'OfgCreatorStats(views: $views, videos: $videos, likes: $likes, '
      'followers: $followers, following: $following)';
}

// ---------------------------------------------------------------------------
// OfgUserProfile  (returned by GET /users/{id})
// ---------------------------------------------------------------------------

class OfgUserProfile {
  final OfgUser user;
  final List<OfgVideo> videos;
  final int followerCount;
  final int followingCount;
  final int videoCount;
  final bool isFollowing;

  const OfgUserProfile({
    required this.user,
    required this.videos,
    required this.followerCount,
    required this.followingCount,
    required this.videoCount,
    required this.isFollowing,
  });

  factory OfgUserProfile.fromJson(Map<String, dynamic> json) {
    final rawVideos = json['videos'];
    final List<OfgVideo> videos = rawVideos is List
        ? rawVideos
            .whereType<Map<String, dynamic>>()
            .map(OfgVideo.fromJson)
            .toList()
        : [];

    return OfgUserProfile(
      user: OfgUser.fromJson(json),
      videos: videos,
      followerCount:
          _asInt(json['followerCount'] ?? json['followers']),
      followingCount:
          _asInt(json['followingCount'] ?? json['following']),
      videoCount: _asInt(json['videoCount'] ?? json['videos_count']),
      isFollowing:
          _asBool(json['isFollowing'] ?? json['following'] ?? json['is_following']),
    );
  }
}

// ---------------------------------------------------------------------------
// OfgReport  (used by admin reports)
// ---------------------------------------------------------------------------

class OfgReport {
  final String id;
  final String type;
  final String targetId;
  final String reason;
  final String status;
  final String createdAt;
  final String? reporterId;
  final String? reporterName;

  const OfgReport({
    required this.id,
    required this.type,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reporterId,
    this.reporterName,
  });

  factory OfgReport.fromJson(Map<String, dynamic> json) {
    return OfgReport(
      id: _asStr(json['id'] ?? json['_id']),
      type: _asStr(json['type']),
      targetId: _asStr(json['targetId'] ?? json['target_id']),
      reason: _asStr(json['reason']),
      status: _asStr(json['status'] ?? 'pending'),
      createdAt: _asStr(json['createdAt'] ?? json['created_at']),
      reporterId: _asStr(json['reporterId'] ?? json['reporter_id']).nullIfEmpty,
      reporterName:
          _asStr(json['reporterName'] ?? json['reporter_name']).nullIfEmpty,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'targetId': targetId,
        'reason': reason,
        'status': status,
        'createdAt': createdAt,
        'reporterId': reporterId,
        'reporterName': reporterName,
      };
}

// ---------------------------------------------------------------------------
// Private utility: format numbers and dates
// ---------------------------------------------------------------------------

String _formatCount(int count) {
  if (count >= 1000000) {
    return '${(count / 1000000).toStringAsFixed(1)}M';
  } else if (count >= 1000) {
    return '${(count / 1000).toStringAsFixed(1)}K';
  }
  return count.toString();
}

String _timeAgo(String isoString) {
  if (isoString.isEmpty) return '';
  try {
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return isoString;
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  } catch (_) {
    return isoString;
  }
}

// ---------------------------------------------------------------------------
// String extension
// ---------------------------------------------------------------------------

extension _NullIfEmpty on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}