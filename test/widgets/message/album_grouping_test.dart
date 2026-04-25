import 'package:flutter_test/flutter_test.dart';
import 'package:telega2/domain/entities/chat.dart';
import 'package:telega2/widgets/message/album_grouping.dart';

Message _msg({
  required int id,
  required int senderId,
  required DateTime date,
  int chatId = 1,
  int? mediaAlbumId,
  bool isOutgoing = false,
  MessageType type = MessageType.photo,
  String content = '',
}) {
  return Message(
    id: id,
    chatId: chatId,
    senderId: senderId,
    date: date,
    content: content,
    isOutgoing: isOutgoing,
    type: type,
    mediaAlbumId: mediaAlbumId,
  );
}

/// Build a *newest-first* list (matching state ordering): pass messages in
/// the order they were sent and the helper reverses them.
List<Message> _newestFirst(List<Message> sentInOrder) =>
    sentInOrder.reversed.toList();

void main() {
  final base = DateTime(2026, 4, 25, 12, 0);
  DateTime t(int seconds) => base.add(Duration(seconds: seconds));

  group('groupAlbums', () {
    test('three messages with same album_id → one AlbumRow', () {
      final input = _newestFirst([
        _msg(id: 1, senderId: 100, date: t(0), mediaAlbumId: 42),
        _msg(id: 2, senderId: 100, date: t(1), mediaAlbumId: 42),
        _msg(id: 3, senderId: 100, date: t(2), mediaAlbumId: 42),
      ]);
      final rows = groupAlbums(input);
      expect(rows.length, 1);
      expect(rows.first, isA<AlbumRow>());
      final album = rows.first as AlbumRow;
      expect(album.messages.map((m) => m.id), [1, 2, 3]);
      expect(album.albumId, 42);
    });

    test('different album_ids → separate rows', () {
      final input = _newestFirst([
        _msg(id: 1, senderId: 100, date: t(0), mediaAlbumId: 11),
        _msg(id: 2, senderId: 100, date: t(1), mediaAlbumId: 22),
        _msg(id: 3, senderId: 100, date: t(2), mediaAlbumId: 33),
      ]);
      final rows = groupAlbums(input);
      expect(rows.length, 3);
      expect(rows.every((r) => r is SingleMessageRow), isTrue);
    });

    test('mixed null and non-null album ids', () {
      final input = _newestFirst([
        _msg(id: 1, senderId: 100, date: t(0)), // standalone
        _msg(id: 2, senderId: 100, date: t(1), mediaAlbumId: 99),
        _msg(id: 3, senderId: 100, date: t(2), mediaAlbumId: 99),
        _msg(id: 4, senderId: 100, date: t(3)), // standalone
      ]);
      final rows = groupAlbums(input);
      // Newest-first order: [single 4, album(2,3), single 1]
      expect(rows.length, 3);
      expect(rows[0], isA<SingleMessageRow>());
      expect((rows[0] as SingleMessageRow).message.id, 4);
      expect(rows[1], isA<AlbumRow>());
      expect((rows[1] as AlbumRow).messages.map((m) => m.id), [2, 3]);
      expect(rows[2], isA<SingleMessageRow>());
      expect((rows[2] as SingleMessageRow).message.id, 1);
    });

    test('different senders → not grouped', () {
      final input = _newestFirst([
        _msg(id: 1, senderId: 100, date: t(0), mediaAlbumId: 7),
        _msg(id: 2, senderId: 200, date: t(1), mediaAlbumId: 7),
      ]);
      final rows = groupAlbums(input);
      expect(rows.length, 2);
      expect(rows.every((r) => r is SingleMessageRow), isTrue);
    });

    test('different direction → not grouped', () {
      final input = _newestFirst([
        _msg(
          id: 1,
          senderId: 100,
          date: t(0),
          mediaAlbumId: 7,
          isOutgoing: false,
        ),
        _msg(
          id: 2,
          senderId: 100,
          date: t(1),
          mediaAlbumId: 7,
          isOutgoing: true,
        ),
      ]);
      final rows = groupAlbums(input);
      expect(rows.length, 2);
    });

    test('cap at 10 — twelfth message starts a new run', () {
      final messages = [
        for (var i = 1; i <= 12; i++)
          _msg(id: i, senderId: 100, date: t(i), mediaAlbumId: 50),
      ];
      final input = _newestFirst(messages);
      final rows = groupAlbums(input);
      // First 10 form one album, remaining 2 form another album.
      expect(rows.length, 2);
      // Newest-first ordering: 2-message album (ids 11,12) is newest.
      expect(rows[0], isA<AlbumRow>());
      expect((rows[0] as AlbumRow).messages.map((m) => m.id), [11, 12]);
      expect(rows[1], isA<AlbumRow>());
      expect((rows[1] as AlbumRow).messages.length, 10);
      expect((rows[1] as AlbumRow).messages.first.id, 1);
      expect((rows[1] as AlbumRow).messages.last.id, 10);
    });

    test('mediaAlbumId == null → standalone, not albumed even alone', () {
      final input = _newestFirst([
        _msg(id: 1, senderId: 100, date: t(0)),
      ]);
      final rows = groupAlbums(input);
      expect(rows.length, 1);
      expect(rows.first, isA<SingleMessageRow>());
    });

    test('lone message with album_id renders as SingleMessageRow', () {
      // A defensive case: a sole message bearing an album_id must not crash
      // the grouping (no degenerate 1-item AlbumRow).
      final input = _newestFirst([
        _msg(id: 1, senderId: 100, date: t(0), mediaAlbumId: 7),
      ]);
      final rows = groupAlbums(input);
      expect(rows.length, 1);
      expect(rows.first, isA<SingleMessageRow>());
    });

    test('empty input → empty output', () {
      expect(groupAlbums(const []), isEmpty);
    });

    test('different chatIds with same album_id → not grouped', () {
      final input = _newestFirst([
        _msg(id: 1, chatId: 1, senderId: 100, date: t(0), mediaAlbumId: 8),
        _msg(id: 2, chatId: 2, senderId: 100, date: t(1), mediaAlbumId: 8),
      ]);
      final rows = groupAlbums(input);
      expect(rows.length, 2);
    });

    test('span midnight: same album, different days → not grouped', () {
      final lateNight = DateTime(2026, 4, 25, 23, 59, 30);
      final justAfterMidnight = DateTime(2026, 4, 26, 0, 0, 5);
      final input = _newestFirst([
        _msg(
          id: 1,
          senderId: 100,
          date: lateNight,
          mediaAlbumId: 7,
        ),
        _msg(
          id: 2,
          senderId: 100,
          date: justAfterMidnight,
          mediaAlbumId: 7,
        ),
      ]);
      final rows = groupAlbums(input);
      expect(rows.length, 2);
    });
  });
}
