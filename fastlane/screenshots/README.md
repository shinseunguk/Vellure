# App Store 스크린샷

`fastlane deliver`(= `upload_to_app_store`)가 이 폴더의 이미지를 언어별로 업로드합니다.

## 폴더 구조

```
fastlane/screenshots/
├── ko/
├── en-US/
├── ja/
└── zh-Hans/
```

각 언어 폴더에 해당 언어로 캡처한 이미지를 넣습니다. 파일명 알파벳 순서대로 스토어에 노출되므로 `01_home.png`, `02_edit.png` … 처럼 접두 번호를 붙이세요.

## 필수 해상도 (2025~ 기준)

App Store Connect는 **6.9형 디스플레이 스크린샷이 필수**입니다. 6.5형은 6.9형이 있으면 생략 가능합니다.

| 디스플레이 | 대표 기기 | 세로 해상도(px) |
|-----------|----------|----------------|
| 6.9" (필수) | iPhone 17 Pro Max / 16 Pro Max | 1320 × 2868 |
| 6.5" (선택) | iPhone 11 Pro Max 등 | 1242 × 2688 |

- 장당 3~10장, PNG 또는 JPG.
- `docs/screenshots/`의 README용 이미지는 6.3형(1206×2622)이라 **App Store 규격이 아닙니다**. 6.9형 시뮬레이터로 다시 캡처해야 합니다.

## 캡처 방법 (6.9형)

```bash
# 6.9형 시뮬레이터 부팅 후, 시드 데이터가 있는 화면을 캡처
xcrun simctl boot "iPhone 17 Pro Max"
xcrun simctl io "iPhone 17 Pro Max" screenshot fastlane/screenshots/ko/01_home.png
```

> 잠금화면 Live Activity 컷은 시뮬레이터에서 ⌘L(Device → Lock)로 직접 잠근 뒤 캡처해야 합니다(CLI 자동 잠금 불가).

## 업로드

```bash
bundle exec fastlane upload_screenshots
```
