import 'package:equatable/equatable.dart';

abstract class FeedEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadFeeds extends FeedEvent {}

class AddFeed extends FeedEvent {
  final String url;
  final String? categoryId;
  AddFeed(this.url, {this.categoryId});
  @override
  List<Object?> get props => [url, categoryId];
}

class DeleteFeed extends FeedEvent {
  final String feedId;
  DeleteFeed(this.feedId);
  @override
  List<Object?> get props => [feedId];
}

class RefreshFeeds extends FeedEvent {}

class RefreshFeed extends FeedEvent {
  final String feedId;
  RefreshFeed(this.feedId);
  @override
  List<Object?> get props => [feedId];
}

class AddCategory extends FeedEvent {
  final String name;
  final String color;
  AddCategory(this.name, this.color);
  @override
  List<Object?> get props => [name, color];
}

class DeleteCategory extends FeedEvent {
  final String categoryId;
  DeleteCategory(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}
