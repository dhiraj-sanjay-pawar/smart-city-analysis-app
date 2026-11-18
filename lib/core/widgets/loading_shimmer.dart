import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF253547) : const Color(0xFFE8EDF2),
      highlightColor: isDark ? const Color(0xFF2E4057) : const Color(0xFFF6F8FB),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

// Pre-built shimmer for a card layout
class CardShimmer extends StatelessWidget {
  const CardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF253547)
              : const Color(0xFFE8EDF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          LoadingShimmer(height: 16, width: 200),
          SizedBox(height: 8),
          LoadingShimmer(height: 12),
          SizedBox(height: 6),
          LoadingShimmer(height: 12, width: 150),
          SizedBox(height: 12),
          LoadingShimmer(height: 28, width: 90, radius: 100),
        ],
      ),
    );
  }
}

// Shimmer list
class ShimmerList extends StatelessWidget {
  final int count;
  const ShimmerList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: count,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, index) => const CardShimmer(),
    );
  }
}
