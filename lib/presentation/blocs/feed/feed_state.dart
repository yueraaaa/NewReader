import 'package:equatable/equatable.dart';
import '../../../data/models/feed_model.dart';
import '../../../data/models/category_model.dart';

abstract class FeedState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FeedInitial extends FeedState {}

class FeedLoading extends FeedState {}

class FeedsLoaded extends FeedState {
  final List<FeedModel> feeds;
  final List<CategoryModel> categories;

  FeedsLoaded({required this.feeds, required this.categories});

  @override
  List<Object?> get props => [feeds, categories];
}

class FeedError extends FeedState {
  final String message;
  FeedError(this.message);
  @override
  List<Object?> get props => [message];
}
