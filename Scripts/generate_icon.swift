import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - 配置
let size = 1024

// 暮色紫 #372f52
let bgColor = CGColor(
    red: 0x37 / 255.0,
    green: 0x2F / 255.0,
    blue: 0x52 / 255.0,
    alpha: 1.0
)

// 暖白 #f0e6d2
let moonColor = CGColor(
    red: 0xF0 / 255.0,
    green: 0xE6 / 255.0,
    blue: 0xD2 / 255.0,
    alpha: 1.0
)

// MARK: - 月牙几何参数
// 两个圆形布尔相减：CircleA - CircleB = 月牙
// 不对称设计：不同半径 + 对角线偏移
let centerX: CGFloat = 512
let centerY: CGFloat = 510
let radiusA: CGFloat = 285  // 外圈（稍大）
let radiusB: CGFloat = 255  // 内圈（稍小）

// 偏移：右下方向 → 月牙粗端在左上，细端在右下
let offsetX: CGFloat = 65
let offsetY: CGFloat = 55

// MARK: - 渲染
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

// 2. 画月牙（even-odd fill 实现布尔相减）
let path = CGMutablePath()

// Circle A（正向圆）
path.addArc(
    center: CGPoint(x: centerX, y: centerY),
    radius: radiusA,
    startAngle: 0,
    endAngle: 2 * .pi,
    clockwise: false
)
path.closeSubpath()

// Circle B（减去圆）
path.addArc(
    center: CGPoint(x: centerX + offsetX, y: centerY + offsetY),
    radius: radiusB,
    startAngle: 0,
    endAngle: 2 * .pi,
    clockwise: false
)
path.closeSubpath()

context.setFillColor(moonColor)
context.addPath(path)
context.fillPath(using: .evenOdd)

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
print("   Moon: CircleA(center:\(Int(centerX)),\(Int(centerY)) r:\(Int(radiusA))) - CircleB(r:\(Int(radiusB)) offset:\(Int(offsetX)),\(Int(offsetY)))")
