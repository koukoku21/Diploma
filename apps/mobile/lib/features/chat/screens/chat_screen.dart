import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/chat_models.dart';
import '../providers/chat_provider.dart';

// C-11: Диалог с мастером
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.roomId, required this.masterName});

  final String roomId;
  final String masterName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    // Load history then connect socket
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final history = await ref.read(chatMessagesProvider(widget.roomId).future);
    final myId = await ref.read(currentUserIdProvider.future);
    await ref.read(chatSocketProvider(widget.roomId).notifier).connect(history, myId);
    if (mounted) setState(() => _connected = true);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    ref.read(chatSocketProvider(widget.roomId).notifier).send(text);
    _ctrl.clear();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatSocketProvider(widget.roomId));

    // Scroll when new message arrives
    ref.listen(chatSocketProvider(widget.roomId), (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        title: Text(widget.masterName, style: AppTextStyles.title),
        leading: const BackButton(color: kTextPrimary),
      ),
      body: Column(
        children: [
          // ─── Messages list ─────────────────────────────────────
          Expanded(
            child: !_connected
                ? const Center(child: CircularProgressIndicator(color: kGold))
                : messages.isEmpty
                    ? Center(
                        child: Text('Начните переписку',
                            style: AppTextStyles.caption.copyWith(color: kTextTertiary)),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenH, vertical: AppSpacing.md),
                        itemCount: messages.length,
                        itemBuilder: (_, i) => _MessageBubble(message: messages[i]),
                      ),
          ),

          // ─── Input bar ─────────────────────────────────────────
          _InputBar(
            controller: _ctrl,
            onSend: _send,
            onTyping: () =>
                ref.read(chatSocketProvider(widget.roomId).notifier).sendTyping(),
          ),
        ],
      ),
    );
  }
}

// ─── Single message bubble ─────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? kGold : kBgSecondary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.md),
            topRight: const Radius.circular(AppRadius.md),
            bottomLeft: Radius.circular(isMe ? AppRadius.md : AppRadius.xs),
            bottomRight: Radius.circular(isMe ? AppRadius.xs : AppRadius.md),
          ),
        ),
        child: Text(
          message.content,
          style: AppTextStyles.body.copyWith(
            color: isMe ? kBgPrimary : kTextPrimary,
          ),
        ),
      ),
    );
  }
}

// ─── Input bar ─────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onTyping,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onTyping;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH, vertical: AppSpacing.sm),
        decoration: const BoxDecoration(
          color: kBgSecondary,
          border: Border(top: BorderSide(color: kBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: (_) => onTyping(),
                onSubmitted: (_) => onSend(),
                style: AppTextStyles.body,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: 'Сообщение...',
                  hintStyle: AppTextStyles.body.copyWith(color: kTextTertiary),
                  filled: true,
                  fillColor: kBgTertiary,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: kGold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: kBgPrimary, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
