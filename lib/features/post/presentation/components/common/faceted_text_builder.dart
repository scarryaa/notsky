import 'dart:convert';

import 'package:bluesky/bluesky.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FacetedTextBuilder {
  static Widget build(
    BuildContext context,
    String text,
    List<Facet>? facets, {
    double fontSize = 14.0,
  }) {
    if (facets == null || facets.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: fontSize,
        ),
      );
    }

    final sortedFacets = List<Facet>.from(facets);
    sortedFacets.sort((a, b) => a.index.byteStart.compareTo(b.index.byteStart));

    final utf8Bytes = utf8.encode(text);
    final List<InlineSpan> spans = [];
    int currentIndex = 0;

    for (var facet in sortedFacets) {
      final byteStart = facet.index.byteStart;
      final byteEnd = facet.index.byteEnd;

      if (byteStart > currentIndex) {
        final beforeText = utf8.decode(
          utf8Bytes.sublist(currentIndex, byteStart),
        );
        spans.add(
          TextSpan(
            text: beforeText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: fontSize,
            ),
          ),
        );
      }

      final facetText = utf8.decode(utf8Bytes.sublist(byteStart, byteEnd));

      if (facet.features.isNotEmpty) {
        var feature = facet.features.first;

        if (feature.data is FacetLink) {
          spans.add(
            TextSpan(
              text: facetText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: fontSize,
                decoration: TextDecoration.underline,
              ),
              recognizer:
                  TapGestureRecognizer()
                    ..onTap = () {
                      launchUrl(Uri.parse((feature.data as FacetLink).uri));
                    },
            ),
          );
        } else if (feature.data is FacetMention) {
          spans.add(
            TextSpan(
              text: facetText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: fontSize,
              ),
              recognizer:
                  TapGestureRecognizer()
                    ..onTap = () {
                      // TODO navigate to profile
                    },
            ),
          );
        } else {
          spans.add(
            TextSpan(
              text: facetText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: fontSize,
              ),
            ),
          );
        }
      } else {
        spans.add(
          TextSpan(
            text: facetText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: fontSize,
            ),
          ),
        );
      }

      currentIndex = byteEnd;
    }

    if (currentIndex < utf8Bytes.length) {
      final remainingText = utf8.decode(utf8Bytes.sublist(currentIndex));
      spans.add(
        TextSpan(
          text: remainingText,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: fontSize,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }
}
