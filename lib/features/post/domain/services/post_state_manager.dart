import 'dart:async';

import 'package:notsky/features/post/presentation/cubits/post_state.dart';

class PostStateManager {
  static final PostStateManager _instance = PostStateManager._internal();
  factory PostStateManager() => _instance;
  PostStateManager._internal();

  final Map<String, PostState> _postStates = {};
  final _controller = StreamController<String>.broadcast();

  Stream<String> get postUpdates => _controller.stream;

  void updatePostState(String postUri, PostState state) {
    _postStates[postUri] = state;
    _controller.add(postUri);
  }

  PostState? getPostState(String postUri) {
    return _postStates[postUri];
  }
}
