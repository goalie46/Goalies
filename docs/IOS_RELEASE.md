# iOS 빌드와 TestFlight 준비

## 개발 미리보기와 배포 빌드의 차이

- Expo Go/웹은 빠른 기능 확인용이다. 웹에서 보인다고 iOS 앱이 완성된 것은 아니다.
- 로컬 iOS Simulator는 Mac과 Xcode가 필요하다.
- EAS Build는 Mac이 없어도 원격 macOS에서 iOS 빌드를 만들 수 있다. 단, 배포 서명과 TestFlight에는 Apple Developer Program 가입이 필요하다.

## 필요한 외부 계정

1. 앱 소유자 명의 Apple Developer Program / App Store Connect 계정
2. Expo 계정과 EAS CLI
3. 고유 bundle identifier(현재 임시값 `com.creaselog.app`)
4. 지원·개인정보 처리방침 웹 주소와 문의 연락처

## 예상 명령

```bash
npm install
npx expo install --check
npx expo-doctor
npx eas-cli login
npx eas-cli build:configure
npx eas-cli build --platform ios --profile preview
npx eas-cli build --platform ios --profile production
npx eas-cli submit --platform ios --profile production
```

EAS가 인증서를 관리하도록 선택할 수 있지만 계정 소유권과 App Store Connect 권한은 앱 소유자가 유지한다. 첫 배포 전 실제 iPhone과 iPad에서 로그인, 키보드, 영상, 네트워크 실패, 글자 크기, 계정 삭제를 검사한다.

## 심사 준비 체크리스트

- 앱 아이콘, iPhone/iPad 스크린샷, 설명, 연령 등급
- 개인정보 처리방침과 지원 페이지
- 앱에서 시작할 수 있는 계정 삭제 흐름
- 코치/선수/부모 역할별 심사용 데모 계정과 심사 메모
- 실제 수집·공유 내용과 일치하는 App Privacy 답변
- 타사 소셜 로그인을 추가한다면 당시 적용되는 Apple 로그인 정책 검토
- 미성년자 보호자 동의, 연결 해제, 보존·삭제 정책 검증
- 결제 없는 파일럿. 유료 디지털 기능을 넣기 전에 당시 인앱결제 규정 재검토

> 이 환경에서는 공식 웹 문서 검색 도구가 인증 오류(HTTP 401)를 반환하여 2026-09-15 기준 정책 원문을 재확인하지 못했다. 제출 직전에 Apple App Review Guidelines, Account Deletion, App Privacy 및 Expo EAS 공식 문서를 반드시 다시 확인한다.
