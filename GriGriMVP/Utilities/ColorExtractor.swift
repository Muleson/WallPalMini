//
//  ColorExtractor.swift
//  GriGriMVP
//
//  Utility for extracting prominent colors from images
//

import SwiftUI
import UIKit

/// Utility class for extracting prominent colors from images
class ColorExtractor {

    /// Options for color extraction
    struct ExtractionOptions {
        /// Number of colors to analyze (higher = more accurate but slower)
        let sampleSize: Int
        /// Whether to exclude very dark or very light colors
        let excludeExtremes: Bool
        /// Minimum saturation threshold (0.0-1.0)
        let minSaturation: Double

        static let `default` = ExtractionOptions(
            sampleSize: 10,
            excludeExtremes: true,
            minSaturation: 0.2
        )

        static let fast = ExtractionOptions(
            sampleSize: 5,
            excludeExtremes: true,
            minSaturation: 0.15
        )

        static let accurate = ExtractionOptions(
            sampleSize: 20,
            excludeExtremes: true,
            minSaturation: 0.25
        )
    }

    /// Extract the most prominent color from a UIImage
    /// - Parameters:
    ///   - image: The image to analyze
    ///   - options: Extraction options
    /// - Returns: The prominent color, or nil if extraction fails
    static func extractProminentColor(from image: UIImage, options: ExtractionOptions = .default) -> Color? {
        guard let cgImage = image.cgImage else { return nil }

        // Resize image to a smaller size for faster processing
        let size = CGSize(width: 150, height: 150)
        guard let resizedImage = resizeImage(image, to: size) else { return nil }
        guard let resizedCGImage = resizedImage.cgImage else { return nil }

        // Create color space and context
        let width = Int(resizedCGImage.width)
        let height = Int(resizedCGImage.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(resizedCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Extract colors using k-means-like clustering
        var colorBuckets: [ColorBucket] = []
        let sampleInterval = max(1, (width * height) / 1000) // Sample ~1000 pixels

        for y in stride(from: 0, to: height, by: Int(sqrt(Double(sampleInterval)))) {
            for x in stride(from: 0, to: width, by: Int(sqrt(Double(sampleInterval)))) {
                let pixelIndex = (y * width + x) * bytesPerPixel

                guard pixelIndex + 2 < pixelData.count else { continue }

                let r = Double(pixelData[pixelIndex]) / 255.0
                let g = Double(pixelData[pixelIndex + 1]) / 255.0
                let b = Double(pixelData[pixelIndex + 2]) / 255.0
                let a = Double(pixelData[pixelIndex + 3]) / 255.0

                // Skip transparent pixels
                guard a > 0.5 else { continue }

                let uiColor = UIColor(red: r, green: g, blue: b, alpha: 1.0)

                // Skip extreme colors if requested
                if options.excludeExtremes {
                    let brightness = (r + g + b) / 3.0
                    if brightness < 0.15 || brightness > 0.85 {
                        continue
                    }
                }

                // Check saturation
                var hue: CGFloat = 0
                var saturation: CGFloat = 0
                var brightness: CGFloat = 0
                uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)

                if Double(saturation) < options.minSaturation {
                    continue
                }

                // Add to closest bucket or create new bucket
                if let closestBucketIndex = findClosestBucket(
                    for: (r, g, b),
                    in: colorBuckets,
                    threshold: 0.2
                ) {
                    colorBuckets[closestBucketIndex].add(color: (r, g, b))
                } else {
                    colorBuckets.append(ColorBucket(color: (r, g, b)))
                }
            }
        }

        // Find the bucket with the most pixels
        guard let dominantBucket = colorBuckets.max(by: { $0.count < $1.count }) else {
            return nil
        }

        let avgColor = dominantBucket.averageColor()
        return Color(red: avgColor.0, green: avgColor.1, blue: avgColor.2)
    }

    /// Extract multiple prominent colors from an image
    /// - Parameters:
    ///   - image: The image to analyze
    ///   - count: Number of colors to extract
    ///   - options: Extraction options
    /// - Returns: Array of prominent colors, ordered by prominence
    static func extractProminentColors(
        from image: UIImage,
        count: Int = 3,
        options: ExtractionOptions = .default
    ) -> [Color] {
        guard let cgImage = image.cgImage else { return [] }

        // Use the same extraction logic but return top N buckets
        let size = CGSize(width: 150, height: 150)
        guard let resizedImage = resizeImage(image, to: size) else { return [] }
        guard let resizedCGImage = resizedImage.cgImage else { return [] }

        let width = Int(resizedCGImage.width)
        let height = Int(resizedCGImage.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }

        context.draw(resizedCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var colorBuckets: [ColorBucket] = []
        let sampleInterval = max(1, (width * height) / 1000)

        for y in stride(from: 0, to: height, by: Int(sqrt(Double(sampleInterval)))) {
            for x in stride(from: 0, to: width, by: Int(sqrt(Double(sampleInterval)))) {
                let pixelIndex = (y * width + x) * bytesPerPixel

                guard pixelIndex + 2 < pixelData.count else { continue }

                let r = Double(pixelData[pixelIndex]) / 255.0
                let g = Double(pixelData[pixelIndex + 1]) / 255.0
                let b = Double(pixelData[pixelIndex + 2]) / 255.0
                let a = Double(pixelData[pixelIndex + 3]) / 255.0

                guard a > 0.5 else { continue }

                let uiColor = UIColor(red: r, green: g, blue: b, alpha: 1.0)

                if options.excludeExtremes {
                    let brightness = (r + g + b) / 3.0
                    if brightness < 0.15 || brightness > 0.85 {
                        continue
                    }
                }

                var hue: CGFloat = 0
                var saturation: CGFloat = 0
                var brightness: CGFloat = 0
                uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)

                if Double(saturation) < options.minSaturation {
                    continue
                }

                if let closestBucketIndex = findClosestBucket(
                    for: (r, g, b),
                    in: colorBuckets,
                    threshold: 0.2
                ) {
                    colorBuckets[closestBucketIndex].add(color: (r, g, b))
                } else {
                    colorBuckets.append(ColorBucket(color: (r, g, b)))
                }
            }
        }

        // Sort buckets by count and take top N
        let topBuckets = colorBuckets.sorted { $0.count > $1.count }.prefix(count)

        return topBuckets.map { bucket in
            let avgColor = bucket.averageColor()
            return Color(red: avgColor.0, green: avgColor.1, blue: avgColor.2)
        }
    }

    // MARK: - Private Helpers

    private static func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        image.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    private static func findClosestBucket(
        for color: (Double, Double, Double),
        in buckets: [ColorBucket],
        threshold: Double
    ) -> Int? {
        var closestIndex: Int?
        var closestDistance = Double.infinity

        for (index, bucket) in buckets.enumerated() {
            let avgColor = bucket.averageColor()
            let distance = colorDistance(color, avgColor)

            if distance < closestDistance && distance < threshold {
                closestDistance = distance
                closestIndex = index
            }
        }

        return closestIndex
    }

    private static func colorDistance(
        _ color1: (Double, Double, Double),
        _ color2: (Double, Double, Double)
    ) -> Double {
        let rDiff = color1.0 - color2.0
        let gDiff = color1.1 - color2.1
        let bDiff = color1.2 - color2.2
        return sqrt(rDiff * rDiff + gDiff * gDiff + bDiff * bDiff)
    }
}

// MARK: - ColorBucket

/// Helper class for grouping similar colors
private class ColorBucket {
    private var colors: [(Double, Double, Double)] = []

    var count: Int { colors.count }

    init(color: (Double, Double, Double)) {
        colors.append(color)
    }

    func add(color: (Double, Double, Double)) {
        colors.append(color)
    }

    func averageColor() -> (Double, Double, Double) {
        guard !colors.isEmpty else { return (0, 0, 0) }

        let sum = colors.reduce((0.0, 0.0, 0.0)) { result, color in
            (result.0 + color.0, result.1 + color.1, result.2 + color.2)
        }

        let count = Double(colors.count)
        return (sum.0 / count, sum.1 / count, sum.2 / count)
    }
}
