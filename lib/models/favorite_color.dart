import 'package:flutter/material.dart';

class FavoriteColor {
  final String id;
  final Color color;
  final String? userId;
  final DateTime createdAt;
  final String? name;
  final bool isSync;

  FavoriteColor({
    required this.id,
    required this.color,
    this.userId,
    required this.createdAt,
    this.name,
    this.isSync = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'color': color.value,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'name': name,
      'is_sync': isSync ? 1 : 0,
    };
  }

  factory FavoriteColor.fromMap(Map<String, dynamic> map) {
    return FavoriteColor(
      id: map['id'],
      color: Color(map['color']),
      userId: map['user_id'],
      createdAt: DateTime.parse(map['created_at']),
      name: map['name'],
      isSync: map['is_sync'] == 1,
    );
  }

  FavoriteColor copyWith({
    String? id,
    Color? color,
    String? userId,
    DateTime? createdAt,
    String? name,
    bool? isSync,
  }) {
    return FavoriteColor(
      id: id ?? this.id,
      color: color ?? this.color,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      isSync: isSync ?? this.isSync,
    );
  }
}