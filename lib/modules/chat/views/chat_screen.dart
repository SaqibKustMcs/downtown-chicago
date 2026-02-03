import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:food_flow_app/core/widgets/animated_list_item.dart';
import 'package:food_flow_app/core/utils/tabler_icons_helper.dart';
import 'package:food_flow_app/models/chat_message_model.dart';
import 'package:food_flow_app/styles/colors/custom_colors.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String contactName;
  final String? contactAvatarUrl;

  const ChatScreen({
    super.key,
    required this.contactName,
    this.contactAvatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Sample messages
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Are you coming?',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
      isSent: true,
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&q=80',
    ),
    ChatMessage(
      text: 'Hay, Congratulation for order',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 49)),
      isSent: false,
      avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&q=80',
    ),
    ChatMessage(
      text: 'Hey Where are you now?',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 49)),
      isSent: true,
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&q=80',
    ),
    ChatMessage(
      text: 'I\'m Coming , just wait ...',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 48)),
      isSent: false,
      avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&q=80',
    ),
    ChatMessage(
      text: 'Hurry Up, Man',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 48)),
      isSent: true,
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&q=80',
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: _messageController.text.trim(),
          timestamp: DateTime.now(),
          isSent: true,
          avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&q=80',
        ),
      );
      _messageController.clear();
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final showTimestamp = index == 0 ||
                      _messages[index - 1].timestamp.difference(message.timestamp).inMinutes > 5;

                  return AnimatedListItem(
                    index: index,
                    delay: const Duration(milliseconds: 50),
                    child: Column(
                      crossAxisAlignment: message.isSent
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (showTimestamp)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: Sizes.s8),
                            child: Text(
                              _formatTime(message.timestamp),
                              style: AppTextStyles.caption.copyWith(
                                color: CustomColors.secondaryTextColor,
                                fontSize: Sizes.s12,
                              ),
                            ),
                          ),
                        _buildMessageBubble(message),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Message Input
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: Sizes.s4,
            offset: const Offset(0, Sizes.s2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Close Button
          Container(
            width: Sizes.s40,
            height: Sizes.s40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(TablerIconsHelper.close, color: CustomColors.textBoldColor, size: Sizes.s20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: Sizes.s12),

          // Contact Name
          Expanded(
            child: Text(
              widget.contactName,
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.w600,
                color: CustomColors.textBoldColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Sizes.s12),
      child: Row(
        mainAxisAlignment: message.isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isSent) ...[
            // Avatar (left side for received messages)
            _buildAvatar(message.avatarUrl, message.isSent),
            const SizedBox(width: Sizes.s8),
          ],

          // Message Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Sizes.s16,
                vertical: Sizes.s12,
              ),
              decoration: BoxDecoration(
                color: message.isSent
                    ? const Color(0xFFFF6B35)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(Sizes.s16),
                  topRight: const Radius.circular(Sizes.s16),
                  bottomLeft: Radius.circular(message.isSent ? Sizes.s16 : Sizes.s4),
                  bottomRight: Radius.circular(message.isSent ? Sizes.s4 : Sizes.s16),
                ),
              ),
              child: Text(
                message.text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: message.isSent ? Colors.white : CustomColors.textBoldColor,
                ),
              ),
            ),
          ),

          if (message.isSent) ...[
            const SizedBox(width: Sizes.s8),
            // Status Indicator (double checkmark for sent messages)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  TablerIconsHelper.check,
                  size: Sizes.s14,
                  color: const Color(0xFFFF6B35),
                ),
                const SizedBox(width: -Sizes.s4),
                Icon(
                  TablerIconsHelper.check,
                  size: Sizes.s14,
                  color: const Color(0xFFFF6B35),
                ),
              ],
            ),
            const SizedBox(width: Sizes.s4),
            // Avatar (right side for sent messages)
            _buildAvatar(message.avatarUrl, message.isSent),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, bool isSent) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: avatarUrl ?? '',
        width: Sizes.s32,
        height: Sizes.s32,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: Sizes.s32,
          height: Sizes.s32,
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: Sizes.s32,
          height: Sizes.s32,
          color: Colors.grey.shade200,
          child: Icon(
            TablerIconsHelper.person,
            size: Sizes.s16,
            color: CustomColors.secondaryTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(Sizes.s12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: Sizes.s4,
            offset: const Offset(0, -Sizes.s2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji Button
          Container(
            width: Sizes.s40,
            height: Sizes.s40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined, color: CustomColors.secondaryTextColor, size: Sizes.s20),
              onPressed: () {
                // TODO: Open emoji picker
              },
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: Sizes.s8),

          // Message Input Field
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Write somethings',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: CustomColors.secondaryTextColor,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Sizes.s24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Sizes.s16,
                  vertical: Sizes.s12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: Sizes.s8),

          // Send Button
          Container(
            width: Sizes.s40,
            height: Sizes.s40,
            decoration: const BoxDecoration(
              color: Color(0xFFFF6B35),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: Sizes.s20),
              onPressed: _sendMessage,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
