# 09. 구현 계획 (Implementation Plan)

> Phase 0/1 범위의 구체적인 코드 변경 계획

---

## 1. Phase 0 구현 (즉시, 1-2일)

### P0-1: 암호화 키 Fallback 제거

**파일**: `supabase/migrations/015_fix_encryption_key_security.sql` (신규)

```sql
-- Migration: 015_fix_encryption_key_security.sql
-- Purpose: Remove hardcoded fallback encryption key for security

-- Drop the existing function
DROP FUNCTION IF EXISTS get_encryption_key();

-- Create a secure version that fails fast without proper configuration
CREATE OR REPLACE FUNCTION get_encryption_key()
RETURNS TEXT AS $$
DECLARE
  key TEXT;
BEGIN
  -- Try to get the key from PostgreSQL settings
  key := current_setting('app.encryption_key', true);

  -- Fail fast if not configured
  IF key IS NULL OR key = '' THEN
    RAISE EXCEPTION
      'SECURITY ERROR: Encryption key not configured. '
      'Set app.encryption_key in your Supabase project settings or via: '
      'ALTER SYSTEM SET app.encryption_key = ''your-32-byte-secure-key''; '
      'SELECT pg_reload_conf();';
  END IF;

  -- Validate key length (32 bytes for AES-256)
  IF length(key) < 32 THEN
    RAISE EXCEPTION
      'SECURITY ERROR: Encryption key must be at least 32 bytes. '
      'Current length: %', length(key);
  END IF;

  RETURN key;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Also update decrypt function to handle missing key gracefully
CREATE OR REPLACE FUNCTION decrypt_sensitive_data(encrypted_data BYTEA)
RETURNS TEXT AS $$
BEGIN
  IF encrypted_data IS NULL THEN
    RETURN NULL;
  END IF;

  RETURN pgp_sym_decrypt(
    encrypted_data,
    get_encryption_key()
  )::TEXT;
EXCEPTION
  WHEN OTHERS THEN
    -- Log the error but don't expose details
    RAISE WARNING 'Decryption failed: %', SQLERRM;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Add comment for documentation
COMMENT ON FUNCTION get_encryption_key() IS
  'Returns the AES-256 encryption key from PostgreSQL settings. '
  'CRITICAL: Must be configured in production via app.encryption_key setting.';
```

**배포 순서**:
1. 프로덕션 환경에서 `app.encryption_key` 먼저 설정
2. 마이그레이션 실행
3. 기존 암호화된 데이터 복호화 테스트

**롤백 방법**:
```sql
-- Rollback if needed
DROP FUNCTION IF EXISTS get_encryption_key();
-- Restore previous version from backup
```

---

### P0-2: 감사로그 INSERT 정책 수정

**파일**: `supabase/migrations/016_fix_audit_log_policy.sql` (신규)

```sql
-- Migration: 016_fix_audit_log_policy.sql
-- Purpose: Fix overly permissive INSERT policy on admin_audit_log

-- Drop the insecure policy
DROP POLICY IF EXISTS "admin_audit_insert" ON admin_audit_log;

-- Create a secure policy that only allows:
-- 1. service_role (for backend operations)
-- 2. authenticated admins
CREATE POLICY "admin_audit_insert_secure" ON admin_audit_log
  FOR INSERT
  WITH CHECK (
    -- Service role can always insert (backend operations)
    auth.jwt()->>'role' = 'service_role'
    OR
    -- Authenticated admins can insert
    (
      auth.uid() IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM user_profiles
        WHERE id = auth.uid()
        AND role = 'admin'
      )
    )
  );

-- Add a function for programmatic audit logging
CREATE OR REPLACE FUNCTION log_admin_action(
  p_action TEXT,
  p_target_type TEXT DEFAULT NULL,
  p_target_id UUID DEFAULT NULL,
  p_details JSONB DEFAULT '{}'::JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER  -- Runs with elevated privileges
SET search_path = public
AS $$
DECLARE
  v_log_id UUID;
  v_user_id UUID;
BEGIN
  -- Get the current user (or null for service_role)
  v_user_id := auth.uid();

  -- Validate that the caller is authorized
  IF v_user_id IS NULL AND auth.jwt()->>'role' != 'service_role' THEN
    RAISE EXCEPTION 'Unauthorized: Must be authenticated or service_role';
  END IF;

  -- If user is authenticated, verify they are an admin
  IF v_user_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = v_user_id AND role = 'admin'
    ) THEN
      RAISE EXCEPTION 'Unauthorized: User is not an admin';
    END IF;
  END IF;

  -- Insert the audit log entry
  INSERT INTO admin_audit_log (
    admin_user_id,
    action,
    target_type,
    target_id,
    details,
    created_at
  ) VALUES (
    v_user_id,
    p_action,
    p_target_type,
    p_target_id,
    p_details,
    NOW()
  ) RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$;

-- Grant execute permission to authenticated users
-- (the function itself validates admin status)
GRANT EXECUTE ON FUNCTION log_admin_action TO authenticated;

COMMENT ON FUNCTION log_admin_action IS
  'Securely logs admin actions. Only admins and service_role can execute. '
  'Use this function instead of direct INSERT for audit logging.';
```

