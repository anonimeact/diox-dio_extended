import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_model.freezed.dart';
part 'post_model.g.dart';

/// Represents a Post entity (sample data model for CRUD demo)
///
/// This class is generated using `freezed` for immutability and pattern matching.
///
/// Example usage:
/// ```dart
/// final post = PostModel(id: 1, title: 'Hello', body: 'World', userId: 2);
/// print(post.toJson());
/// ```
@freezed
abstract class PostModel with _$PostModel {
  const factory PostModel({
    int? id,
    required String title,
    required String body,
    required int userId,
  }) = _PostModel;

  /// Deserialize from JSON
  factory PostModel.fromJson(Map<String, dynamic> json) =>
      _$PostModelFromJson(json);
}
