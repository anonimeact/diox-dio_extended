import 'package:diox/diox.dart';
import 'package:diox/models/api_result.dart';
import 'package:example/models/post_model.dart';

/// Service class untuk operasi CRUD post
class CrudService extends DioExtended {
  CrudService() : super(baseUrl: 'https://jsonplaceholder.typicode.com');

  Future<ApiResult<List<PostModel>>> getPosts() async {
    final result = await get('/posts');
    if (result.isSuccess) {
      final list = (result.data as List)
          .map((json) => PostModel.fromJson(json))
          .toList();
      return ApiResult.success(list);
    }
    return ApiResult.failure(result.message ?? 'Failed to load posts');
  }

  Future<ApiResult<PostModel>> createPost(dynamic body) async {
    final result = await post('/posts', data: body.toJson());
    if (result.isSuccess) {
      return ApiResult.success(PostModel.fromJson(result.data));
    }
    return ApiResult.failure(result.message ?? 'Failed to create post');
  }

  Future<ApiResult<PostModel>> updatePost(PostModel post) async {
    final result = await put('/posts/${post.id}', data: post.toJson());
    if (result.isSuccess) {
      return ApiResult.success(PostModel.fromJson(result.data));
    }
    return ApiResult.failure(result.message ?? 'Failed to update post');
  }

  Future<ApiResult<void>> deletePost(int id) async {
    final result = await delete('/posts/$id');
    if (result.isSuccess) {
      return ApiResult.success(null);
    }
    return ApiResult.failure(result.message ?? 'Failed to delete post');
  }
}
