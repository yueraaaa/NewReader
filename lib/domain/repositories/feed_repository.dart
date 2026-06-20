import '../../data/models/feed_model.dart';
import '../../data/models/category_model.dart';

abstract class FeedRepository {
  void setUserId(String? userId);

  Future<List<FeedModel>> getFeeds();
  Future<List<FeedModel>> getFeedsByCategory(String categoryId);
  Future<FeedModel?> getFeedById(String id);
  Future<void> addFeed(String url, {String? categoryId});
  Future<void> updateFeed(FeedModel feed);
  Future<void> updateFeedFields(String feedId, {String? title, String? categoryId});
  Future<void> deleteFeed(String id);
  Future<void> refreshFeed(String id);
  Future<void> refreshAllFeeds();
  Future<List<CategoryModel>> getCategories();
  Future<void> addCategory(String name, String color);
  Future<void> updateCategory(CategoryModel category);
  Future<void> updateCategoryFields(String categoryId, String name);
  Future<void> deleteCategory(String id);
}
