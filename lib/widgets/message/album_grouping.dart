import '../../domain/entities/chat.dart';

/// A row in the rendered message list — either a single standalone message or
/// a grouped album of 2+ messages that share a TDLib `media_album_id`.
sealed class MessageRow {
  const MessageRow();

  /// The newest message in the row. Used for keying and for the "latest" date
  /// when deciding date separators between rows.
  Message get newest;

  /// The oldest message in the row. Used for date-separator comparison against
  /// the next-older row.
  Message get oldest;
}

class SingleMessageRow extends MessageRow {
  final Message message;
  const SingleMessageRow(this.message);

  @override
  Message get newest => message;

  @override
  Message get oldest => message;
}

class AlbumRow extends MessageRow {
  /// 2..10 messages, sorted oldest → newest so the grid reads in send order
  /// (top-left → bottom-right).
  final List<Message> messages;

  AlbumRow(this.messages)
      : assert(messages.length >= 2),
        assert(messages.length <= 10),
        assert(messages.first.mediaAlbumId != null);

  int get albumId => messages.first.mediaAlbumId!;

  @override
  Message get newest => messages.last;

  @override
  Message get oldest => messages.first;
}

/// Maximum number of items Telegram packs into a single album. Defensive cap —
/// runs longer than this are split into multiple albums.
const int kMaxAlbumSize = 10;

/// Groups consecutive same-album messages into [AlbumRow]s. Input must be the
/// chat's existing newest-first message list (as stored in
/// `MessageState.messagesByChat`); output preserves that newest-first ordering
/// at the row level. Within an [AlbumRow] messages are sorted oldest → newest.
///
/// Two adjacent messages join the same album iff:
///   - both have a non-null `mediaAlbumId` and they're equal,
///   - same `chatId`,
///   - same `senderId` (defensive — Telegram albums are always single-sender),
///   - same `isOutgoing`,
///   - same calendar day (so a date separator never splits a run).
///
/// A run shorter than 2 emits a [SingleMessageRow]; a run hitting
/// [kMaxAlbumSize] flushes and starts a new run.
List<MessageRow> groupAlbums(List<Message> messages) {
  if (messages.isEmpty) return const [];

  final rows = <MessageRow>[];
  // Walk oldest → newest so runs build naturally; reverse the row list at the
  // end to restore newest-first.
  final ascending = messages.reversed.toList();

  var runStart = 0;
  for (var i = 1; i <= ascending.length; i++) {
    final atEnd = i == ascending.length;
    final current = atEnd ? null : ascending[i];
    final prev = ascending[i - 1];

    final canJoin = !atEnd &&
        prev.mediaAlbumId != null &&
        current!.mediaAlbumId != null &&
        prev.mediaAlbumId == current.mediaAlbumId &&
        prev.chatId == current.chatId &&
        prev.senderId == current.senderId &&
        prev.isOutgoing == current.isOutgoing &&
        _sameCalendarDay(prev.date, current.date) &&
        (i - runStart) < kMaxAlbumSize;

    if (canJoin) continue;

    final runLength = i - runStart;
    final run = ascending.sublist(runStart, i);
    if (runLength >= 2 && run.first.mediaAlbumId != null) {
      rows.add(AlbumRow(run));
    } else {
      for (final m in run) {
        rows.add(SingleMessageRow(m));
      }
    }
    runStart = i;
  }

  return rows.reversed.toList(growable: false);
}

bool _sameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