**테스트**:
```sql
-- Test 1: Regular user cannot insert directly
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims = '{"sub": "non-admin-user-id"}';
INSERT INTO admin_audit_log (action, details)
VALUES ('test', '{}');  -- Should fail

-- Test 2: Admin can use the function
SET LOCAL request.jwt.claims = '{"sub": "admin-user-id"}';
SELECT log_admin_action('test_action', 'user', 'some-uuid', '{"test": true}');
-- Should succeed
```

---

### P0-3: Service Role Key 사용처 감사

**체크리스트 및 발견 사항**:

```typescript
// apps/web/lib/supabase/server.ts
// 현재 사용처:

export async function createAdminClient() {
  // ⚠️ 이 함수는 service_role_key를 사용
  // 사용처 감사 필요
}

// 사용되는 위치:
// 1. (admin)/admin/* - ✅ 어드민 전용, 적절함
// 2. (studio)/studio/* - ⚠️ 크리에이터 스튜디오, 검토 필요
// 3. API routes - 확인 필요
```

**권장 수정사항**:

```typescript
// apps/web/lib/supabase/server.ts

// AS-IS
export async function createAdminClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { ... }
  );
}

// TO-BE: 명시적인 사용처 제한
export async function createAdminClient(context: AdminClientContext) {
  // 허용된 컨텍스트만 사용 가능
  const allowedContexts = ['admin_dashboard', 'payment_webhook', 'payout_process'];

  if (!allowedContexts.includes(context)) {
    console.warn(`Unexpected admin client usage: ${context}`);
    // In production, could throw or alert
  }

  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { ... }
  );
}

type AdminClientContext =
  | 'admin_dashboard'
  | 'payment_webhook'
  | 'payout_process'
  | 'audit_log';
```

---

## 2. Phase 1-A: 채팅 편집/삭제/신고/차단

### P1-A1: 메시지 편집 API

**파일**: `supabase/functions/message-edit/index.ts` (신규)

```typescript
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      throw new Error("Missing authorization header");
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      throw new Error("Unauthorized");
    }

    const { messageId, newContent } = await req.json();

    // Validate input
    if (!messageId || !newContent || newContent.trim().length === 0) {
      throw new Error("Invalid input: messageId and newContent required");
    }

    // Get the message
    const { data: message, error: fetchError } = await supabase
      .from("messages")
      .select("*")
      .eq("id", messageId)
      .single();

    if (fetchError || !message) {
      throw new Error("Message not found");
    }

    // Check ownership
    if (message.sender_id !== user.id) {
      throw new Error("Forbidden: Can only edit own messages");
    }

    // Check if message can be edited (within 24 hours)
    const createdAt = new Date(message.created_at);
    const now = new Date();
    const hoursSinceCreation = (now.getTime() - createdAt.getTime()) / (1000 * 60 * 60);

    if (hoursSinceCreation > 24) {
      throw new Error("Cannot edit messages older than 24 hours");
    }

    // Build edit history
    const editHistory = message.edit_history || [];
    editHistory.push({
      content: message.content,
      edited_at: now.toISOString(),
    });

    // Update the message
    const { data: updated, error: updateError } = await supabase
      .from("messages")
      .update({
        content: newContent.trim(),
        is_edited: true,
        last_edited_at: now.toISOString(),
        edit_history: editHistory,
      })
      .eq("id", messageId)
      .select()
      .single();

    if (updateError) {
      throw updateError;
    }

    return new Response(
      JSON.stringify({ success: true, message: updated }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
```

### P1-A2: 메시지 편집 UI (Flutter)

**파일**: `lib/features/chat/widgets/message_edit_dialog.dart` (신규)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/broadcast_message.dart';
import '../../../core/theme/app_colors.dart';

class MessageEditDialog extends ConsumerStatefulWidget {
  final BroadcastMessage message;
  final Function(String) onSave;

