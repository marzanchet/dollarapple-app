// Generates AppIcon.icns: a green rounded square with a white dollar sign.
// Run: swift Packaging/make-icon.swift Packaging/AppIcon.icns
import AppKit

func render(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    let rect = NSRect(x: 0, y: 0, width: size, height: size).insetBy(dx: size * 0.06, dy: size * 0.06)
    let path = NSBezierPath(roundedRect: rect, xRadius: size * 0.22, yRadius: size * 0.22)
    NSGradient(colors: [NSColor(calibratedRed: 0.13, green: 0.62, blue: 0.36, alpha: 1),
                        NSColor(calibratedRed: 0.05, green: 0.40, blue: 0.24, alpha: 1)])!
        .draw(in: path, angle: -90)
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let font = NSFont.systemFont(ofSize: size * 0.66, weight: .bold)
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white, .paragraphStyle: paragraph]
    let text = NSAttributedString(string: "$", attributes: attrs)
    let textSize = text.size()
    text.draw(in: NSRect(x: 0, y: (size - textSize.height) / 2 - size * 0.01, width: size, height: textSize.height))
    image.unlockFocus()
    return image
}

func png(_ image: NSImage, pixels: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    render(size: CGFloat(pixels)).draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.icns"
let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: tmp)
try! FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try! png(render(size: CGFloat(base)), pixels: base).write(to: tmp.appendingPathComponent("icon_\(base)x\(base).png"))
    try! png(render(size: CGFloat(base * 2)), pixels: base * 2).write(to: tmp.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", tmp.path, "-o", output]
try! task.run()
task.waitUntilExit()
print(task.terminationStatus == 0 ? "wrote \(output)" : "iconutil failed")
