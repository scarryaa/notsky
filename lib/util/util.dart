import 'package:atproto_core/atproto_core.dart';

bool isExpiredTokenError(dynamic error) {
  return error is InvalidRequestException && error.response.status.code == 400;
}

String formatNumber(num number) {
  if (number < 1000) {
    return number.toString();
  } else if (number < 1000000) {
    double result = number / 1000;
    if (result == result.truncate()) {
      return '${result.toInt()}k';
    }
    return '${result.toStringAsFixed(1)}k';
  } else if (number < 1000000000) {
    double result = number / 1000000;
    if (result == result.truncate()) {
      return '${result.toInt()}M';
    }
    return '${result.toStringAsFixed(1)}M';
  } else {
    double result = number / 1000000000;
    if (result == result.truncate()) {
      return '${result.toInt()}B';
    }
    return '${result.toStringAsFixed(1)}B';
  }
}
