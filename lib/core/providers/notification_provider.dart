import 'package:flutter/foundation.dart';

/// 앱 전역 알림 상태를 관리하는 Provider
/// 메시지 알림, 읽지 않은 메시지 수 등을 추적
class NotificationProvider extends ChangeNotifier {
  // 읽지 않은 메시지 수
  int _unreadMessageCount = 0;

  // 읽지 않은 홈 알림 수
  int _unreadHomeCount = 0;

  // 최근 알림 메시지 (스낵바/토스트용)
  String? _latestNotification;

  // 새 메시지 도착 플래그 (애니메이션 트리거용)
  bool _hasNewMessage = false;

  // Getters
  int get unreadMessageCount => _unreadMessageCount;
  int get unreadHomeCount => _unreadHomeCount;
  String? get latestNotification => _latestNotification;
  bool get hasNewMessage => _hasNewMessage;

  /// 총 읽지 않은 알림 수
  int get totalUnreadCount => _unreadMessageCount + _unreadHomeCount;

  /// 메시지 알림 수 설정
  void setUnreadMessageCount(int count) {
    if (_unreadMessageCount != count) {
      final wasLower = count > _unreadMessageCount;
      _unreadMessageCount = count;
      if (wasLower && count > 0) {
        _hasNewMessage = true;
      }
      notifyListeners();
    }
  }

  /// 메시지 알림 수 증가
  void incrementMessageCount([int amount = 1]) {
    _unreadMessageCount += amount;
    _hasNewMessage = true;
    notifyListeners();
  }

  /// 메시지 알림 수 감소
  void decrementMessageCount([int amount = 1]) {
    _unreadMessageCount = (_unreadMessageCount - amount).clamp(0, 9999);
    notifyListeners();
  }

  /// 메시지 알림 초기화
  void clearMessageCount() {
    _unreadMessageCount = 0;
    _hasNewMessage = false;
    notifyListeners();
  }

  /// 홈 알림 수 설정
  void setUnreadHomeCount(int count) {
    if (_unreadHomeCount != count) {
      _unreadHomeCount = count;
      notifyListeners();
    }
  }

  /// 홈 알림 초기화
  void clearHomeCount() {
    _unreadHomeCount = 0;
    notifyListeners();
  }

  /// 새 메시지 플래그 초기화 (애니메이션 완료 후 호출)
  void clearNewMessageFlag() {
    _hasNewMessage = false;
    notifyListeners();
  }

  /// 최근 알림 설정 (토스트/스낵바 표시용)
  void setLatestNotification(String message) {
    _latestNotification = message;
    notifyListeners();
  }

  /// 최근 알림 초기화
  void clearLatestNotification() {
    _latestNotification = null;
    notifyListeners();
  }

  /// 새 메시지 도착 시뮬레이션 (데모/테스트용)
  void simulateNewMessage({
    String artistName = '아이유',
    String preview = '새로운 메시지가 도착했어요!',
  }) {
    incrementMessageCount();
    setLatestNotification('$artistName: $preview');
  }

  /// 모든 알림 초기화
  void clearAll() {
    _unreadMessageCount = 0;
    _unreadHomeCount = 0;
    _latestNotification = null;
    _hasNewMessage = false;
    notifyListeners();
  }
}
