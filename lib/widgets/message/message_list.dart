import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/motion.dart';
import '../../domain/entities/chat.dart';
import '../../presentation/providers/app_providers.dart';
import '../../presentation/providers/telegram_client_provider.dart';
import '../common/state_widgets.dart';
import '../chat/chat_picker_sheet.dart';
import 'album_grouping.dart';
import 'album_message_bubble.dart';
import 'message_bubble.dart';
import 'date_separator.dart';
import 'reaction_bar.dart';
import 'reaction_picker.dart';

class MessageList extends ConsumerStatefulWidget {
  final Chat chat;

  const MessageList({super.key, required this.chat});

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  late ScrollController _scrollController;
  bool _isAutoScrolling = false;
  bool _shouldAutoScroll = true;
  // Tracks message IDs that have already played their entrance animation.
  // Pre-populated with the initial message set so first-load doesn't
  // animate every history bubble — only new arrivals (sent or received)
  // animate in. Cleared on chat switch.
  final Set<int> _seenMessageIds = <int>{};
  bool _seenIdsCaptured = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Load messages for this chat when widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messageProvider.notifier).selectChat(widget.chat.id);
      ref.read(messageProvider.notifier).loadMessages(widget.chat.id);
    });
  }

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When chat changes, load messages for the new chat
    if (oldWidget.chat.id != widget.chat.id) {
      _seenMessageIds.clear();
      _seenIdsCaptured = false;
      // Delay the provider modification to avoid modifying during build
      Future(() {
        ref.read(messageProvider.notifier).selectChat(widget.chat.id);
        ref.read(messageProvider.notifier).loadMessages(widget.chat.id);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final currentScrollPosition = _scrollController.offset;

      // With reverse: true, offset 0 = bottom (newest messages visible)
      // Show scroll-to-bottom button when scrolled away from newest messages
      final shouldAutoScroll = currentScrollPosition < 100;
      if (shouldAutoScroll != _shouldAutoScroll) {
        setState(() {
          _shouldAutoScroll = shouldAutoScroll;
        });
      }

      // Load more messages when scrolling to the top (older messages)
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreMessages();
      }
    }
  }

  void _loadMoreMessages() {
    final msgState = ref.read(messageProvider).value;
    if (msgState == null) return;
    if (msgState.isLoadingMore) return;
    if (!msgState.hasMoreMessages(widget.chat.id)) return;
    ref.read(messageProvider.notifier).loadMoreMessages(widget.chat.id);
  }

  void _markLatestAsRead(List<Message>? messages) {
    if (messages == null || messages.isEmpty) return;

    // Find the latest incoming message (messages are sorted newest first)
    final latestIncoming = messages.cast<Message?>().firstWhere(
      (m) => m != null && !m.isOutgoing,
      orElse: () => null,
    );

    if (latestIncoming == null) return;

    // The notifier handles duplicate checking via lastMarkedMessageIds in state
    ref
        .read(messageProvider.notifier)
        .markAsRead(widget.chat.id, latestIncoming.id);
  }

  void _scrollToBottom({bool animated = true}) {
    if (_scrollController.hasClients && !_isAutoScrolling) {
      _isAutoScrolling = true;

      if (animated) {
        _scrollController
            .animateTo(
              0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            )
            .then((_) {
              _isAutoScrolling = false;
              if (!mounted) return;
              if (!_shouldAutoScroll) {
                setState(() {
                  _shouldAutoScroll = true;
                });
              }
            });
      } else {
        _scrollController.jumpTo(0.0);
        _isAutoScrolling = false;
        if (!_shouldAutoScroll) {
          setState(() {
            _shouldAutoScroll = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to message updates for this chat
    ref.listen(
      messageProvider.select((state) => state.value?.selectedChatMessages),
      (prev, next) {
        if (next != null &&
            prev != null &&
            next.length > prev.length &&
            _shouldAutoScroll) {
          // New message arrived, scroll to bottom and mark as read
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
            _markLatestAsRead(next);
          });
        }
      },
    );

    // Watch messages for this specific chat to ensure rebuilds on new messages/reactions
    final messages = ref.watch(
      messageProvider.select(
        (state) => state.value?.messagesByChat[widget.chat.id],
      ),
    );
    final isChatInitialized = ref.watch(
      messageProvider.select(
        (state) => state.value?.isChatInitialized(widget.chat.id) ?? false,
      ),
    );
    final isLoadingMore = ref.watch(
      messageProvider.select((state) => state.value?.isLoadingMore ?? false),
    );
    final hasError = ref.watch(
      messageProvider.select((state) => state.hasError),
    );
    final error = ref.watch(
      messageProvider.select((state) => state.error?.toString()),
    );

    if (hasError && error != null) {
      return _buildErrorState(error);
    }

    // Show loading if messages not loaded yet OR chat hasn't completed initialization
    if (messages == null || !isChatInitialized) {
      return _buildLoadingState();
    }

    // Empty list with initialization complete means truly no messages
    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    // Mark latest message as read when messages are displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markLatestAsRead(messages);
    });

    // First time we see a non-empty list: capture every existing id as
    // already-animated so initial load doesn't entrance-animate the
    // entire history.
    if (!_seenIdsCaptured) {
      _seenMessageIds.addAll(messages.map((m) => m.id));
      _seenIdsCaptured = true;
    }

    final rows = groupAlbums(messages);

    return Stack(
      children: [
        Column(
          children: [
            if (isLoadingMore) _buildLoadingMoreIndicator(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _refreshMessages(),
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Show newest messages at bottom
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final showDateSeparator = _shouldShowDateSeparator(
                      rows,
                      index,
                    );
                    return _buildRow(
                      context: context,
                      row: row,
                      showDateSeparator: showDateSeparator,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: AnimatedSwitcher(
            duration: motionDurationFor(
              context,
              kAppearanceTransitionDuration,
            ),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: _shouldAutoScroll
                ? const SizedBox.shrink(key: ValueKey('hidden'))
                : _buildScrollToBottomButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildRow({
    required BuildContext context,
    required MessageRow row,
    required bool showDateSeparator,
  }) {
    // A row animates iff at least one of its messages has not been seen yet.
    // For an album that means a freshly-arrived item triggers the entrance
    // animation for the whole row — desirable, since the visible content
    // materially changed.
    final memberIds = switch (row) {
      SingleMessageRow() => [row.message.id],
      AlbumRow() => row.messages.map((m) => m.id).toList(),
    };
    final shouldAnimate = memberIds.any((id) => !_seenMessageIds.contains(id));
    if (shouldAnimate) _seenMessageIds.addAll(memberIds);

    final Widget bubble = switch (row) {
      SingleMessageRow() => MessageBubble(
          key: ValueKey(row.message.id),
          message: row.message,
          showSender: !row.message.isOutgoing,
          onLongPress: () => _showMessageOptions(context, row.message),
        ),
      AlbumRow() => AlbumMessageBubble(
          key: ValueKey('album-${row.albumId}'),
          album: row,
          showSender: !row.messages.first.isOutgoing,
          onLongPress: (m) => _showMessageOptions(context, m),
        ),
    };

    final core = Column(
      children: [
        if (showDateSeparator) DateSeparator(date: row.oldest.date),
        bubble,
      ],
    );

    if (!shouldAnimate) return core;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: motionDurationFor(context, kAppearanceTransitionDuration),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 8),
            child: child,
          ),
        );
      },
      child: core,
    );
  }

  Widget _buildLoadingState() {
    return const LoadingStateWidget(message: 'Loading messages...');
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.chat_bubble_outline,
      title: 'No messages yet',
      subtitle: 'Start the conversation by sending a message',
    );
  }

  Widget _buildErrorState(String error) {
    return ErrorStateWidget(
      title: 'Failed to load messages',
      error: error,
      onRetry: _refreshMessages,
      useErrorColor: true,
    );
  }

  Widget _buildLoadingMoreIndicator() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading more messages...',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollToBottomButton() {
    final colorScheme = Theme.of(context).colorScheme;

    return FloatingActionButton.small(
      key: const ValueKey('scroll-to-bottom'),
      onPressed: () => _scrollToBottom(),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      child: const Icon(Icons.keyboard_arrow_down),
    );
  }

  bool _shouldShowDateSeparator(List<MessageRow> rows, int index) {
    // In reversed list: index 0 = newest (bottom), higher index = older (top).
    // Show a separator when this row's *oldest* message starts a new day
    // compared to the *newest* message of the next-older row.
    if (index == rows.length - 1) {
      return true; // Always show for the oldest row
    }

    final currentDate = rows[index].oldest.date;
    final nextOlderDate = rows[index + 1].newest.date;

    final currentDay = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    final nextOlderDay = DateTime(
      nextOlderDate.year,
      nextOlderDate.month,
      nextOlderDate.day,
    );

    return currentDay != nextOlderDay;
  }

  Future<void> _refreshMessages() async {
    await ref
        .read(messageProvider.notifier)
        .loadMessages(widget.chat.id, forceRefresh: true);
  }

  void _showMessageOptions(BuildContext context, Message message) {
    // Fetch available reactions
    final reactionsFuture = ref
        .read(telegramClientProvider)
        .getAvailableReactions(widget.chat.id, message.id);

    final outerContext = context;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reaction bar at top
              FutureBuilder<List<String>>(
                future: reactionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ReactionBar(
                                reactions: snapshot.data!,
                                onReactionSelected: (emoji) {
                                  Navigator.pop(context);
                                  _addReaction(message, emoji);
                                },
                              ),
                            ),
                            // Expand button to show full emoji picker
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: IconButton(
                                icon: Icon(
                                  Icons.add_circle_outline,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final emoji =
                                      await ExpandedReactionPicker.show(
                                        outerContext,
                                      );
                                  if (emoji != null) {
                                    _addReaction(message, emoji);
                                  }
                                },
                                tooltip: 'More reactions',
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 1),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              if (message.sendingState == MessageSendingState.failed)
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Resend'),
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(messageProvider.notifier)
                        .resendMessage(widget.chat.id, message.id);
                  },
                ),
              if (message.isOutgoing && message.type == MessageType.text)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(messageProvider.notifier).startEditing(message);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(messageProvider.notifier).setReplyingTo(message);
                },
              ),
              if (message.content.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Copy'),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: message.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.forward),
                title: const Text('Forward'),
                onTap: () {
                  Navigator.pop(context);
                  _showForwardSheet(message);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteMessage(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(messageProvider.notifier)
                  .deleteMessage(widget.chat.id, message.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showForwardSheet(Message message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ChatPickerSheet(
        excludeChatId: widget.chat.id,
        onChatSelected: (targetChat) {
          ref
              .read(messageProvider.notifier)
              .forwardMessage(widget.chat.id, targetChat.id, message.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Message forwarded to ${targetChat.title}'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _addReaction(Message message, String emoji) {
    final reaction = MessageReaction(
      type: ReactionType.emoji,
      emoji: emoji,
      count: 0,
      isChosen: false,
    );
    ref
        .read(telegramClientProvider)
        .addReaction(widget.chat.id, message.id, reaction);
  }
}