  const MessageEditDialog({
    super.key,
    required this.message,
    required this.onSave,
  });

  @override
  ConsumerState<MessageEditDialog> createState() => _MessageEditDialogState();
}

class _MessageEditDialogState extends ConsumerState<MessageEditDialog> {
  late TextEditingController _controller;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.message.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canEdit {
    final createdAt = widget.message.createdAt;
    final hoursSinceCreation =
        DateTime.now().difference(createdAt).inHours;
    return hoursSinceCreation < 24;
  }

  Future<void> _save() async {
    if (_controller.text.trim().isEmpty) {
      setState(() => _errorMessage = '메시지를 입력해주세요');
      return;
    }

    if (_controller.text.trim() == widget.message.content) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.onSave(_controller.text.trim());
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = '편집에 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('메시지 편집'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_canEdit)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '24시간이 지난 메시지는 편집할 수 없습니다.',
                style: TextStyle(color: AppColors.warning),
              ),
            ),
          TextField(
            controller: _controller,
            maxLines: 5,
            enabled: _canEdit && !_isLoading,
            decoration: InputDecoration(
              hintText: '메시지 내용',
              border: const OutlineInputBorder(),
              errorText: _errorMessage,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _canEdit && !_isLoading ? _save : null,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('저장'),
        ),
      ],
    );
  }
}
```

### P1-A5/A6: 신고 테이블 및 UI

**파일**: `supabase/migrations/017_add_reports_table.sql` (신규)

```sql
-- Migration: 017_add_reports_table.sql
-- Purpose: Add reports table for user reporting functionality

-- Create enum types
CREATE TYPE report_reason AS ENUM (
  'spam',
  'harassment',
  'inappropriate_content',
  'fraud',
  'copyright',
  'other'
);

CREATE TYPE report_status AS ENUM (
  'open',
  'in_progress',
  'resolved',
  'dismissed'
);

CREATE TYPE report_priority AS ENUM (
  'low',
  'medium',
  'high',
  'critical'
);

-- Create reports table
CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID REFERENCES auth.users(id) NOT NULL,

  -- What is being reported
  reported_user_id UUID REFERENCES auth.users(id),
  reported_content_id UUID,
  reported_content_type TEXT CHECK (reported_content_type IN (
    'message', 'profile', 'campaign', 'comment'
  )),

  -- Report details
  reason report_reason NOT NULL,
  description TEXT,

  -- Processing status
  status report_status DEFAULT 'open',
  priority report_priority DEFAULT 'medium',
  assigned_to UUID REFERENCES auth.users(id),

  -- Resolution
  resolution_action TEXT,
  resolution_note TEXT,
  resolved_by UUID REFERENCES auth.users(id),
  resolved_at TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Users can create reports
CREATE POLICY "users_create_reports" ON reports
  FOR INSERT
  WITH CHECK (reporter_id = auth.uid());

-- Users can view their own reports
CREATE POLICY "users_view_own_reports" ON reports
  FOR SELECT
  USING (reporter_id = auth.uid());

-- Admins can view and manage all reports
CREATE POLICY "admin_manage_reports" ON reports
  FOR ALL
  USING (
    auth.uid() IN (
      SELECT id FROM user_profiles WHERE role = 'admin'
    )
  );

-- Index for common queries
CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_reporter ON reports(reporter_id);
CREATE INDEX idx_reports_reported_user ON reports(reported_user_id);
CREATE INDEX idx_reports_created ON reports(created_at DESC);

