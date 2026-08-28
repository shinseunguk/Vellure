fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios generate

```sh
[bundle exec] fastlane ios generate
```

Tuist 프로젝트 생성

### ios lint

```sh
[bundle exec] fastlane ios lint
```

SwiftLint 실행

### ios build

```sh
[bundle exec] fastlane ios build
```

개발 빌드

### ios test

```sh
[bundle exec] fastlane ios test
```

테스트 실행

### ios beta

```sh
[bundle exec] fastlane ios beta
```

TestFlight 배포

### ios release

```sh
[bundle exec] fastlane ios release
```

App Store 배포

### ios upload_metadata

```sh
[bundle exec] fastlane ios upload_metadata
```

메타데이터만 App Store Connect에 업로드 (바이너리/스크린샷 제외)

### ios upload_screenshots

```sh
[bundle exec] fastlane ios upload_screenshots
```

스크린샷만 App Store Connect에 업로드 (바이너리/메타데이터 제외)

### ios certificates

```sh
[bundle exec] fastlane ios certificates
```

match 인증서/프로파일 동기화 (최초 생성 및 갱신)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
