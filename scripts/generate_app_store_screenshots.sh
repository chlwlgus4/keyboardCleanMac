#!/bin/zsh
set -euo pipefail
setopt null_glob

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$ROOT_DIR/build/KeyboardClean.app"
APP_BINARY="$APP_PATH/Contents/MacOS/KeyboardClean"
TMP_DIR="$ROOT_DIR/build/app-store-screenshots-tmp"
OUTPUT_DIR="${SCREENSHOT_OUTPUT_DIR:-$ROOT_DIR/AppStoreScreenshots}"
CANVAS_WIDTH=2880
CANVAS_HEIGHT=1800
SCREENSHOT_LANGUAGE="${SCREENSHOT_LANGUAGE:-ko}"

capture_scene() {
  local scene="$1"
  local output_prefix="$2"
  rm -f "$TMP_DIR/${output_prefix}.png" "$TMP_DIR/${output_prefix}-primary.png" "$TMP_DIR/${output_prefix}-overlay.png"

  SCREENSHOT_UI_LANGUAGE="$SCREENSHOT_LANGUAGE" \
    "$APP_BINARY" --export-screenshot-scene "$scene" --output-dir "$TMP_DIR" >/dev/null 2>&1

  if [[ "$scene" == "cleaning" ]]; then
    [[ -f "$TMP_DIR/cleaning-primary.png" ]] || { echo "Missing cleaning primary export."; exit 1; }
    [[ -f "$TMP_DIR/cleaning-overlay.png" ]] || { echo "Missing cleaning overlay export."; exit 1; }
  else
    [[ -f "$TMP_DIR/${output_prefix}.png" ]] || { echo "Missing export for scene '$scene'."; exit 1; }
  fi
}

compose_scene() {
  OUTPUT_PATH="$1" \
  EYEBROW="$2" \
  TITLE="$3" \
  SUBTITLE="$4" \
  UTILITY_LABEL="$5" \
  IMAGE1_LABEL="$6" \
  IMAGE2_LABEL="$7" \
  BG_START="$8" \
  BG_END="$9" \
  BG_ACCENT="${10}" \
  IMAGE1_PATH="${11}" \
  IMAGE1_X="${12}" \
  IMAGE1_Y="${13}" \
  IMAGE1_SCALE="${14}" \
  IMAGE2_PATH="${15:-}" \
  IMAGE2_X="${16:-0}" \
  IMAGE2_Y="${17:-0}" \
  IMAGE2_SCALE="${18:-1}" \
  ICON_PATH="$ROOT_DIR/Resources/AppIcon-1024.png" \
  CANVAS_WIDTH="$CANVAS_WIDTH" \
  CANVAS_HEIGHT="$CANVAS_HEIGHT" \
  /usr/bin/xcrun swift - <<'SWIFT'
import AppKit
import Foundation

let env = ProcessInfo.processInfo.environment

func color(from hex: String, alpha: CGFloat = 1.0) -> NSColor {
    let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var value: UInt64 = 0
    Scanner(string: cleaned).scanHexInt64(&value)

    let red = CGFloat((value >> 16) & 0xFF) / 255.0
    let green = CGFloat((value >> 8) & 0xFF) / 255.0
    let blue = CGFloat(value & 0xFF) / 255.0
    return NSColor(red: red, green: green, blue: blue, alpha: alpha)
}

func roundedRect(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func drawChip(text: String, rect: NSRect, fill: NSColor, stroke: NSColor, textColor: NSColor, font: NSFont) {
    fill.setFill()
    let path = roundedRect(rect, radius: rect.height / 2)
    path.fill()

    stroke.setStroke()
    path.lineWidth = 1
    path.stroke()

    let style = NSMutableParagraphStyle()
    style.alignment = .center

    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: textColor,
        .paragraphStyle: style
    ]

    (text as NSString).draw(
        in: NSRect(x: rect.minX, y: rect.minY + 7, width: rect.width, height: rect.height - 10),
        withAttributes: attributes
    )
}

func drawPanelLabel(_ text: String?, panelRect: NSRect) {
    guard let text, !text.isEmpty else { return }

    let font = NSFont.systemFont(ofSize: 22, weight: .semibold)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color(from: "#0F172A", alpha: 0.82)
    ]

    let textSize = (text as NSString).size(withAttributes: attributes)
    let chipRect = NSRect(
        x: panelRect.minX + 26,
        y: panelRect.maxY - 70,
        width: textSize.width + 42,
        height: 44
    )

    drawChip(
        text: text,
        rect: chipRect,
        fill: NSColor.white.withAlphaComponent(0.82),
        stroke: NSColor.white.withAlphaComponent(0.65),
        textColor: color(from: "#0F172A", alpha: 0.82),
        font: font
    )
}

