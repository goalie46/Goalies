# 데이터 구조와 접근 권한 설계

> `supabase/migrations/0001_initial_schema.sql`은 구현 전 검토용 첫 초안이다. 실제 개인정보를 넣기 전에 별도 개발 프로젝트에서 자동 권한 테스트를 통과해야 한다.

## 핵심 관계와 제약

- `users`는 인증 계정과 1:1이며 전역 역할을 저장하지 않는다.
- `organizations`와 `memberships`가 작업 공간 역할을 정의한다. `coach` membership은 조직 관리자가 서버에서 부여한다.
- `athletes`는 계정 없이 존재할 수 있다. 로그인한 선수를 연결할 때만 `athlete_access`에 `athlete` 관계를 만든다.
- `athlete_access`는 선수별 `coach | athlete | parent` 연결이며 철회 시 `revoked_at`을 기록한다.
- `sessions`의 공개 상태와 `assignments`의 수행 상태를 분리한다.
- `session_feedback`에는 선수/부모에게 공개 가능한 내용만, `private_coach_notes`에는 코치 전용 메모만 저장한다.
- `monthly_reports`는 `draft | approved | needs_review` 상태다. 승인 후 근거 레슨이 바뀌면 DB trigger가 `needs_review`로 바꾼다.

## 조회 원칙

| 데이터 | 코치 | 선수·부모 |
|---|---|---|
| 선수 프로필 | 활성 coach 연결 | 자신의 활성 연결 |
| 레슨 draft | 해당 조직 coach만 | 불가 |
| 레슨 published | 활성 연결 | 활성 연결 |
| 코치 전용 메모 | 작성 코치 | 테이블 접근 자체 불가 |
| 자기평가 | 연결 코치 | 해당 선수 연결 |
| 리포트 draft/재검토 | 연결 코치 | 불가 |
| 리포트 approved | 연결 코치 | 활성 연결 |
| 비공개 영상 | 연결 + 공개상태 규칙 | 연결 + 공개 레슨만 |

앱 API에서 테이블 전체를 조합해 반환하지 않고 역할별 허용 필드만 명시적으로 선택한다. 특히 공개 응답에는 `private_coach_notes` join을 하지 않는다.

## 초대

원문 토큰은 저장하지 않고 SHA-256 hash만 저장한다. Edge Function이 다음을 한 트랜잭션에서 검사한다.

1. hash 일치, `accepted_at/revoked_at IS NULL`, `expires_at > now()` 확인
2. 초대 이메일과 현재 인증 이메일 비교
3. membership/athlete_access 생성
4. 조건부 update로 `accepted_at` 기록 (`accepted_at IS NULL` 조건)

조건부 update가 한 행이 아니면 재사용/경합으로 실패한다. 코치 초대는 조직 관리자만 만들 수 있다.

## 영상

- Storage private bucket에 `{organization_id}/{athlete_id}/{asset_id}` 경로로 저장한다.
- MVP 허용 형식: `video/mp4`, `video/quicktime`; 파일당 최대 500 MB, 레슨당 3개.
- 텍스트 초안을 먼저 저장하고 영상은 별도 upload 상태로 처리하여 실패가 글을 지우지 않게 한다.
- 업로드 progress, 재시도, 중복 방지용 object key를 둔다.
- annotation은 `0 <= start_ms < end_ms <= duration_ms`를 서버에서 검사한다.
- Edge Function이 현재 연결과 레슨 공개 상태를 다시 확인한 뒤 5분 signed URL을 발급한다.
- 연결 해제 후 새 URL은 발급하지 않는다. 이미 발급된 URL은 만료까지 열릴 수 있으므로 짧은 만료, 즉시 객체 이동/삭제가 필요한 사고 대응 절차를 함께 둔다.

## 삭제와 보존 초안

- 연결 해제는 `revoked_at`을 즉시 기록하고 새 조회와 URL 발급을 차단한다.
- 계정 삭제 요청 즉시 로그인 세션과 개인 연결을 철회하고, 법적 보존 사유가 없는 계정 정보는 30일 내 삭제한다.
- 선수 기록은 조직의 계약상 보존 책임과 보호자 요청을 확인한 뒤 삭제/익명화한다. 파일럿 전에 최종 기간과 책임자를 개인정보 처리방침에 동일하게 명시한다.
- 동의 사건은 `consent_logs`에 철회까지 남기되 불필요한 본문/영상과 분리한다.
- 내보내기는 서버가 권한을 재확인한 뒤 만료되는 다운로드를 제공한다.

## 필수 보안 테스트

부모의 다른 선수 ID 직접 접근, 미연결 코치 수정, draft/미승인 리포트 조회, coach note 누출, 만료·재사용 초대, 연결 철회 후 조회/URL 발급을 서로 다른 실제 JWT로 검사한다. service role을 사용하는 테스트만으로 RLS가 안전하다고 판단하면 안 된다.
