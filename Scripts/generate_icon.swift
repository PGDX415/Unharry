import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
import AppKit

// MARK: - 配置
let size = 1024

// 暮色紫 #372f52（与 App 背景一致）
let bgColor = CGColor(
    red: 0x37 / 255.0,
    green: 0x2F / 255.0,
    blue: 0x52 / 255.0,
    alpha: 1.0
)

// 金色 #E8C547
let accentColor = CGColor(
    red: 0xE8 / 255.0,
    green: 0xC5 / 255.0,
    blue: 0x47 / 255.0,
    alpha: 1.0
)

// MARK: - 渲染 SF Symbol

let symbolName = "moon.stars.fill"
let pointSize: CGFloat = 280

// 使用 AppKit 渲染 SF Symbol
let config = NSImage.SymbolConfiguration(
    pointSize: pointSize,
    weight: .regular,
    scale: .large
)
guard let symbolImage = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
    .withSymbolConfiguration(config)
else {
    print("ERROR: Failed to load SF Symbol: \(symbolName)")
    exit(1)
}

// 着色
let tinted = NSImage(size: symbolImage.size)
tinted.lockFocus()
NSColor(cgColor: accentColor)?.set()
NSRect(origin: .zero, size: symbolImage.size).fill()
symbolImage.draw(
    in: NSRect(origin: .zero, size: symbolImage.size),
    from: .zero,
    operation: .destinationIn,
    fraction: 1.0
)
tinted.unlockFocus()

guard let tintedCGImage = tinted.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("ERROR: Failed to get CGImage from tinted NSImage")
    exit(1)
}

// MARK: - 绘制到上下文

let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
guard let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    print("ERROR: Failed to create CGContext")
    exit(1)
}

// 1. 填充背景
context.setFillColor(bgColor)
context.fill(CGRect(x: 0, y: 0, width: size, height: size))

// 2. 居中绘制 SF Symbol
let iconWidth = CGFloat(tintedCGImage.width)
let iconHeight = CGFloat(tintedCGImage.height)
let iconRect = CGRect(
    x: (CGFloat(size) - iconWidth) / 2,
    y: (CGFloat(size) - iconHeight) / 2,
    width: iconWidth,
    height: iconHeight
)
context.draw(tintedCGImage, in: iconRect)

// 3. 导出
guard let image = context.makeImage() else {
    print("ERROR: Failed to create CGImage")
    exit(1)
}

let outputURL = URL(fileURLWithPath: "/tmp/app_icon_1024.png")
guard let destination = CGImageDestinationCreateWithURL(
    outputURL as CFURL,
    UTType.png.identifier as CFString,
    1,
    nil
) else {
    print("ERROR: Failed to create image destination")
    exit(1)
}

CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    print("ERROR: Failed to write PNG")
    exit(1)
}

print("✅ Icon generated: \(outputURL.path)")
print("   Size: \(image.width)×\(image.height)")
print("   Symbol: \(symbolName) @ \(Int(pointSize))pt")
