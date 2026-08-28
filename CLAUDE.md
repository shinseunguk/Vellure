# Vellure

## 프로젝트 개요

- **플랫폼**: iOS (SwiftUI)
- **최소 지원 버전**: iOS 26.4
- **언어**: Swift 5.0
- **Bundle ID**: dev.ukseung.Vellure
- **빌드 도구**: Xcode 26.4.1
- **아키텍처**: MVVM

## 디렉토리 구조

```
Vellure/
├── App/                  # App Entry Point (VellureApp.swift)
├── Models/               # 데이터 모델
├── ViewModels/           # 뷰모델
├── Views/                # SwiftUI 뷰
│   ├── Components/       # 재사용 가능한 공통 컴포넌트
│   └── Screens/          # 화면 단위 뷰
├── Services/             # 네트워크, 저장소 등 서비스 레이어
├── Extensions/           # Swift Extension
├── Utilities/            # 헬퍼, 상수 등 유틸리티
└── Resources/            # Assets, Fonts, Localizable 등 리소스
```

## 브랜치 전략

```
main (프로덕션)
 └── develop (개발)
      └── feature/#{이슈번호}-{기능명}
      └── bugfix/#{이슈번호}-{버그명}
      └── hotfix/#{이슈번호}-{긴급수정}
```

- `main`: 릴리즈 가능한 안정 브랜치
- `develop`: 개발 통합 브랜치
- `feature/*`: 기능 개발 브랜치 (develop에서 파생)
- `bugfix/*`: 버그 수정 브랜치 (develop에서 파생)
- `hotfix/*`: 긴급 수정 브랜치 (main에서 파생)

## 워크플로우

1. GitHub 이슈 생성 (템플릿 기반)
2. `develop`에서 브랜치 파생 (`feature/#{이슈번호}-{기능명}`)
3. 코드 작업 + 커밋 (컨벤션에 맞게)
4. `develop`에 rebase
5. PR 작성 (`feature` -> `develop`)
6. 머지 후 릴리즈 시 `develop` -> `main` PR

## 커밋 컨벤션

Conventional Commits 스타일을 따르며, **커밋 메시지는 반드시 한글로 작성**한다.

### 형식

```
<type>: <제목>

<본문 (선택)>
```

### Type

| Type | 설명 |
|------|------|
| `feat` | 새로운 기능 추가 |
| `fix` | 버그 수정 |
| `refactor` | 리팩토링 (기능 변경 없음) |
| `style` | 코드 스타일 변경 (포맷팅 등) |
| `docs` | 문서 수정 |
| `test` | 테스트 추가/수정 |
| `chore` | 빌드, 설정 등 기타 작업 |

### 예시

```
feat: 로그인 화면 구현
fix: 프로필 이미지 로딩 실패 수정
refactor: 네트워크 레이어 구조 개선
chore: SwiftLint 설정 추가
```

### 규칙

- **`Co-Authored-By` 서명은 절대 포함하지 않는다**
- 제목은 간결하게 (50자 이내)
- 본문이 필요한 경우 빈 줄로 구분
- 하나의 커밋에는 하나의 논리적 변경만 포함

## 네이밍 컨벤션

| 대상 | 규칙 | 예시 |
|------|------|------|
| 파일명 | PascalCase | `LoginView.swift`, `UserModel.swift` |
| 클래스/구조체 | PascalCase | `LoginViewModel`, `UserService` |
| 함수/변수 | camelCase | `fetchUserData()`, `userName` |
| 상수 | camelCase | `maxRetryCount` |
| 프로토콜 | PascalCase + ~able/~ing/~Protocol | `Configurable`, `NetworkServiceProtocol` |
| 열거형 | PascalCase (case는 camelCase) | `enum ViewState { case loading }` |

## 코딩 스타일

- SwiftLint 규칙을 준수한다 (`.swiftlint.yml` 참고)
- SwiftUI 기반으로 UI를 구성한다
- MVVM 아키텍처를 따른다
- `import` 순서: Foundation > SwiftUI/UIKit > 외부 라이브러리 > 내부 모듈 (알파벳 순)
- Access Control은 최소 권한 원칙을 따른다 (`private` 우선)
- 매직 넘버 사용을 지양하고 상수로 정의한다
- 강제 언래핑(`!`)은 사용하지 않는다 (`IBOutlet` 제외)
- `self`는 클로저 내부 등 필요한 경우에만 사용한다

## PR 규칙

- GitHub PR 템플릿을 따른다 (`.github/PULL_REQUEST_TEMPLATE.md`)
- `develop` 브랜치로의 PR은 rebase 후 생성한다
- PR 제목은 커밋 컨벤션과 동일한 형식을 따른다
- 관련 이슈 번호를 반드시 연결한다 (`closes #이슈번호`)

## Git 규칙

- `main`, `develop` 브랜치에 직접 push하지 않는다
- force push는 사용하지 않는다
- 머지 전 반드시 rebase로 히스토리를 정리한다
