import Foundation
import os

/// Monitors system resources for Neural NGen AI
public final class ResourceMonitor {
    private let logger = Logger(subsystem: "com.neuralngenai.resources", category: "monitor")
    private var monitoringTask: Task<Void, Never>?
    
    public private(set) var currentMemoryPressure: Double = 0.0
    
    public func startMonitoring(updateCallback: @escaping () -> Void) async {
        logger.info("🔍 Neural NGen AI Resource Monitor started")
        
        monitoringTask = Task {
            while !Task.isCancelled {
                await updateResourceMetrics()
                updateCallback()
                
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
    }
    
    public func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
        logger.info("Resource monitoring stopped")
    }
    
    private func updateResourceMetrics() async {
        // Update current memory pressure
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let availableMemory = await getAvailableMemory()
        currentMemoryPressure = Double(totalMemory - availableMemory) / Double(totalMemory)
    }
    
    private func getAvailableMemory() async -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? UInt64(info.resident_size) : 0
    }
}
