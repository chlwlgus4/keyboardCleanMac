import AppKit

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

let bg = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 1024, height: 1024), xRadius: 220, yRadius: 220)
NSColor(calibratedRed: 0.11, green: 0.16, blue: 0.23, alpha: 1.0).setFill()
bg.fill()

let glow = NSGradient(colors: [
    NSColor(calibratedRed: 0.25, green: 0.72, blue: 0.89, alpha: 0.45),
    NSColor(calibratedRed: 0.12, green: 0.35, blue: 0.55, alpha: 0.0)
])
glow?.draw(in: NSBezierPath(ovalIn: NSRect(x: 110, y: 560, width: 840, height: 420)), angle: 0)

let boardRect = NSRect(x: 150, y: 240, width: 724, height: 460)
let board = NSBezierPath(roundedRect: boardRect, xRadius: 86, yRadius: 86)
NSColor(calibratedRed: 0.88, green: 0.94, blue: 0.98, alpha: 1.0).setFill()
board.fill()

let rows = 4
let cols = [10, 10, 9, 7]
let keySpacing: CGFloat = 16
let keyHeight: CGFloat = 68
let startY = boardRect.maxY - 110

for r in 0..<rows {
    let count = cols[r]
    let availableWidth = boardRect.width - 80
    let keyWidth = (availableWidth - CGFloat(count - 1) * keySpacing) / CGFloat(count)
    let offsetX: CGFloat = r == 3 ? 55 : (r == 2 ? 28 : 0)
    let y = startY - CGFloat(r) * (keyHeight + keySpacing)

    for c in 0..<count {
        let x = boardRect.minX + 40 + offsetX + CGFloat(c) * (keyWidth + keySpacing)
        let keyRect = NSRect(x: x, y: y, width: keyWidth, height: keyHeight)
        let keyPath = NSBezierPath(roundedRect: keyRect, xRadius: 16, yRadius: 16)
        NSColor(calibratedRed: 0.74, green: 0.83, blue: 0.90, alpha: 1.0).setFill()
        keyPath.fill()
    }
}

// Space bar
let space = NSBezierPath(roundedRect: NSRect(x: boardRect.midX - 170, y: boardRect.minY + 48, width: 340, height: 52), xRadius: 18, yRadius: 18)
NSColor(calibratedRed: 0.68, green: 0.78, blue: 0.86, alpha: 1.0).setFill()
space.fill()

// Sparkle accent
func drawSparkle(center: NSPoint, radius: CGFloat, color: NSColor) {
    let path = NSBezierPath()
    path.move(to: NSPoint(x: center.x, y: center.y + radius))
    path.line(to: NSPoint(x: center.x + radius * 0.28, y: center.y + radius * 0.28))
    path.line(to: NSPoint(x: center.x + radius, y: center.y))
    path.line(to: NSPoint(x: center.x + radius * 0.28, y: center.y - radius * 0.28))
    path.line(to: NSPoint(x: center.x, y: center.y - radius))
    path.line(to: NSPoint(x: center.x - radius * 0.28, y: center.y - radius * 0.28))
    path.line(to: NSPoint(x: center.x - radius, y: center.y))
    path.line(to: NSPoint(x: center.x - radius * 0.28, y: center.y + radius * 0.28))
    path.close()
    color.setFill()
    path.fill()
}

drawSparkle(center: NSPoint(x: 790, y: 790), radius: 72, color: NSColor(calibratedRed: 0.98, green: 0.98, blue: 1.0, alpha: 0.95))
drawSparkle(center: NSPoint(x: 705, y: 870), radius: 34, color: NSColor(calibratedRed: 0.89, green: 0.97, blue: 1.0, alpha: 0.9))

image.unlockFocus()

let outputURL = URL(fileURLWithPath: "/Users/choijihyeon/IdeaProjects/keyboardCleanMac/Resources/AppIcon-1024.png")
if let tiff = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiff),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    try pngData.write(to: outputURL)
    print("Wrote \(outputURL.path)")
} else {
    fputs("Failed to generate icon\n", stderr)
    exit(1)
}
