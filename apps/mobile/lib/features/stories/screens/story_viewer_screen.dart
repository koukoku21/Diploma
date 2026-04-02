import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../feed/data/feed_models.dart';
import '../../feed/providers/stories_provider.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  final List<StoryItem> stories;
  final int initialIndex;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _progressController;

  static const _storyDuration = Duration(seconds: 7);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _next();
      });
    _startStory();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _startStory() {
    _progressController.forward(from: 0);
    // Записываем просмотр
    final storyId = widget.stories[_currentIndex].id;
    ref.read(storiesProvider.notifier).markViewed(storyId);
  }

  void _next() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() => _currentIndex++);
      _startStory();
    } else {
      context.pop();
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startStory();
    }
  }

  void _onTapDown(TapDownDetails details) {
    _progressController.stop();
  }

  void _onTapUp(TapUpDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx < screenWidth / 2) {
      _prev();
    } else {
      _next();
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ─── Медиа ───────────────────────────────────────────
            _StoryMedia(mediaUrl: story.mediaUrl),

            // ─── Градиент снизу ──────────────────────────────────
            const _BottomGradient(),

            // ─── Прогресс-бары ───────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: _ProgressBars(
                count: widget.stories.length,
                currentIndex: _currentIndex,
                progress: _progressController,
              ),
            ),

            // ─── Шапка: салон ────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 28,
              left: 16,
              right: 48,
              child: Row(
                children: [
                  // Аватар салона
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: kGold, width: 1.5),
                      color: kBgSecondary,
                    ),
                    child: story.salonLogoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              story.salonLogoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _avatarPlaceholder(story.salonName),
                            ),
                          )
                        : _avatarPlaceholder(story.salonName),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.salonName,
                          style: AppTextStyles.label.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            shadows: _textShadow,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (story.isPaid)
                          Text('Реклама',
                              style: AppTextStyles.caption.copyWith(
                                color: kGold,
                                shadows: _textShadow,
                              )),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Кнопка закрыть ──────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 28,
              right: 12,
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),

            // ─── Подпись + кнопка ────────────────────────────────
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (story.caption != null) ...[
                    Text(
                      story.caption!,
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        shadows: _textShadow,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        _progressController.stop();
                        context.pop();
                        // Переход к поиску мастеров этой категории
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGold,
                        foregroundColor: const Color(0xFF0A0A0F),
                        shape: const StadiumBorder(),
                      ),
                      child: Text('Записаться',
                          style: AppTextStyles.label.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0A0A0F))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'S',
        style: AppTextStyles.label.copyWith(color: kGold),
      ),
    );
  }

  static final _textShadow = [
    const Shadow(color: Colors.black54, blurRadius: 8),
  ];
}

// ─── Медиа ───────────────────────────────────────────────────────
class _StoryMedia extends StatelessWidget {
  const _StoryMedia({required this.mediaUrl});
  final String mediaUrl;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      mediaUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF111118),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              color: Color(0xFF5A5750), size: 48),
        ),
      ),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: kGold, strokeWidth: 2),
          ),
        );
      },
    );
  }
}

// ─── Градиент снизу ──────────────────────────────────────────────
class _BottomGradient extends StatelessWidget {
  const _BottomGradient();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 280,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black87],
          ),
        ),
      ),
    );
  }
}

// ─── Прогресс-бары ───────────────────────────────────────────────
class _ProgressBars extends StatelessWidget {
  const _ProgressBars({
    required this.count,
    required this.currentIndex,
    required this.progress,
  });
  final int count;
  final int currentIndex;
  final AnimationController progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < count - 1 ? 3 : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: i < currentIndex
                  ? _bar(1.0)
                  : i == currentIndex
                      ? AnimatedBuilder(
                          animation: progress,
                          builder: (_, __) => _bar(progress.value),
                        )
                      : _bar(0.0),
            ),
          ),
        );
      }),
    );
  }

  Widget _bar(double value) {
    return LinearProgressIndicator(
      value: value,
      backgroundColor: Colors.white24,
      valueColor: const AlwaysStoppedAnimation(Colors.white),
      minHeight: 3,
    );
  }
}
