import Foundation
import os

extension OSLog {
    
    static let mapKitSubsystem = "ru.demo.ymapkit"
    static let mapkitLog = OSLog(
        subsystem: mapKitSubsystem,
        category: OSLog.Category.pointsOfInterest
    )
}