func drawImage(at path: String?, x: CGFloat, y: CGFloat, scale: CGFloat, label: String?) {
    guard let path, !path.isEmpty, let image = NSImage(contentsOfFile: path) else { return }

    let targetSize = NSSize(width: image.size.width * scale, height: image.size.height * scale)
    let imageRect = NSRect(x: x, y: y, width: targetSize.width, height: targetSize.height)
    let panelRect = imageRect.insetBy(dx: -42, dy: -42)

    NSGraphicsContext.current?.saveGraphicsState()

    let panelShadow = NSShadow()
    panelShadow.shadowColor = NSColor.black.withAlphaComponent(0.14)
    panelShadow.shadowBlurRadius = 48
    panelShadow.shadowOffset = NSSize(width: 0, height: -18)
    panelShadow.set()

    let panelPath = roundedRect(panelRect, radius: 34)
    color(from: "#FFFFFF", alpha: 0.76).setFill()
    panelPath.fill()

    NSGraphicsContext.current?.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.62).setStroke()
    panelPath.lineWidth = 1
    panelPath.stroke()

    if let panelGradient = NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.34),
        NSColor.white.withAlphaComponent(0.12),
        NSColor.white.withAlphaComponent(0.04)
    ]) {
        panelGradient.draw(in: panelPath, angle: -90)
    }

    NSGraphicsContext.current?.saveGraphicsState()
    let imageShadow = NSShadow()
    imageShadow.shadowColor = NSColor.black.withAlphaComponent(0.12)
    imageShadow.shadowBlurRadius = 26
    imageShadow.shadowOffset = NSSize(width: 0, height: -12)
    imageShadow.set()
    image.draw(in: imageRect)
    NSGraphicsContext.current?.restoreGraphicsState()

    drawPanelLabel(label, panelRect: panelRect)
}

let canvasWidth = CGFloat(Double(env["CANVAS_WIDTH"] ?? "2880") ?? 2880)
let canvasHeight = CGFloat(Double(env["CANVAS_HEIGHT"] ?? "1800") ?? 1800)
let canvasSize = NSSize(width: canvasWidth, height: canvasHeight)

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(canvasWidth),
    pixelsHigh: Int(canvasHeight),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fatalError("Unable to create bitmap")
}

bitmap.size = canvasSize

guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Missing graphics context")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.cgContext.interpolationQuality = .high

let bgStart = color(from: env["BG_START"] ?? "#FFFFFF")
let bgEnd = color(from: env["BG_END"] ?? "#F3F4F6")
let bgAccent = color(from: env["BG_ACCENT"] ?? "#C4B5FD")

let backgroundGradient = NSGradient(colors: [bgStart, bgEnd])!
backgroundGradient.draw(in: NSRect(origin: .zero, size: canvasSize), angle: -18)

color(from: "#FFFFFF", alpha: 0.42).setFill()
roundedRect(NSRect(x: 90, y: 96, width: canvasWidth - 180, height: canvasHeight - 192), radius: 54).fill()

if let accentGradient = NSGradient(colors: [
    bgAccent.withAlphaComponent(0.55),
    bgAccent.withAlphaComponent(0.0)
]) {
    accentGradient.draw(in: NSRect(x: canvasWidth - 980, y: canvasHeight - 760, width: 940, height: 760), relativeCenterPosition: NSPoint(x: 0.3, y: 0.2))
    accentGradient.draw(in: NSRect(x: -220, y: -140, width: 820, height: 760), relativeCenterPosition: NSPoint(x: 0.5, y: 0.5))
}