-- Function to submit a report
CREATE OR REPLACE FUNCTION submit_report(
  p_reported_user_id UUID DEFAULT NULL,
  p_reported_content_id UUID DEFAULT NULL,
  p_reported_content_type TEXT DEFAULT NULL,
  p_reason report_reason DEFAULT 'other',
  p_description TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_report_id UUID;
BEGIN
  -- Validate that at least one target is specified
  IF p_reported_user_id IS NULL AND p_reported_content_id IS NULL THEN
    RAISE EXCEPTION 'Must specify either reported_user_id or reported_content_id';
  END IF;

  -- Check for duplicate reports (same reporter, same target, within 24 hours)
  IF EXISTS (
    SELECT 1 FROM reports
    WHERE reporter_id = auth.uid()
      AND (
        (reported_user_id = p_reported_user_id AND p_reported_user_id IS NOT NULL)
        OR
        (reported_content_id = p_reported_content_id AND p_reported_content_id IS NOT NULL)
      )
      AND created_at > NOW() - INTERVAL '24 hours'
  ) THEN
    RAISE EXCEPTION 'Already reported this content within the last 24 hours';
  END IF;

  -- Insert the report
  INSERT INTO reports (
    reporter_id,
    reported_user_id,
    reported_content_id,
    reported_content_type,
    reason,
    description
  ) VALUES (
    auth.uid(),
    p_reported_user_id,
    p_reported_content_id,
    p_reported_content_type,
    p_reason,
    p_description
  ) RETURNING id INTO v_report_id;

  RETURN v_report_id;
END;
$$;

GRANT EXECUTE ON FUNCTION submit_report TO authenticated;
```

**파일**: `lib/features/chat/widgets/report_dialog.dart` (신규)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';

enum ReportReason {
  spam('spam', '스팸'),
  harassment('harassment', '괴롭힘/폭언'),
  inappropriateContent('inappropriate_content', '부적절한 콘텐츠'),
  fraud('fraud', '사기/허위 정보'),
  copyright('copyright', '저작권 침해'),
  other('other', '기타');

  final String value;
  final String label;
  const ReportReason(this.value, this.label);
}

class ReportDialog extends ConsumerStatefulWidget {
  final String? reportedUserId;
  final String? reportedContentId;
  final String reportedContentType;
  final Function(ReportReason, String?) onSubmit;

  const ReportDialog({
    super.key,
    this.reportedUserId,
    this.reportedContentId,
    required this.reportedContentType,
    required this.onSubmit,
  });

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  ReportReason? _selectedReason;
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) {
      setState(() => _errorMessage = '신고 사유를 선택해주세요');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmit(
        _selectedReason!,
        _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('신고가 접수되었습니다. 검토 후 조치하겠습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = '신고 접수에 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('신고하기'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '신고 사유를 선택해주세요',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ...ReportReason.values.map((reason) => RadioListTile<ReportReason>(
              title: Text(reason.label),
              value: reason,
              groupValue: _selectedReason,
              onChanged: _isLoading
                  ? null
                  : (value) => setState(() => _selectedReason = value),
              contentPadding: EdgeInsets.zero,
              dense: true,
            )),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                hintText: '추가 설명 (선택)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('신고하기'),
        ),
      ],
    );
  }
}
```

### P1-A7/A8: 차단 테이블 및 UI

**파일**: `supabase/migrations/018_add_blocks_table.sql` (신규)

```sql
-- Migration: 018_add_blocks_table.sql
-- Purpose: Add user blocking functionality

CREATE TABLE user_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id UUID REFERENCES auth.users(id) NOT NULL,
  blocked_id UUID REFERENCES auth.users(id) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(blocker_id, blocked_id),
  CHECK (blocker_id != blocked_id)  -- Can't block yourself
);

-- Enable RLS
ALTER TABLE user_blocks ENABLE ROW LEVEL SECURITY;

-- Users can manage their own blocks
CREATE POLICY "users_manage_own_blocks" ON user_blocks
  FOR ALL
  USING (blocker_id = auth.uid());

-- Index for queries
CREATE INDEX idx_user_blocks_blocker ON user_blocks(blocker_id);
CREATE INDEX idx_user_blocks_blocked ON user_blocks(blocked_id);

-- Function to block a user
CREATE OR REPLACE FUNCTION block_user(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Can't block yourself
  IF p_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Cannot block yourself';
  END IF;

  -- Insert block (ignore if already exists)
  INSERT INTO user_blocks (blocker_id, blocked_id)
  VALUES (auth.uid(), p_user_id)
  ON CONFLICT (blocker_id, blocked_id) DO NOTHING;

  RETURN TRUE;
END;
$$;

-- Function to unblock a user
CREATE OR REPLACE FUNCTION unblock_user(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM user_blocks
  WHERE blocker_id = auth.uid()
    AND blocked_id = p_user_id;

  RETURN TRUE;
END;
$$;

-- Function to check if a user is blocked
CREATE OR REPLACE FUNCTION is_user_blocked(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_blocks
    WHERE blocker_id = auth.uid()
      AND blocked_id = p_user_id
  );
$$;

-- Function to get blocked user IDs
CREATE OR REPLACE FUNCTION get_blocked_user_ids()
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT blocked_id FROM user_blocks
  WHERE blocker_id = auth.uid();
$$;

GRANT EXECUTE ON FUNCTION block_user TO authenticated;
GRANT EXECUTE ON FUNCTION unblock_user TO authenticated;
GRANT EXECUTE ON FUNCTION is_user_blocked TO authenticated;
GRANT EXECUTE ON FUNCTION get_blocked_user_ids TO authenticated;

-- Update messages RLS to exclude blocked users
-- This needs to be added to existing message policies
-- Add to SELECT policy:
-- AND sender_id NOT IN (SELECT blocked_id FROM user_blocks WHERE blocker_id = auth.uid())
```

---

## 3. Phase 1-B: 빈상태/에러상태 표준화

**파일**: `lib/shared/widgets/empty_state.dart` (신규)

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final Widget? action;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.action,
    this.iconSize = 64,
  });

  // Common presets
  factory EmptyState.noMessages() => const EmptyState(
    title: '아직 메시지가 없어요',
    message: '첫 메시지를 보내보세요',
    icon: Icons.chat_bubble_outline,
  );

  factory EmptyState.noNotifications() => const EmptyState(
    title: '알림이 없어요',
    message: '새로운 알림이 오면 여기에 표시됩니다',
    icon: Icons.notifications_none,
  );

  factory EmptyState.noSubscriptions() => const EmptyState(
    title: '구독 중인 아티스트가 없어요',
    message: '관심 있는 아티스트를 찾아 구독해보세요',
    icon: Icons.favorite_border,
  );

  factory EmptyState.noResults() => const EmptyState(
    title: '검색 결과가 없어요',
    message: '다른 검색어로 다시 시도해보세요',
    icon: Icons.search_off,
  );

  factory EmptyState.noTransactions() => const EmptyState(
    title: '거래 내역이 없어요',
    message: 'DT를 구매하면 여기에 표시됩니다',
    icon: Icons.receipt_long_outlined,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: iconSize,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
```

**파일**: `lib/shared/widgets/loading_state.dart` (신규)

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class LoadingState extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingState({
    super.key,
    this.message,
    this.size = 32,
  });

  factory LoadingState.small({String? message}) => LoadingState(
    message: message,
    size: 20,
  );

  factory LoadingState.large({String? message}) => LoadingState(
    message: message,
    size: 48,
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: size > 32 ? 4 : 2,
              color: AppColors.primary500,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
```

---

## 4. 테스트 계획

### 단위 테스트

```dart
// test/features/chat/message_edit_test.dart

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Message Edit', () {
    test('can edit message within 24 hours', () async {
      // Setup
      final message = BroadcastMessage(
        id: 'test-id',
        content: 'Original content',
        createdAt: DateTime.now().subtract(Duration(hours: 12)),
      );

      // Execute
      final canEdit = message.canEdit;

      // Verify
      expect(canEdit, isTrue);
    });

    test('cannot edit message after 24 hours', () async {
      // Setup
      final message = BroadcastMessage(
        id: 'test-id',
        content: 'Original content',
        createdAt: DateTime.now().subtract(Duration(hours: 25)),
      );

      // Execute
      final canEdit = message.canEdit;

      // Verify
      expect(canEdit, isFalse);
    });
  });
}
```

### 통합 테스트

```dart
// integration_test/chat_flow_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User can report a message', (tester) async {
    // Login as test user
    await loginAsTestUser(tester);

    // Navigate to chat
    await tester.tap(find.byIcon(Icons.chat));
    await tester.pumpAndSettle();

    // Long press on a message
    await tester.longPress(find.byType(MessageBubble).first);
    await tester.pumpAndSettle();

    // Tap report
    await tester.tap(find.text('신고'));
    await tester.pumpAndSettle();

    // Select reason
    await tester.tap(find.text('스팸'));
    await tester.pumpAndSettle();

    // Submit
    await tester.tap(find.text('신고하기'));
    await tester.pumpAndSettle();

    // Verify success message
    expect(find.text('신고가 접수되었습니다'), findsOneWidget);
  });
}
```

---

## 5. 배포 절차

### Phase 0 배포

```bash
# 1. Supabase 마이그레이션 (프로덕션)
# ⚠️ 먼저 app.encryption_key 설정 확인!
supabase db push

# 2. 마이그레이션 검증
supabase db diff

# 3. 롤백 준비
# 마이그레이션 롤백 스크립트 준비해둘 것
```

### Phase 1 배포

```bash
# 1. Edge Functions 배포
supabase functions deploy message-edit
supabase functions deploy content-filter

# 2. 마이그레이션 배포
supabase db push

# 3. Flutter 앱 빌드
flutter build web --release
flutter build apk --release
flutter build ios --release

# 4. Firebase 배포 (웹)
firebase deploy --only hosting

# 5. 앱스토어 제출
# - TestFlight 업로드
# - Google Play 내부 테스트 트랙
```
