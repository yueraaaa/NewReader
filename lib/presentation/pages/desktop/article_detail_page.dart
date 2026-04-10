import 'package:flutter/material.dart';

class ArticleDetailPage extends StatelessWidget {
  final String articleId;

  const ArticleDetailPage({
    super.key,
    required this.articleId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Article $articleId')),
    );
  }
}
