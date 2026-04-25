import 'package:flutter_test/flutter_test.dart';
import 'package:telega2/domain/entities/chat.dart';

Map<String, dynamic> _baseMessageJson({Object? mediaAlbumId}) {
  return {
    'id': 1,
    'chat_id': 100,
    'sender_id': {'@type': 'messageSenderUser', 'user_id': 200},
    'date': 1719340800,
    'is_outgoing': false,
    'content': {'@type': 'messageText', 'text': {'text': 'hi'}},
    'media_album_id': ?mediaAlbumId,
  };
}

void main() {
  group('Message.fromJson media_album_id parsing', () {
    test('absent → null', () {
      final m = Message.fromJson(_baseMessageJson());
      expect(m.mediaAlbumId, isNull);
    });

    test('string-encoded int64 → parsed', () {
      final m = Message.fromJson(
        _baseMessageJson(mediaAlbumId: '12345678901234567'),
      );
      expect(m.mediaAlbumId, 12345678901234567);
    });

    test('plain int → parsed', () {
      final m = Message.fromJson(_baseMessageJson(mediaAlbumId: 42));
      expect(m.mediaAlbumId, 42);
    });

    test('zero (int) treated as absent', () {
      final m = Message.fromJson(_baseMessageJson(mediaAlbumId: 0));
      expect(m.mediaAlbumId, isNull);
    });

    test('zero (string) treated as absent', () {
      final m = Message.fromJson(_baseMessageJson(mediaAlbumId: '0'));
      expect(m.mediaAlbumId, isNull);
    });

    test('garbage string → null (parse-tolerant)', () {
      final m = Message.fromJson(_baseMessageJson(mediaAlbumId: 'not-a-num'));
      expect(m.mediaAlbumId, isNull);
    });
  });

  group('Message.copyWith mediaAlbumId', () {
    test('threads the value through', () {
      final m = Message(
        id: 1,
        chatId: 1,
        senderId: 1,
        date: DateTime(2026, 4, 25),
        content: '',
        isOutgoing: false,
        type: MessageType.photo,
      );
      expect(m.mediaAlbumId, isNull);
      final copied = m.copyWith(mediaAlbumId: 99);
      expect(copied.mediaAlbumId, 99);
    });

    test('preserves an existing value when not overridden', () {
      final m = Message(
        id: 1,
        chatId: 1,
        senderId: 1,
        date: DateTime(2026, 4, 25),
        content: '',
        isOutgoing: false,
        type: MessageType.photo,
        mediaAlbumId: 7,
      );
      final copied = m.copyWith(content: 'caption');
      expect(copied.mediaAlbumId, 7);
      expect(copied.content, 'caption');
    });
  });
}
