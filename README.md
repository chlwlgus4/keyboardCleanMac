# KeyboardCleanMac

맥에서 키보드를 닦을 때 키 입력을 잠시 막는 macOS 앱입니다.

## 기능
- 메뉴바에서 `Enable Cleaning Mode` 클릭 시 키 입력 차단
- 메뉴바에서 `Disable Cleaning Mode` 클릭 시 즉시 해제
- 전역 단축키로 ON/OFF 토글
- 메뉴에서 단축키 직접 변경 (`Set Shortcut...`)
- 모드 변경 시 화면 상단 HUD 표시

## 권한
처음 실행 시 접근성(Accessibility) 권한이 필요합니다.
- 시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용
- `KeyboardClean.app` 허용 후 앱 재실행

## 빌드
```bash
./build_app.sh
```

빌드 결과:
- `/Users/choijihyeon/IdeaProjects/keyboardCleanMac/build/KeyboardClean.app`

## 실행
```bash
open /Applications/KeyboardClean.app
```

## 설치(권장)
```bash
./build_app.sh
killall KeyboardClean 2>/dev/null || true
rm -rf /Applications/KeyboardClean.app
cp -R /Users/choijihyeon/IdeaProjects/keyboardCleanMac/build/KeyboardClean.app /Applications/KeyboardClean.app
open /Applications/KeyboardClean.app
```
