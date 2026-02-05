class Message {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final String? imageUrl;
  final bool isRead;

  /// 발신자가 인증된 아티스트인지 여부
  /// (아티스트가 다른 아티스트 채팅에 참여할 때 강조 표시용)
  final bool isSenderVerifiedArtist;

  /// 발신자 표시 이름 (아티스트인 경우 표시됨)
  final String? senderDisplayName;

  const Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.imageUrl,
    this.isRead = false,
    this.isSenderVerifiedArtist = false,
    this.senderDisplayName,
  });
}

enum MessageType {
  text,
  image,
  emoji,
}

class ChatThread {
  final String id;
  final String artistId;
  final String artistName;
  final String? artistEnglishName;
  final String artistAvatarUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final bool isVerified;
  final bool isPinned;
  final bool isStar;
  final List<Message> messages;

  const ChatThread({
    required this.id,
    required this.artistId,
    required this.artistName,
    this.artistEnglishName,
    required this.artistAvatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isVerified = false,
    this.isPinned = false,
    this.isStar = false,
    this.messages = const [],
  });

  String get artistDisplayName =>
      artistEnglishName != null ? '$artistName ($artistEnglishName)' : artistName;

  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(lastMessageTime);

    if (diff.inMinutes < 1) {
      return '방금';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inDays < 1) {
      final hour = lastMessageTime.hour;
      final minute = lastMessageTime.minute.toString().padLeft(2, '0');
      final period = hour < 12 ? '오전' : '오후';
      final displayHour = hour > 12 ? hour - 12 : hour;
      return '$period $displayHour:$minute';
    } else if (diff.inDays == 1) {
      return '어제';
    } else {
      return '${lastMessageTime.month}/${lastMessageTime.day}';
    }
  }
}
