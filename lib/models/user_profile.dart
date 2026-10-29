import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_preferences.dart';

/// Shared model for a user's profile stored in Firestore.
///
/// Firestore path: users/{userId}
///
/// Fields:
///   uid          – Firebase Auth UID (also the document ID)
///   displayName  – User's chosen name
///   email        – Email address (stored for convenience, source of truth is Auth)
///   photoUrl     – Optional profile picture URL (Firebase Storage)
///   currency     – Preferred currency code, default 'USD'
///   locale       – Preferred locale code, default 'en'
///   timeZone     – IANA time zone ID, e.g. 'Asia/Phnom_Penh' (synced from
///                  the phone automatically)
///   notificationPreferences – map of bools, see [NotificationPreferences]
///   createdAt    – Server timestamp when the account was first created
///   updatedAt    – Server timestamp of the last profile update
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.currency = 'USD',
    this.locale = 'en',
    this.timeZone = 'UTC',
    this.notificationPreferences = const NotificationPreferences(),
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String currency;
  final String locale;
  final String timeZone;
  final NotificationPreferences notificationPreferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Firestore serialization ─────────────────────────────────────
  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      currency: data['currency'] as String? ?? 'USD',
      locale: data['locale'] as String? ?? 'en',
      timeZone: data['timeZone'] as String? ?? 'UTC',
      notificationPreferences: NotificationPreferences.fromMap(
          data['notificationPreferences'] as Map<String, dynamic>?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        'email': email,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'currency': currency,
        'locale': locale,
        'timeZone': timeZone,
        'notificationPreferences': notificationPreferences.toMap(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  // ── copyWith ───────────────────────────────────────────────────
  UserProfile copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    String? currency,
    String? locale,
    String? timeZone,
    NotificationPreferences? notificationPreferences,
    DateTime? updatedAt,
  }) =>
      UserProfile(
        uid: uid,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        photoUrl: photoUrl ?? this.photoUrl,
        currency: currency ?? this.currency,
        locale: locale ?? this.locale,
        timeZone: timeZone ?? this.timeZone,
        notificationPreferences:
            notificationPreferences ?? this.notificationPreferences,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
