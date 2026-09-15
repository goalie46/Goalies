# CreaseLog

골리 코치의 레슨 기록이 선수의 과제와 월간 성장 리포트로 이어지도록 돕는 **React Native + Expo + TypeScript** 앱입니다.

> 현재 상태: **1–2단계 UI 프로토타입**입니다. 코치 홈, 선수 상세, 레슨 작성, 선수 홈, 부모 홈을 가상 데이터로 둘러볼 수 있습니다. 로그인, 서버 저장, 실제 권한 통제, 영상 업로드는 아직 연결되지 않았습니다.

## 지금 확인할 수 있는 흐름

1. 상단 `코치 데모` 버튼으로 코치 → 선수 → 부모 역할 화면을 전환합니다.
2. 코치 홈에서 담당 선수를 눌러 목표와 공개 레슨 타임라인을 확인합니다.
3. `새 레슨 기록`에서 태그와 필수 기록 항목을 입력하고 초안 저장 UI를 확인합니다.
4. 선수 홈에서는 핵심 과제와 완료 행동을, 부모 홈에서는 공개 요약과 리포트 상태를 확인합니다.

역할 전환은 **프론트엔드 데모 전용**이며 인증이나 권한 부여가 아닙니다. 실제 버전에서는 서버가 검증한 `memberships`와 `athlete_access`만 사용합니다.

## 로컬 실행

요구 사항: Node.js 20 LTS 이상, npm, iPhone/iPad의 Expo Go 또는 iOS Simulator가 있는 Mac.

```bash
npm install
npm start
```

- 터미널 QR을 Expo Go로 스캔하면 실제 기기에서 개발 미리보기를 실행할 수 있습니다.
- `npm run web`은 브라우저 미리보기이며 **iOS 앱 빌드가 아닙니다**.
- `npm run ios`는 macOS와 Xcode/iOS Simulator가 필요합니다.
- 타입 검사: `npm run typecheck`
- 데이터 모델 검사: `npm test`

현재 작업 환경은 npm registry 요청이 `403 Forbidden`으로 차단되어 의존성 설치와 앱 실행을 완료하지 못했습니다. 네트워크가 허용된 환경에서 먼저 `npm install`을 실행해야 합니다.

## 기술 구성

| 영역 | 선택 | 이유 |
|---|---|---|
| 앱 | Expo SDK 54 / React Native / TypeScript | 한 코드베이스로 iOS·Android·웹 개발 미리보기, EAS 클라우드 빌드 가능 |
| 백엔드(3단계) | Supabase Auth + Postgres + Storage | 관계형 권한 모델, Row Level Security, 비공개 객체 저장을 함께 제공 |
| 서버 작업(3단계) | Supabase Edge Functions | 초대 토큰, 짧은 유효기간 재생 URL, 계정 삭제처럼 클라이언트가 직접 수행하면 안 되는 작업 처리 |
| 상태/검증(추가 예정) | TanStack Query + React Hook Form + Zod | 서버 상태, 폼 오류, 중복 제출을 명확히 분리 |
| 빌드 | EAS Build | Mac이 없어도 Expo의 macOS 빌드 인프라에서 iOS 바이너리 생성 가능 |

의존성 버전은 설치 시점에 Expo 호환성 검사(`npx expo install --check`)를 거쳐 확정해야 합니다.

## 프로젝트 구조

```text
App.tsx                 역할별 데모 화면과 기본 탐색
src/data/demo.ts        실제 인물이 아닌 가상 데이터
src/types.ts            UI 데이터 타입과 상태값
docs/PRODUCT_SPEC.md    제품 범위와 단계별 구현 상태
docs/DATA_AND_ACCESS.md 데이터 구조, 제약조건, 권한 설계
docs/IOS_RELEASE.md     EAS, 서명, TestFlight 준비 안내
supabase/migrations/    향후 백엔드에 적용할 데이터베이스 초안
tests/                  상태 모델의 기본 불변조건 검사
```

## 다음 구현 순서

1. Supabase 프로젝트 생성 후 환경변수 설정 및 실제 인증 연결
2. 아래 migration을 별도 개발 프로젝트에 검토·적용
3. 초대 수락 Edge Function과 역할/선수 접근 검증 테스트
4. 레슨 초안의 자동 저장, idempotency key, 공개 트랜잭션 연결
5. 과제 완료·자기평가·승인형 월간 리포트 연결
6. 비공개 영상 업로드와 짧은 수명의 signed URL 구현

비밀값은 `.env`나 앱 번들에 넣지 않습니다. `EXPO_PUBLIC_` 변수는 사용자 기기에서 읽을 수 있으므로 공개 가능한 Supabase URL과 anon key만 사용합니다.

## 외부에서 필요한 것

- **Supabase 계정/프로젝트**: 실제 로그인·저장·RLS 검증 단계
- **Expo 계정**: EAS 클라우드 빌드
- **Apple Developer Program 계정**: 실제 기기 배포, 서명, TestFlight/App Store 제출. 앱 소유자가 관리해야 합니다.
- 앱 식별자, 지원 URL, 개인정보 처리방침 URL, 심사용 역할별 데모 계정

세부 내용은 [iOS 배포 문서](docs/IOS_RELEASE.md)를 참고하세요.
