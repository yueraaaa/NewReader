import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/category_model.dart';

class CategoryTabs extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;

  const CategoryTabs({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: categories.length + 1, // +1 for "All" tab
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CategoryChip(
              label: '全部',
              isSelected: selectedCategoryId == null,
              onTap: () => onCategorySelected(null),
            );
          }
          final category = categories[index - 1];
          return _CategoryChip(
            label: category.name,
            isSelected: selectedCategoryId == category.id,
            onTap: () => onCategorySelected(category.id),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                : (isDark
                    ? AppColors.darkSurfaceContainerHigh
                    : AppColors.surfaceContainerHigh),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: isSelected
                  ? (isDark ? AppColors.darkOnPrimary : AppColors.onPrimary)
                  : (isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}
