//
//  DetectedObject.swift
//  VideoAnalysisSDK
//
//  检测对象模型

import Foundation
import CoreGraphics
import Vision

/// 检测到的对象
public struct DetectedObject {
    public let label: String
    public let confidence: Float
    public let boundingBox: BoundingBox
    public let visionObservation: VNRecognizedObjectObservation?
    public let timestamp: TimeInterval?
    
    public init(
        label: String,
        confidence: Float,
        boundingBox: BoundingBox,
        visionObservation: VNRecognizedObjectObservation? = nil,
        timestamp: TimeInterval? = nil
    ) {
        self.label = label
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.visionObservation = visionObservation
        self.timestamp = timestamp
    }
    
    public init(from observation: VNRecognizedObjectObservation, timestamp: TimeInterval? = nil) {
        self.label = observation.labels.first?.identifier ?? "unknown"
        self.confidence = observation.confidence
        self.boundingBox = BoundingBox(
            x: observation.boundingBox.origin.x,
            y: observation.boundingBox.origin.y,
            width: observation.boundingBox.width,
            height: observation.boundingBox.height
        )
        self.visionObservation = observation
        self.timestamp = timestamp
    }
}

/// 边界框（归一化坐标）
public struct BoundingBox {
    public let x: CGFloat
    public let y: CGFloat
    public let width: CGFloat
    public let height: CGFloat
    
    public init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
    
    public var centerX: CGFloat { x + width / 2 }
    public var centerY: CGFloat { y + height / 2 }
    public var rect: CGRect { CGRect(x: x, y: y, width: width, height: height) }
    
    public func iou(with other: BoundingBox) -> CGFloat {
        let intersection = self.rect.intersection(other.rect)
        if intersection.isEmpty { return 0 }
        
        let intersectionArea = intersection.width * intersection.height
        let unionArea = self.rect.width * self.rect.height +
                       other.rect.width * other.rect.height -
                       intersectionArea
        return intersectionArea / unionArea
    }
    
    public func distance(to other: BoundingBox) -> CGFloat {
        let dx = centerX - other.centerX
        let dy = centerY - other.centerY
        return sqrt(dx * dx + dy * dy)
    }
}

extension DetectedObject: Codable {
    enum CodingKeys: String, CodingKey {
        case label, confidence, boundingBox, timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try container.decode(String.self, forKey: .label)
        confidence = try container.decode(Float.self, forKey: .confidence)
        boundingBox = try container.decode(BoundingBox.self, forKey: .boundingBox)
        timestamp = try container.decodeIfPresent(TimeInterval.self, forKey: .timestamp)
        visionObservation = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(label, forKey: .label)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(boundingBox, forKey: .boundingBox)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
    }
}

extension BoundingBox: Codable {}
