import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore日付型の互換処理ユーティリティ
/// String / Timestamp の混在に対応
DateTime? parseFirestoreDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null; // それ以外は無視
}
