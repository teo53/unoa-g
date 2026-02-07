/// Renders celebration templates by replacing variable placeholders.
///
/// Supported variables:
///   {nickname}     — Fan display name
///   {day_count}    — Subscription day count
///   {artist_name}  — Artist/creator name
class TemplateRenderer {
  TemplateRenderer._();

  /// Render a template string with the given variables.
  ///
  /// Unknown variables are left as-is.
  static String render(
    String template, {
    String? nickname,
    int? dayCount,
    String? artistName,
  }) {
    var result = template;

    if (nickname != null) {
      result = result.replaceAll('{nickname}', nickname);
    }
    if (dayCount != null) {
      result = result.replaceAll('{day_count}', dayCount.toString());
    }
    if (artistName != null) {
      result = result.replaceAll('{artist_name}', artistName);
    }

    return result;
  }

  /// Render a template with a variable map.
  static String renderMap(String template, Map<String, String> variables) {
    var result = template;
    for (final entry in variables.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  /// Preview a template with sample data (for template selection UI).
  static String preview(String template) {
    return render(
      template,
      nickname: '팬닉네임',
      dayCount: 100,
      artistName: '아티스트',
    );
  }

  /// Extract variable names from a template string.
  static List<String> extractVariables(String template) {
    final regex = RegExp(r'\{(\w+)\}');
    return regex.allMatches(template).map((m) => m.group(1)!).toList();
  }
}
