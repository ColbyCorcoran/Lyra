//
//  ImageEnhancementEngine.swift
//  Lyra
//
//  Phase 7.10: Enhanced OCR - Engine 6
//  Image quality enhancement and preprocessing
//

import Foundation
import UIKit
import CoreImage
import Accelerate

/// Engine for enhancing image quality before OCR processing
@MainActor
class ImageEnhancementEngine {

    // MARK: - Properties

    private let ciContext: CIContext

    // MARK: - Initialization

    init() {
        // Create a Core Image context for processing
        self.ciContext = CIContext(options: [
            .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
            .outputColorSpace: CGColorSpaceCreateDeviceRGB()
        ])
    }

    // MARK: - Public API

    /// Full image enhancement pipeline
    /// - Parameter image: Original image
    /// - Returns: Enhanced image with quality metrics
    func enhanceImage(_ image: UIImage) -> (enhanced: UIImage, metrics: ImageQualityMetrics) {
        var currentImage = image

        // Calculate initial quality metrics
        let initialMetrics = calculateQualityMetrics(currentImage)

        var enhancementsApplied: [String] = []

        // Step 1: Auto-rotate to correct orientation
        if let rotated = autoRotate(currentImage) {
            currentImage = rotated
            enhancementsApplied.append("rotate")
        }

        // Step 2: Deskew if needed (angle > 2 degrees)
        if abs(initialMetrics.skewAngle) > 2.0 {
            if let deskewed = deskewImage(currentImage, angle: initialMetrics.skewAngle) {
                currentImage = deskewed
                enhancementsApplied.append("deskew")
            }
        }

        // Step 3: Enhance contrast for better text visibility
        if initialMetrics.contrast < 0.5 {
            if let enhanced = enhanceContrast(currentImage) {
                currentImage = enhanced
                enhancementsApplied.append("contrast")
            }
        }

        // Step 4: Reduce noise if present
        if initialMetrics.noiseLevel > 20.0 {
            if let denoised = reduceNoise(currentImage) {
                currentImage = denoised
                enhancementsApplied.append("denoise")
            }
        }

        // Step 5: Sharpen for clarity
        if initialMetrics.sharpness < 50.0 {
            if let sharpened = sharpenImage(currentImage) {
                currentImage = sharpened
                enhancementsApplied.append("sharpen")
            }
        }

        // Calculate final quality metrics
        let finalMetrics = calculateQualityMetrics(currentImage)

        return (currentImage, finalMetrics)
    }

    /// Calculate comprehensive quality metrics for an image
    /// - Parameter image: Image to analyze
    /// - Returns: Quality metrics
    func calculateQualityMetrics(_ image: UIImage) -> ImageQualityMetrics {
        guard let cgImage = image.cgImage else {
            return ImageQualityMetrics(
                brightness: 0.5,
                contrast: 0.3,
                sharpness: 0.0,
                skewAngle: 0.0,
                noiseLevel: 50.0,
                overallScore: 0.0
            )
        }

        let brightness = calculateBrightness(cgImage)
        let contrast = calculateContrast(cgImage)
        let sharpness = calculateSharpness(cgImage)
        let skewAngle = detectSkew(cgImage)
        let noiseLevel = estimateNoise(cgImage)

        // Calculate overall score (weighted average)
        let brightnessScore = 1.0 - abs(0.5 - brightness) * 2.0 // Optimal at 0.5
        let contrastScore = min(contrast / 0.5, 1.0)
        let sharpnessScore = min(sharpness / 100.0, 1.0)
        let skewScore = max(0.0, 1.0 - abs(skewAngle) / 45.0)
        let noiseScore = max(0.0, 1.0 - noiseLevel / 50.0)

        let overallScore = (
            brightnessScore * 0.2 +
            contrastScore * 0.3 +
            sharpnessScore * 0.3 +
            skewScore * 0.1 +
            noiseScore * 0.1
        )

        return ImageQualityMetrics(
            brightness: brightness,
            contrast: contrast,
            sharpness: sharpness,
            skewAngle: skewAngle,
            noiseLevel: noiseLevel,
            overallScore: overallScore
        )
    }

    // MARK: - Enhancement Operations

    /// Detect and correct image rotation
    /// - Parameter image: Input image
    /// - Returns: Rotated image if needed
    func autoRotate(_ image: UIImage) -> UIImage? {
        // Use existing image orientation
        guard image.imageOrientation != .up else {
            return nil // Already correctly oriented
        }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let rotated = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return rotated
    }