if let iconPath = env["ICON_PATH"], let icon = NSImage(contentsOfFile: iconPath) {
    let iconCard = NSRect(x: 176, y: canvasHeight - 250, width: 116, height: 116)

    NSGraphicsContext.current?.saveGraphicsState()
    let iconShadow = NSShadow()
    iconShadow.shadowColor = NSColor.black.withAlphaComponent(0.12)
    iconShadow.shadowBlurRadius = 20
    iconShadow.shadowOffset = NSSize(width: 0, height: -8)
    iconShadow.set()
    color(from: "#FFFFFF", alpha: 0.84).setFill()
    roundedRect(iconCard, radius: 30).fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.58).setStroke()
    let iconPathRect = roundedRect(iconCard, radius: 30)
    iconPathRect.lineWidth = 1
    iconPathRect.stroke()

    icon.draw(in: iconCard.insetBy(dx: 16, dy: 16))
}

let eyebrow = env["EYEBROW"] ?? ""
let title = (env["TITLE"] ?? "").replacingOccurrences(of: "\\n", with: "\n")
let subtitle = env["SUBTITLE"] ?? ""

let eyebrowAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 26, weight: .semibold),
    .foregroundColor: color(from: "#1D4ED8", alpha: 0.9)
]
let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 96, weight: .bold),
    .foregroundColor: color(from: "#0F172A")
]
let subtitleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 36, weight: .regular),
    .foregroundColor: color(from: "#334155", alpha: 0.9)
]

(eyebrow as NSString).draw(
    in: NSRect(x: 176, y: canvasHeight - 360, width: 900, height: 56),
    withAttributes: eyebrowAttributes
)

(title as NSString).draw(
    with: NSRect(x: 170, y: canvasHeight - 760, width: 1360, height: 340),
    options: [.usesLineFragmentOrigin, .usesFontLeading],
    attributes: titleAttributes
)

(subtitle as NSString).draw(
    with: NSRect(x: 176, y: canvasHeight - 930, width: 1320, height: 160),
    options: [.usesLineFragmentOrigin, .usesFontLeading],
    attributes: subtitleAttributes
)

let utilityLabel = env["UTILITY_LABEL"] ?? "macOS utility"
let utilityFont = NSFont.systemFont(ofSize: 24, weight: .medium)
let utilityWidth = (utilityLabel as NSString).size(withAttributes: [.font: utilityFont]).width + 48

drawChip(
    text: utilityLabel,
    rect: NSRect(x: 176, y: 154, width: utilityWidth, height: 56),
    fill: color(from: "#FFFFFF", alpha: 0.82),
    stroke: color(from: "#FFFFFF", alpha: 0.56),
    textColor: color(from: "#0F172A", alpha: 0.84),
    font: utilityFont
)

drawImage(
    at: env["IMAGE1_PATH"],
    x: CGFloat(Double(env["IMAGE1_X"] ?? "0") ?? 0),
    y: CGFloat(Double(env["IMAGE1_Y"] ?? "0") ?? 0),
    scale: CGFloat(Double(env["IMAGE1_SCALE"] ?? "1") ?? 1),
    label: env["IMAGE1_LABEL"]
)

drawImage(
    at: env["IMAGE2_PATH"],
    x: CGFloat(Double(env["IMAGE2_X"] ?? "0") ?? 0),
    y: CGFloat(Double(env["IMAGE2_Y"] ?? "0") ?? 0),
    scale: CGFloat(Double(env["IMAGE2_SCALE"] ?? "1") ?? 1),
    label: env["IMAGE2_LABEL"]
)

NSGraphicsContext.restoreGraphicsState()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Unable to encode composed screenshot")
}

try pngData.write(to: URL(fileURLWithPath: env["OUTPUT_PATH"] ?? "output.png"))
SWIFT
}

