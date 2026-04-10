import 'package:flutter/material.dart';

class FeedListPage extends StatelessWidget {
  final String? categoryId;
  final String? feedId;

  const FeedListPage({
    super.key,
    this.categoryId,
    this.feedId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Feed List - ${categoryId ?? feedId ?? "unknown"}'),
      ),
    );
  }
}
