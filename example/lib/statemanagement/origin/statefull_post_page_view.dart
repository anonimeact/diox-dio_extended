import 'package:dio_extended/models/api_result.dart';
import 'package:example/services/crud_service.dart';
import 'package:flutter/material.dart';
import '../../../models/post_model.dart';

class StatefullPostPageView extends StatefulWidget {
  const StatefullPostPageView({super.key});

  @override
  State<StatefullPostPageView> createState() => _StatefullPostPageViewState();
}

class _StatefullPostPageViewState extends State<StatefullPostPageView> {
  final _service = CrudService();
  late Future<ApiResult<List<PostModel>>> _futurePosts;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    _futurePosts = _service.getPosts();
  }

  Future<void> _addPost() async {
    final newPost = PostModel(
      title: 'New Post ${DateTime.now().millisecondsSinceEpoch}',
      body: 'This is a new post body.',
      userId: 1,
    );

    final result = await _service.createPost(newPost);

    if (result.isSuccess) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post created successfully!')));
      setState(_loadPosts); // refresh list
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to create post')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Posts Example')),
      body: FutureBuilder<ApiResult<List<PostModel>>>(
        future: _futurePosts,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final result = snapshot.data!;
          if (result.isSuccess) {
            final posts = result.data!;
            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return ListTile(
                  title: Text(post.title),
                  subtitle: Text(post.body),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await _service.deletePost(post.id!);
                      setState(_loadPosts);
                    },
                  ),
                );
              },
            );
          }

          return Center(child: Text(result.message ?? 'Unknown error'));
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addPost, child: const Icon(Icons.add)),
    );
  }
}
