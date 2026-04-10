import 'package:flutter_test/flutter_test.dart';
import 'package:real_reader/data/models/category_model.dart';

void main() {
  final now = DateTime(2024, 1, 1, 12, 0, 0);
  final testMap = {
    'id': 'cat-1',
    'name': 'Technology',
    'color': '#00497d',
    'sort_order': 1,
    'is_deleted': 0,
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  };

  group('CategoryModel', () {
    test('fromMap creates correct instance', () {
      final category = CategoryModel.fromMap(testMap);
      expect(category.id, 'cat-1');
      expect(category.name, 'Technology');
      expect(category.color, '#00497d');
      expect(category.sortOrder, 1);
      expect(category.isDeleted, false);
      expect(category.createdAt, now);
      expect(category.updatedAt, now);
    });

    test('toMap produces correct map', () {
      final category = CategoryModel.fromMap(testMap);
      final map = category.toMap();
      expect(map['id'], 'cat-1');
      expect(map['name'], 'Technology');
      expect(map['color'], '#00497d');
      expect(map['sort_order'], 1);
      expect(map['is_deleted'], 0);
    });

    test('fromMap -> toMap roundtrip preserves data', () {
      final original = CategoryModel.fromMap(testMap);
      final roundtrip = CategoryModel.fromMap(original.toMap());
      expect(roundtrip, original);
    });

    test('toMap -> fromMap roundtrip preserves data', () {
      final category = CategoryModel.fromMap(testMap);
      final map = category.toMap();
      final roundtrip = CategoryModel.fromMap(map);
      expect(roundtrip, category);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = CategoryModel.fromMap(testMap);
      final updated = original.copyWith(
        name: 'Science',
        color: '#ff0000',
      );
      expect(updated.name, 'Science');
      expect(updated.color, '#ff0000');
      expect(updated.id, original.id);
      expect(updated.sortOrder, original.sortOrder);
    });

    test('Equatable props are correct', () {
      final cat1 = CategoryModel.fromMap(testMap);
      final cat2 = CategoryModel.fromMap(testMap);
      expect(cat1, cat2);
      expect(cat1.props.length, 7);
    });

    test('isDeleted maps from int 1 correctly', () {
      final mapDeleted = Map<String, dynamic>.from(testMap);
      mapDeleted['is_deleted'] = 1;
      final category = CategoryModel.fromMap(mapDeleted);
      expect(category.isDeleted, true);
    });

    test('sortOrder defaults to 0 when null', () {
      final mapNoSort = Map<String, dynamic>.from(testMap);
      mapNoSort['sort_order'] = null;
      final category = CategoryModel.fromMap(mapNoSort);
      expect(category.sortOrder, 0);
    });

    test('optional fields can be null', () {
      final mapMinimal = {
        'id': 'cat-1',
        'name': 'Technology',
        'color': '#00497d',
        'is_deleted': 0,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      final category = CategoryModel.fromMap(mapMinimal);
      expect(category.sortOrder, 0);
    });
  });
}
