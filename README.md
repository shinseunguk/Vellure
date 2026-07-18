# Vellure

iOS 애플리케이션

## 기술 스택

- **UI**: SwiftUI
- **아키텍처**: MVVM
- **최소 지원**: iOS 26.4
- **언어**: Swift 5.0
- **린트**: SwiftLint
- **CI/CD**: GitHub Actions, Fastlane

## 시작하기

### 요구사항

- Xcode 26.4.1+
- SwiftLint (`brew install swiftlint`)

### 설치

```bash
git clone https://github.com/shinseunguk/Vellure.git
cd Vellure
open Vellure.xcodeproj
```

### Fastlane

```bash
bundle install
bundle exec fastlane lint    # SwiftLint 실행
bundle exec fastlane build   # 개발 빌드
bundle exec fastlane test    # 테스트 실행
bundle exec fastlane beta    # TestFlight 배포
bundle exec fastlane release # App Store 배포
```

## 브랜치 전략

| 브랜치 | 용도 |
|--------|------|
| `main` | 프로덕션 릴리즈 |
| `develop` | 개발 통합 |
| `feature/*` | 기능 개발 |
| `bugfix/*` | 버그 수정 |
| `hotfix/*` | 긴급 수정 |

## 커밋 컨벤션

```
feat: 새로운 기능 추가
fix: 버그 수정
refactor: 리팩토링
style: 코드 스타일 변경
docs: 문서 수정
test: 테스트 추가/수정
chore: 빌드, 설정 등 기타 작업
```
