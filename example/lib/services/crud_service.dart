import 'package:dio_extended/diox.dart';
import 'package:dio_extended/models/api_result.dart';
import 'package:example/models/post_model.dart';

/// Example service class untuk operasi CRUD post
class CrudService extends DioExtended {
  CrudService()
      : super(
            baseUrl: 'https://jsonplaceholder.typicode.com',
            tokenExpiredCode: 401);

  /// Overriding [handleTokenExpired] to fetch new auth key or etc
  @override
  Future<dynamic> handleTokenExpired() async {
    /// Chane this line with you functions
    final newHeader = await Future.delayed(Duration(seconds: 3));

    /// Send callback as Map
    /// exemple {'Authentication': 'Bearer xxx'}
    return newHeader;
  }

  /// Fetches a list of all posts from the API.
  ///
  /// Returns an [ApiResult] containing a list of [PostModel] objects on success,
  /// or an error message on failure.
  Future<ApiResult<List<PostModel>>> getPosts() async {
    return await callApiRequest<List<PostModel>>(
      request: () => get('/posts'),
      parseData: (data) => (data as List)
          .map((itemJson) => PostModel.fromJson(itemJson))
          .toList(),
    );
  }

  /// Creates a new post on the server.
  ///
  /// The [body] should be a map or a model that can be converted to JSON,
  /// representing the post to be created.
  ///
  /// Returns an [ApiResult] containing the newly created [PostModel] on success,
  /// or an error message on failure.
  Future<ApiResult<PostModel>> createPost(dynamic body) async {
    return await callApiRequest<PostModel>(
      request: () => post('/posts', body: body),
      parseData: (data) => PostModel.fromJson(data),
    );
  }

  /// Updates an existing post on the server.
  ///
  /// The [body] must be a [PostModel] instance containing the updated data.
  /// The ID of the post to update is extracted from the `body.id` property.
  ///
  /// Returns an [ApiResult] containing the updated [PostModel] on success,
  /// or an error message on failure.
  Future<ApiResult<PostModel>> updatePost(PostModel body) async {
    return await callApiRequest<PostModel>(
      request: () => put('/posts/${body.id}', body: body.toJson()),
      parseData: (data) => PostModel.fromJson(data),
    );
  }

  /// Deletes a post from the server by its unique [id].
  ///
  /// This method does not expect any data in the response body and therefore
  /// returns `ApiResult<void>`. The success of the operation is determined by
  /// the status code and the absence of an error message.
  ///
  /// Returns an [ApiResult<void>] which is successful if the deletion is confirmed,
  /// or contains an error message if it fails.
  Future<ApiResult<void>> deletePost(int id) async {
    return await callApiRequest<void>(
      request: () => delete('/posts/$id'),
      // For a void return, we don't need to parse the response body.
      // We provide a no-op (no operation) function.
      parseData: (data) => {},
    );
  }
}
