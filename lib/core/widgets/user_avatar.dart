import 'package:flutter/material.dart';

import '../../features/session/domain/user.dart';
import '../theme/app_colors.dart';

/// Circular avatar with a gradient initial fallback.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.user,
    this.size = 40,
    this.showEditBadge = false,
    this.borderRadius,
  });

  final User user;
  final double size;
  final bool showEditBadge;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size / 2);
    final imageUrl = user.profileImageUrl;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: radius,
            child: imageUrl == null
                ? _fallback()
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : _fallback(),
                    errorBuilder: (_, _, _) => _fallback(),
                  ),
          ),
          if (showEditBadge)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: Icon(
                  Icons.edit,
                  size: size * 0.17,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.posterGradientFor(user.id),
      ),
      alignment: Alignment.center,
      child: Text(
        user.initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
