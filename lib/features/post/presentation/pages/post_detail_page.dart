import 'package:bluesky/bluesky.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/post/domain/entities/post_content.dart';
import 'package:notsky/features/post/presentation/components/base_post_component.dart';
import 'package:notsky/features/post/presentation/cubits/post_cubit.dart';
import 'package:notsky/main.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({
    super.key,
    required this.post,
    required this.reason,
    required this.reply,
    required this.contentLabelPreferences,
  });

  final Post post;
  final Reason? reason;
  final Reply? reply;
  final List<ContentLabelPreference> contentLabelPreferences;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> with RouteAware {
  late PostCubit _postCubit;
  final ScrollController _scrollController = ScrollController();
  double? _savedScrollPosition;

  @override
  void initState() {
    super.initState();
    _postCubit = PostCubit(context.read<AuthCubit>().getBlueskyService());
    _initializeThread();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    NotSkyApp.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    NotSkyApp.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _initializeThread();
    if (_savedScrollPosition != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_savedScrollPosition!);
        }
      });
    }
  }

  @override
  void didPushNext() {
    if (_scrollController.hasClients) {
      _savedScrollPosition = _scrollController.offset;
    }
  }

  void _initializeThread() {
    _postCubit.initializePost(
      widget.post.uri.toString(),
      widget.post.viewer.isLiked,
      widget.post.viewer.like,
      widget.post.viewer.isReposted,
      widget.post.viewer.repost,
      widget.post.likeCount,
      widget.post.repostCount + widget.post.quoteCount,
    );
    _postCubit.getThread(widget.post.uri);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _postCubit,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size(double.infinity, 60.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.25),
                ),
              ),
            ),
            child: AppBar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              scrolledUnderElevation: 0,
              actions: [
                // TODO
              ],
              title: Text('Post'),
            ),
          ),
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              BasePostComponent(
                postContent: RegularPost(widget.post),
                reason: widget.reason,
                reply: widget.reply,
                detailed: true,
                contentLabelPreferences: widget.contentLabelPreferences,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
