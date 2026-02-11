import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Sentry 모니터링 서비스
///
/// 에러 추적, 성능 모니터링, 사용자 피드백을 위한 중앙 서비스
class SentryService {
  SentryService._();

  static bool _initialized = false;

  /// Sentry DSN (환경변수 또는 빌드 설정에서 가져옴)
  static String? get _dsn => const String.fromEnvironment(
        'SENTRY_DSN',
        defaultValue: '',
      );

  /// 현재 환경
  static String get _environment => const String.fromEnvironment(
        'ENV',
        defaultValue: 'development',
      );

  /// Sentry 초기화
  /// 프로덕션 환경에서는 DSN이 반드시 설정되어야 합니다.
  static Future<void> initialize() async {
    if (_initialized) return;

    final dsn = _dsn;
    if (dsn == null || dsn.isEmpty) {
      if (_environment == 'production') {
        throw StateError(
          '[Sentry] DSN is required in production. '
          'Set --dart-define=SENTRY_DSN=your-dsn',
        );
      }
      if (kDebugMode) {
        debugPrint('[Sentry] DSN not configured, skipping initialization');
      }
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.environment = _environment;

        // 성능 모니터링 설정
        options.tracesSampleRate = _environment == 'production' ? 0.2 : 1.0;
        options.profilesSampleRate = _environment == 'production' ? 0.1 : 0.5;

        // 디버그 모드에서 더 많은 정보 수집
        options.debug = kDebugMode;
        options.diagnosticLevel =
            kDebugMode ? SentryLevel.debug : SentryLevel.warning;

        // 스크린샷 및 뷰 계층 첨부 (에러 발생 시)
        options.attachScreenshot = true;
        options.attachViewHierarchy = true;

        // 민감한 데이터 필터링
        options.beforeSend = _beforeSend;
        options.beforeBreadcrumb = _beforeBreadcrumb;

        // 자동 세션 추적
        options.autoSessionTrackingInterval = const Duration(seconds: 30);

        // 앱 행 탐지
        options.anrEnabled = true;
        options.anrTimeoutInterval = const Duration(seconds: 5);
      },
    );

    _initialized = true;
    if (kDebugMode) {
      debugPrint('[Sentry] Initialized for environment: $_environment');
    }
  }

  /// 에러 전송 전 민감 정보 필터링
  static SentryEvent? _beforeSend(SentryEvent event, Hint hint) {
    // 개발 환경에서는 모든 이벤트 전송
    if (_environment == 'development') {
      return event;
    }

    // 민감한 정보가 포함된 예외 필터링
    final message = event.throwable?.toString() ?? '';
    if (_containsSensitiveData(message)) {
      return event.copyWith(
        throwable: Exception('[FILTERED] Sensitive data removed'),
      );
    }

    return event;
  }

  /// Breadcrumb 필터링
  static Breadcrumb? _beforeBreadcrumb(Breadcrumb? breadcrumb, Hint hint) {
    if (breadcrumb == null) return null;

    // HTTP 요청에서 민감 정보 제거
    if (breadcrumb.category == 'http') {
      final data = Map<String, dynamic>.from(breadcrumb.data ?? {});
      data.remove('headers'); // 헤더에 토큰이 있을 수 있음
      data.remove('request_body'); // 요청 본문에 민감 정보 가능
      data.remove('response_body'); // 응답 본문에 민감 정보 가능
      data.remove('request_body_size');
      data.remove('response_body_size');
      return breadcrumb.copyWith(data: data);
    }

    return breadcrumb;
  }

  /// 민감한 데이터 포함 여부 확인
  static bool _containsSensitiveData(String text) {
    final lowerText = text.toLowerCase();
    const sensitiveKeywords = [
      'password',
      'token',
      'secret',
      'api_key',
      'apikey',
      'credit_card',
      'ssn',
      '주민등록',
      '계좌번호',
    ];
    return sensitiveKeywords.any((keyword) => lowerText.contains(keyword));
  }

  /// 사용자 정보 설정
  static Future<void> setUser({
    required String id,
    String? email,
    String? username,
    Map<String, String>? extras,
  }) async {
    if (!_initialized) return;

    await Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: id,
        email: email,
        username: username,
        data: extras,
      ));
    });
  }

  /// 사용자 정보 초기화 (로그아웃 시)
  static Future<void> clearUser() async {
    if (!_initialized) return;

    await Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  /// 태그 설정
  static Future<void> setTag(String key, String value) async {
    if (!_initialized) return;

    await Sentry.configureScope((scope) {
      scope.setTag(key, value);
    });
  }

  /// 컨텍스트 설정
  static Future<void> setContext(String key, Map<String, dynamic> value) async {
    if (!_initialized) return;

    await Sentry.configureScope((scope) {
      scope.setContexts(key, value);
    });
  }

  /// 예외 캡처
  static Future<SentryId> captureException(
    dynamic exception, {
    dynamic stackTrace,
    String? message,
    Map<String, dynamic>? extras,
    SentryLevel? level,
  }) async {
    if (!_initialized) {
      debugPrint('[Sentry] Not initialized, logging locally: $exception');
      return const SentryId.empty();
    }

    return await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (message != null) {
          scope.setContexts('message', {'text': message});
        }
        if (extras != null) {
          scope.setContexts('extras', extras);
        }
        if (level != null) {
          scope.level = level;
        }
      },
    );
  }

  /// 메시지 캡처
  static Future<SentryId> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extras,
  }) async {
    if (!_initialized) {
      debugPrint('[Sentry] Not initialized, logging locally: $message');
      return const SentryId.empty();
    }

    return await Sentry.captureMessage(
      message,
      level: level,
      withScope: extras != null
          ? (scope) => scope.setContexts('extras', extras)
          : null,
    );
  }

  /// Breadcrumb 추가
  static Future<void> addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
    SentryLevel level = SentryLevel.info,
  }) async {
    if (!_initialized) return;

    await Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      category: category,
      data: data,
      level: level,
      timestamp: DateTime.now(),
    ));
  }

  /// 트랜잭션 시작 (성능 모니터링)
  static ISentrySpan? startTransaction({
    required String name,
    required String operation,
    String? description,
  }) {
    if (!_initialized) return null;

    return Sentry.startTransaction(
      name,
      operation,
      description: description,
      bindToScope: true,
    );
  }

  /// 사용자 피드백 수집
  static Future<void> captureUserFeedback({
    required SentryId eventId,
    required String email,
    required String comments,
    String? name,
  }) async {
    if (!_initialized || eventId == const SentryId.empty()) return;

    await Sentry.captureFeedback(SentryFeedback(
      message: comments,
      contactEmail: email,
      name: name,
      associatedEventId: eventId,
    ));
  }

  /// 네비게이션 관찰자 (go_router용)
  static SentryNavigatorObserver get navigatorObserver {
    return SentryNavigatorObserver(
      setRouteNameAsTransaction: true,
    );
  }
}

/// Sentry 에러 핸들링을 위한 확장
extension SentryErrorHandling on Object {
  /// 에러를 Sentry에 보고하고 로컬에도 로깅
  Future<void> reportToSentry({
    dynamic stackTrace,
    String? message,
    Map<String, dynamic>? extras,
  }) async {
    debugPrint('[Error] $this');
    if (stackTrace != null) {
      debugPrint('[StackTrace] $stackTrace');
    }

    await SentryService.captureException(
      this,
      stackTrace: stackTrace,
      message: message,
      extras: extras,
    );
  }
}
