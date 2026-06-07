import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

/// AuraParsedText
///
/// A widget that parses text to find `@username` tags, renders them styled
/// as clickable links, and navigates to the matching user's profile on click.
class AuraParsedText extends StatelessWidget {
  const AuraParsedText({
    super.key,
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final regex = RegExp(r'@([a-zA-Z0-9_\.]+)');
    final matches = regex.allMatches(text);

    if (matches.isEmpty) {
      return Text(text, style: style);
    }

    final spans = <TextSpan>[];
    int lastMatchEnd = 0;

    for (final match in matches) {
      // Text before match
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: style,
        ));
      }

      final username = match.group(1)!;
      final taggedText = match.group(0)!;

      spans.add(TextSpan(
        text: taggedText,
        style: style.copyWith(
          color: AuraColors.primary,
          fontWeight: FontWeight.bold,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            try {
              final query = await FirebaseFirestore.instance
                  .collection('users')
                  .where('username', isEqualTo: username)
                  .limit(1)
                  .get();

              if (query.docs.isNotEmpty) {
                final uid = query.docs.first.id;
                if (context.mounted) {
                  context.push('/user/$uid');
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Không tìm thấy người dùng @$username'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi tải thông tin: $e'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
      ));

      lastMatchEnd = match.end;
    }

    // Text after last match
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: style,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
