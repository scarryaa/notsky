import 'package:atproto_core/atproto_core.dart';

bool isExpiredTokenError(dynamic error) {
  return error is InvalidRequestException && error.response.status.code == 400;
}