localized_copy() {
  local key="$1"

  case "$SCREENSHOT_LANGUAGE:$key" in
    ko:control_eyebrow) echo "키보드 청소를 더 안전하게" ;;
    ko:control_title) echo "청소 전에\\n키보드를 잠그세요" ;;
    ko:control_subtitle) echo "메뉴 막대에서 청소 모드를 켜면 실수 입력을 바로 막을 수 있어요." ;;
    ko:utility_label) echo "macOS 유틸리티" ;;
    ko:control_label1) echo "청소 모드 컨트롤" ;;
    ko:shortcut_eyebrow) echo "익숙한 방식으로 빠르게" ;;
    ko:shortcut_title) echo "손에 익은 단축키로\\n바로 시작하세요" ;;
    ko:shortcut_subtitle) echo "원하는 키 조합으로 청소 모드를 즉시 켜고 끌 수 있어요." ;;
    ko:shortcut_label1) echo "단축키 설정" ;;
    ko:cleaning_eyebrow) echo "청소 중에도 안심하고" ;;
    ko:cleaning_title) echo "종료 단축키를\\n항상 보여줘요" ;;
    ko:cleaning_subtitle) echo "오버레이에 종료 버튼과 단축키가 표시되어 바로 해제할 수 있어요." ;;
    ko:cleaning_label1) echo "메인 컨트롤" ;;
    ko:cleaning_label2) echo "클리닝 모드 오버레이" ;;
    en:control_eyebrow) echo "Safe keyboard cleaning" ;;
    en:control_title) echo "Lock the keyboard\\nbefore you clean" ;;
    en:control_subtitle) echo "Turn on cleaning mode from the menu bar and stop accidental input instantly." ;;
    en:utility_label) echo "macOS utility" ;;
    en:control_label1) echo "Cleaning mode control" ;;
    en:shortcut_eyebrow) echo "Launch it your way" ;;
    en:shortcut_title) echo "Set a shortcut\\nthat feels natural" ;;
    en:shortcut_subtitle) echo "Use your preferred key combo to toggle cleaning mode in a second." ;;
    en:shortcut_label1) echo "Shortcut setup" ;;
    en:cleaning_eyebrow) echo "Stay in control while cleaning" ;;
    en:cleaning_title) echo "Keep the exit shortcut\\nvisible while cleaning" ;;
    en:cleaning_subtitle) echo "A floating overlay shows the exit shortcut and button the whole time." ;;
    en:cleaning_label1) echo "Main control" ;;
    en:cleaning_label2) echo "Cleaning overlay" ;;
    *) echo "" ;;
  esac
}

compose_control() {
  compose_scene \
    "$OUTPUT_DIR/01-lock-before-cleaning.png" \
    "$(localized_copy control_eyebrow)" \
    "$(localized_copy control_title)" \
    "$(localized_copy control_subtitle)" \
    "$(localized_copy utility_label)" \
    "$(localized_copy control_label1)" \
    "" \
    "#EAF2FF" \
    "#D6E8FF" \
    "#60A5FA" \
    "$TMP_DIR/control.png" \
    "1520" \
    "214" \
    "2.72"
}

compose_shortcut() {
  compose_scene \
    "$OUTPUT_DIR/02-custom-shortcut.png" \
    "$(localized_copy shortcut_eyebrow)" \
    "$(localized_copy shortcut_title)" \
    "$(localized_copy shortcut_subtitle)" \
    "$(localized_copy utility_label)" \
    "$(localized_copy shortcut_label1)" \
    "" \
    "#FFF5E6" \
    "#FFE3C2" \
    "#FB923C" \
    "$TMP_DIR/shortcut.png" \
    "1605" \
    "330" \
    "2.86"
}

compose_cleaning() {
  compose_scene \
    "$OUTPUT_DIR/03-cleaning-overlay.png" \
    "$(localized_copy cleaning_eyebrow)" \
    "$(localized_copy cleaning_title)" \
    "$(localized_copy cleaning_subtitle)" \
    "$(localized_copy utility_label)" \
    "$(localized_copy cleaning_label1)" \
    "$(localized_copy cleaning_label2)" \
    "#EAFBF2" \
    "#D3F3E4" \
    "#34D399" \
    "$TMP_DIR/cleaning-primary.png" \
    "210" \
    "170" \
    "2.84" \
    "$TMP_DIR/cleaning-overlay.png" \
    "1770" \
    "975" \
    "3.55"
}

mkdir -p "$TMP_DIR" "$OUTPUT_DIR"
rm -f "$TMP_DIR"/*.png "$OUTPUT_DIR"/*.png

"$ROOT_DIR/build_app.sh" >/dev/null

capture_scene "control" "control"
capture_scene "shortcut" "shortcut"
capture_scene "cleaning" "cleaning"

compose_control
compose_shortcut
compose_cleaning

echo "Created screenshots in: $OUTPUT_DIR"
