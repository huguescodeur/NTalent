import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

Widget buildShimmerEffect({required BuildContext context}) {
  final size = MediaQuery.of(context).size;

  return Container(
    height: size.height,
    width: size.width,
    color: Colors.black,
    child: Stack(
      children: [
        // Placeholder for video
        Positioned.fill(
          child: Shimmer.fromColors(
            baseColor: Colors.grey[700]!,
            highlightColor: Colors.grey[500]!,
            child: Container(
              color: Colors.grey[700],
            ),
          ),
        ),

        // Placeholder for user info (top)
        Positioned(
          top: 40,
          left: 10,
          child: Row(
            children: [
              // Avatar shimmer
              Shimmer.fromColors(
                baseColor: Colors.grey[700]!,
                highlightColor: Colors.grey[500]!,
                child: CircleAvatar(
                  backgroundColor: Colors.grey[700],
                  radius: 20,
                ),
              ),
              const SizedBox(width: 10),
              // Name and timestamp shimmer
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[700]!,
                    highlightColor: Colors.grey[500]!,
                    child: Container(
                      width: 120,
                      height: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[700]!,
                    highlightColor: Colors.grey[500]!,
                    child: Container(
                      width: 80,
                      height: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Placeholder for actions (right side)
        Positioned(
          right: 10,
          bottom: 100,
          child: Column(
            children: List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[700]!,
                  highlightColor: Colors.grey[500]!,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // Placeholder for description (bottom)
        Positioned(
          bottom: 30,
          left: 10,
          right: 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[700]!,
                highlightColor: Colors.grey[500]!,
                child: Container(
                  width: size.width * 0.8,
                  height: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Shimmer.fromColors(
                baseColor: Colors.grey[700]!,
                highlightColor: Colors.grey[500]!,
                child: Container(
                  width: size.width * 0.6,
                  height: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
