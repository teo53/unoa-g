import 'package:flutter/material.dart';

/// UNO A Design Tokens — Spacing & Radius
///
/// 하드코딩된 spacing/radius 값을 중앙화하여 일관성 확보.
/// 값은 기존 코드에서 가장 빈번하게 사용되는 값 기반.

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;

  /// 화면 좌우 기본 패딩 (24px)
  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: 24.0);

  /// 섹션 간 간격 (24px)
  static const double sectionGap = 24.0;

  /// 카드 간 간격 (12px)
  static const double cardGap = 12.0;
}

/// Canonical AppRadius — 모든 코드가 이 클래스를 사용합니다.
/// (app_radius.dart의 KRDS 참조값은 설계 문서 전용)
class AppRadius {
  AppRadius._();

  static const double xs = 4.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double base = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;

  static BorderRadius get xsBR => BorderRadius.circular(xs);
  static BorderRadius get smBR => BorderRadius.circular(sm);
  static BorderRadius get mdBR => BorderRadius.circular(md);
  static BorderRadius get baseBR => BorderRadius.circular(base);
  static BorderRadius get lgBR => BorderRadius.circular(lg);
  static BorderRadius get xlBR => BorderRadius.circular(xl);
  static BorderRadius get xxlBR => BorderRadius.circular(xxl);
  static BorderRadius get fullBR => BorderRadius.circular(full);
}
