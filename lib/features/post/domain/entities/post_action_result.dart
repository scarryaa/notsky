import 'package:atproto_core/atproto_core.dart';

class PostActionResult {
  final bool success;
  final String? error;
  final AtUri? uri;

  PostActionResult({this.success = false, this.error, this.uri});
}
