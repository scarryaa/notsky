import 'package:atproto/atproto.dart';
import 'package:bluesky/bluesky.dart';

class ContentLabelProcessor {
  static ContentVisibility processLabels(
    List<Label>? postLabels,
    List<ContentLabelPreference> contentLabelPreferences,
  ) {
    if (postLabels == null || postLabels.isEmpty) {
      return ContentVisibility(shouldHide: false, shouldWarn: false);
    }

    bool shouldHide = false;
    bool shouldWarn = false;
    List<String> warningLabels = [];

    for (var postLabel in postLabels) {
      for (var preference in contentLabelPreferences) {
        if (postLabel.value.toLowerCase() == preference.label.toLowerCase()) {
          if (preference.labelerDid == null ||
              postLabel.src == preference.labelerDid) {
            if (preference.visibility == ContentLabelVisibility.hide) {
              shouldHide = true;
              break;
            } else if (preference.visibility == ContentLabelVisibility.warn) {
              shouldWarn = true;
              if (!warningLabels.contains(postLabel.value)) {
                warningLabels.add(postLabel.value);
              }
            }
          }
        }
      }

      if (shouldHide) break;
    }

    return ContentVisibility(
      shouldHide: shouldHide,
      shouldWarn: shouldWarn,
      warningLabels: warningLabels,
    );
  }
}

class ContentVisibility {
  final bool shouldHide;
  final bool shouldWarn;
  final List<String> warningLabels;

  ContentVisibility({
    required this.shouldHide,
    required this.shouldWarn,
    this.warningLabels = const [],
  });
}
