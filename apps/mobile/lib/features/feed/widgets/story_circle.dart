import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/feed_models.dart';

class StoryCircle extends StatelessWidget {
  const StoryCircle({
    super.key,
    required this.story,
    required this.isViewed,
    required this.onTap,
  });

  final StoryItem story;
  final bool isViewed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                // Градиентное кольцо
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isViewed
                        ? null
                        : const LinearGradient(
                            colors: [kGold, kGoldLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: isViewed ? const Color(0xFF2A2A35) : null,
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF111118),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: story.salonLogoUrl != null
                          ? Image.network(
                              story.salonLogoUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                  ),
                ),

                // РЕК бейдж для платных
                if (story.isPaid)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: kGold,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'РЕК',
                      style: TextStyle(
                        fontFamily: 'Mulish',
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A0A0F),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              story.salonName,
              style: AppTextStyles.caption.copyWith(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF1E1E28),
      child: Center(
        child: Text(
          story.salonName.isNotEmpty ? story.salonName[0].toUpperCase() : 'S',
          style: AppTextStyles.subtitle.copyWith(color: kGold),
        ),
      ),
    );
  }
}