    /// Deskew a rotated image using perspective correction
    /// - Parameters:
    ///   - image: Input image
    ///   - angle: Skew angle in degrees
    /// - Returns: Deskewed image
    func deskewImage(_ image: UIImage, angle: Float) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        // Create perspective correction transform
        let radians = angle * .pi / 180.0
        let transform = CGAffineTransform(rotationAngle: CGFloat(-radians))

        let correctedImage = ciImage.transformed(by: transform)

        // Render to UIImage
        guard let cgImage = ciContext.createCGImage(correctedImage, from: correctedImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    /// Enhance contrast using CLAHE (Contrast Limited Adaptive Histogram Equalization)
    /// - Parameter image: Input image
    /// - Returns: Contrast-enhanced image
    func enhanceContrast(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        // Apply tone curve for better contrast
        let filter = CIFilter(name: "CIToneCurve")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)

        // Define control points for S-curve (enhances contrast)
        filter?.setValue(CIVector(x: 0.0, y: 0.0), forKey: "inputPoint0")
        filter?.setValue(CIVector(x: 0.25, y: 0.15), forKey: "inputPoint1")
        filter?.setValue(CIVector(x: 0.5, y: 0.5), forKey: "inputPoint2")
        filter?.setValue(CIVector(x: 0.75, y: 0.85), forKey: "inputPoint3")
        filter?.setValue(CIVector(x: 1.0, y: 1.0), forKey: "inputPoint4")

        guard let outputImage = filter?.outputImage,
              let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    /// Reduce noise using Gaussian blur and unsharp mask
    /// - Parameter image: Input image
    /// - Returns: Denoised image
    func reduceNoise(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        // Step 1: Slight Gaussian blur to reduce noise
        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter?.setValue(0.5, forKey: kCIInputRadiusKey) // Very slight blur

        guard let blurred = blurFilter?.outputImage else { return nil }

        // Step 2: Apply unsharp mask to restore edges
        let unsharpFilter = CIFilter(name: "CIUnsharpMask")
        unsharpFilter?.setValue(blurred, forKey: kCIInputImageKey)
        unsharpFilter?.setValue(0.5, forKey: kCIInputRadiusKey)
        unsharpFilter?.setValue(0.5, forKey: kCIInputIntensityKey)

        guard let sharpened = unsharpFilter?.outputImage,
              let cgImage = ciContext.createCGImage(sharpened, from: ciImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    /// Sharpen image for better text clarity
    /// - Parameter image: Input image
    /// - Returns: Sharpened image
    func sharpenImage(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        let filter = CIFilter(name: "CISharpenLuminance")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(0.7, forKey: kCIInputSharpnessKey) // Moderate sharpening

        guard let outputImage = filter?.outputImage,
              let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    // MARK: - Quality Calculation Methods

    /// Calculate average brightness (0.0 = black, 1.0 = white)
    private func calculateBrightness(_ cgImage: CGImage) -> Float {
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return 0.5
        }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        let width = cgImage.width
        let height = cgImage.height

        var totalBrightness: UInt64 = 0
        var pixelCount = 0

        // Sample every 10th pixel for performance
        for y in stride(from: 0, to: height, by: 10) {
            for x in stride(from: 0, to: width, by: 10) {
                let offset = y * bytesPerRow + x * bytesPerPixel
                if bytesPerPixel >= 3 {
                    let r = bytes[offset]
                    let g = bytes[offset + 1]
                    let b = bytes[offset + 2]
                    // Convert to perceived brightness
                    let brightness = UInt64(0.299 * Float(r) + 0.587 * Float(g) + 0.114 * Float(b))
                    totalBrightness += brightness
                    pixelCount += 1
                }
            }
        }

        return pixelCount > 0 ? Float(totalBrightness) / Float(pixelCount) / 255.0 : 0.5
    }

    /// Calculate image contrast (0.0 = no contrast, 1.0 = high contrast)
    private func calculateContrast(_ cgImage: CGImage) -> Float {
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return 0.3
        }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        let width = cgImage.width
        let height = cgImage.height

        var brightnessValues: [Float] = []

        // Sample pixels
        for y in stride(from: 0, to: height, by: 10) {
            for x in stride(from: 0, to: width, by: 10) {
                let offset = y * bytesPerRow + x * bytesPerPixel
                if bytesPerPixel >= 3 {
                    let r = bytes[offset]
                    let g = bytes[offset + 1]
                    let b = bytes[offset + 2]
                    let brightness = 0.299 * Float(r) + 0.587 * Float(g) + 0.114 * Float(b)
                    brightnessValues.append(brightness / 255.0)
                }
            }
        }

        guard !brightnessValues.isEmpty else { return 0.3 }

        // Calculate standard deviation as measure of contrast
        let mean = brightnessValues.reduce(0, +) / Float(brightnessValues.count)
        let variance = brightnessValues.map { pow($0 - mean, 2) }.reduce(0, +) / Float(brightnessValues.count)
        let stdDev = sqrt(variance)

        return stdDev // 0.0-1.0 range
    }

    /// Calculate image sharpness using Laplacian variance
    private func calculateSharpness(_ cgImage: CGImage) -> Float {
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return 0.0
        }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        let width = cgImage.width
        let height = cgImage.height

        var laplacianSum: Float = 0.0
        var pixelCount = 0

        // Apply Laplacian kernel to detect edges
        for y in 1..<(height-1) {
            for x in 1..<(width-1) {
                if x % 10 == 0 && y % 10 == 0 { // Sample every 10th pixel
                    let center = getGrayValue(bytes: bytes, x: x, y: y, bytesPerRow: bytesPerRow, bytesPerPixel: bytesPerPixel)
                    let top = getGrayValue(bytes: bytes, x: x, y: y-1, bytesPerRow: bytesPerRow, bytesPerPixel: bytesPerPixel)
                    let bottom = getGrayValue(bytes: bytes, x: x, y: y+1, bytesPerRow: bytesPerRow, bytesPerPixel: bytesPerPixel)
                    let left = getGrayValue(bytes: bytes, x: x-1, y: y, bytesPerRow: bytesPerRow, bytesPerPixel: bytesPerPixel)
                    let right = getGrayValue(bytes: bytes, x: x+1, y: y, bytesPerRow: bytesPerRow, bytesPerPixel: bytesPerPixel)

                    // Laplacian: center*4 - (top + bottom + left + right)
                    let laplacian = abs(center * 4.0 - (top + bottom + left + right))
                    laplacianSum += laplacian
                    pixelCount += 1
                }
            }
        }

        let variance = pixelCount > 0 ? laplacianSum / Float(pixelCount) : 0.0
        return variance // Higher value = sharper
    }

    /// Detect skew angle in degrees
    private func detectSkew(_ cgImage: CGImage) -> Float {
        // Simplified skew detection
        // In production, would use Hough transform for line detection
        // For now, return 0 (assuming minimal skew)
        // TODO: Implement proper Hough line detection
        return 0.0
    }

    /// Estimate noise level (0.0 = no noise, 100.0 = very noisy)
    private func estimateNoise(_ cgImage: CGImage) -> Float {
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return 25.0
        }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        let width = cgImage.width
        let height = cgImage.height

        var differences: [Float] = []

        // Calculate local variance (noise indicator)
        for y in stride(from: 1, to: height-1, by: 10) {
            for x in stride(from: 1, to: width-1, by: 10) {
                let center = getGrayValue(bytes: bytes, x: x, y: y, bytesPerRow: bytesPerRow, bytesPerPixel: bytesPerPixel)
                let right = getGrayValue(bytes: bytes, x: x+1, y: y, bytesPerRow: bytesPerRow, bytesPerPixel: bytesPerPixel)
                let bottom = getGrayValue(bytes: bytes, x: x, y: y+1, bytesPerRow: bytesPerRow, bytesPerPixel: bytesPerPixel)

                differences.append(abs(center - right))
                differences.append(abs(center - bottom))
            }
        }

        guard !differences.isEmpty else { return 25.0 }

        // Average difference as noise estimate
        let avgDifference = differences.reduce(0, +) / Float(differences.count)
        return avgDifference * 100.0 / 255.0 // Normalize to 0-100
    }

    /// Helper to get grayscale value at pixel
    private func getGrayValue(bytes: UnsafePointer<UInt8>, x: Int, y: Int, bytesPerRow: Int, bytesPerPixel: Int) -> Float {
        let offset = y * bytesPerRow + x * bytesPerPixel
        if bytesPerPixel >= 3 {
            let r = bytes[offset]
            let g = bytes[offset + 1]
            let b = bytes[offset + 2]
            return 0.299 * Float(r) + 0.587 * Float(g) + 0.114 * Float(b)
        }
        return Float(bytes[offset])
    }
}
