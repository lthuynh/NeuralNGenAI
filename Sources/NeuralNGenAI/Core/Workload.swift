import Foundation

// MARK: - Workload Types

/// Represents different types of workloads that Neural NGen AI can process
public enum WorkloadType: CaseIterable {
    case naturalLanguageProcessing
    case imageProcessing
    case audioProcessing
    case dataAnalysis
    case machineLearning
}

/// Complexity levels for workload processing
public enum WorkloadComplexity: CaseIterable {
    case low
    case medium
    case high
}

/// Priority levels for workload scheduling
public enum WorkloadPriority: CaseIterable {
    case low
    case normal
    case high
    case critical
}

// MARK: - Workload

/// Core workload structure for Neural NGen AI processing
public struct Workload {
    public let id: UUID
    public let type: WorkloadType
    public let complexity: WorkloadComplexity
    public let priority: WorkloadPriority
    public let data: Data
    public let metadata: [String: Any]
    public let createdAt: Date
    
    public init(
        type: WorkloadType,
        complexity: WorkloadComplexity,
        priority: WorkloadPriority,
        data: Data,
        metadata: [String: Any] = [:]
    ) {
        self.id = UUID()
        self.type = type
        self.complexity = complexity
        self.priority = priority
        self.data = data
        self.metadata = metadata
        self.createdAt = Date()
    }
}

// MARK: - Workload Result

/// Result of processing a workload through Neural NGen AI
public struct WorkloadResult {
    public let output: String
    public let confidence: Double
    public let hardwareUtilization: HardwareUtilization
    public let executionTime: TimeInterval
    public let metadata: [String: Any]
    
    public init(
        output: String,
        confidence: Double,
        hardwareUtilization: HardwareUtilization,
        executionTime: TimeInterval,
        metadata: [String: Any] = [:]
    ) {
        self.output = output
        self.confidence = confidence
        self.hardwareUtilization = hardwareUtilization
        self.executionTime = executionTime
        self.metadata = metadata
    }
}

// MARK: - Hardware Utilization

/// Tracks hardware utilization during workload processing
public struct HardwareUtilization {
    public let cpuUtilization: Double?
    public let gpuUtilization: Double?
    public let neuralEngineUtilization: Double?
    public let memoryUtilization: Double?
    public let thermalImpact: ThermalImpact
    
    public init(
        cpuUtilization: Double? = nil,
        gpuUtilization: Double? = nil,
        neuralEngineUtilization: Double? = nil,
        memoryUtilization: Double? = nil,
        thermalImpact: ThermalImpact = .minimal
    ) {
        self.cpuUtilization = cpuUtilization
        self.gpuUtilization = gpuUtilization
        self.neuralEngineUtilization = neuralEngineUtilization
        self.memoryUtilization = memoryUtilization
        self.thermalImpact = thermalImpact
    }
}

/// Thermal impact levels
public enum ThermalImpact {
    case minimal
    case low
    case moderate
    case high
}

// MARK: - Workload Manager

/// Manages workload queue and scheduling for Neural NGen AI
public final class WorkloadManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var queuedWorkloads: [Workload] = []
    @Published public private(set) var processingWorkload: Workload?
    @Published public private(set) var completedWorkloads: Int = 0
    
    // MARK: - Private Properties
    private var workloadQueue: [Workload] = []
    private let queueLock = NSLock()
    private var isProcessing = false
    
    // MARK: - Queue Management
    
    /// Add a workload to the processing queue
    public func enqueue(_ workload: Workload) {
        queueLock.withLock {
            workloadQueue.append(workload)
            workloadQueue.sort { $0.priority.sortOrder > $1.priority.sortOrder }
        }
        
        updatePublishedProperties()
    }
    
    /// Add multiple workloads to the processing queue
    public func enqueueBatch(_ workloads: [Workload]) {
        queueLock.withLock {
            workloadQueue.append(contentsOf: workloads)
            workloadQueue.sort { $0.priority.sortOrder > $1.priority.sortOrder }
        }
        
        updatePublishedProperties()
    }
    
    /// Get the next workload to process
    public func dequeue() -> Workload? {
        return queueLock.withLock {
            return workloadQueue.isEmpty ? nil : workloadQueue.removeFirst()
        }
    }
    
    /// Get workloads by priority level
    public func getWorkloads(withPriority priority: WorkloadPriority) -> [Workload] {
        return queueLock.withLock {
            return workloadQueue.filter { $0.priority == priority }
        }
    }
    
    /// Get workloads by type
    public func getWorkloads(ofType type: WorkloadType) -> [Workload] {
        return queueLock.withLock {
            return workloadQueue.filter { $0.type == type }
        }
    }
    
    /// Clear all queued workloads
    public func clearQueue() {
        queueLock.withLock {
            workloadQueue.removeAll()
        }
        updatePublishedProperties()
    }
    
    /// Set the currently processing workload
    public func setProcessingWorkload(_ workload: Workload?) {
        DispatchQueue.main.async {
            self.processingWorkload = workload
        }
    }
    
    /// Mark a workload as completed
    public func markCompleted() {
        DispatchQueue.main.async {
            self.completedWorkloads += 1
            self.processingWorkload = nil
        }
    }
    
    // MARK: - Queue Statistics
    
    /// Get current queue statistics
    public func getQueueStatistics() -> QueueStatistics {
        return queueLock.withLock {
            let totalCount = workloadQueue.count
            let priorityCounts = Dictionary(grouping: workloadQueue, by: { $0.priority })
                .mapValues { $0.count }
            let typeCounts = Dictionary(grouping: workloadQueue, by: { $0.type })
                .mapValues { $0.count }
            let complexityCounts = Dictionary(grouping: workloadQueue, by: { $0.complexity })
                .mapValues { $0.count }
            
            return QueueStatistics(
                totalCount: totalCount,
                priorityCounts: priorityCounts,
                typeCounts: typeCounts,
                complexityCounts: complexityCounts,
                averageAge: calculateAverageAge()
            )
        }
    }
    
    private func calculateAverageAge() -> TimeInterval {
        guard !workloadQueue.isEmpty else { return 0 }
        
        let now = Date()
        let totalAge = workloadQueue.reduce(0) { $0 + now.timeIntervalSince($1.createdAt) }
        return totalAge / Double(workloadQueue.count)
    }
    
    private func updatePublishedProperties() {
        DispatchQueue.main.async {
            self.queuedWorkloads = self.queueLock.withLock { Array(self.workloadQueue) }
        }
    }
}

// MARK: - Queue Statistics

/// Statistics about the workload queue
public struct QueueStatistics {
    public let totalCount: Int
    public let priorityCounts: [WorkloadPriority: Int]
    public let typeCounts: [WorkloadType: Int]
    public let complexityCounts: [WorkloadComplexity: Int]
    public let averageAge: TimeInterval
    
    public init(
        totalCount: Int,
        priorityCounts: [WorkloadPriority: Int],
        typeCounts: [WorkloadType: Int],
        complexityCounts: [WorkloadComplexity: Int],
        averageAge: TimeInterval
    ) {
        self.totalCount = totalCount
        self.priorityCounts = priorityCounts
        self.typeCounts = typeCounts
        self.complexityCounts = complexityCounts
        self.averageAge = averageAge
    }
}

// MARK: - Extensions

extension WorkloadPriority {
    /// Sort order for priority-based queue management
    public var sortOrder: Int {
        switch self {
        case .critical: return 4
        case .high: return 3
        case .normal: return 2
        case .low: return 1
        }
    }
    
    /// Human-readable description
    public var description: String {
        switch self {
        case .critical: return "Critical"
        case .high: return "High"
        case .normal: return "Normal"
        case .low: return "Low"
        }
    }
}

extension WorkloadType {
    /// Human-readable description
    public var description: String {
        switch self {
        case .naturalLanguageProcessing: return "Natural Language Processing"
        case .imageProcessing: return "Image Processing"
        case .audioProcessing: return "Audio Processing"
        case .dataAnalysis: return "Data Analysis"
        case .machineLearning: return "Machine Learning"
        }
    }
    
    /// Estimated base complexity for the workload type
    public var baseComplexity: WorkloadComplexity {
        switch self {
        case .naturalLanguageProcessing, .machineLearning: return .high
        case .imageProcessing, .audioProcessing: return .medium
        case .dataAnalysis: return .low
        }
    }
}

extension WorkloadComplexity {
    /// Human-readable description
    public var description: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"  
        case .high: return "High"
        }
    }
    
    /// Estimated processing time multiplier
    public var processingMultiplier: Double {
        switch self {
        case .low: return 1.0
        case .medium: return 2.0
        case .high: return 4.0
        }
    }
}

extension ThermalImpact {
    /// Human-readable description
    public var description: String {
        switch self {
        case .minimal: return "Minimal"
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        }
    }
}

// MARK: - NSLock Extension

extension NSLock {
    /// Execute a closure while holding the lock
    func withLock<T>(_ closure: () -> T) -> T {
        lock()
        defer { unlock() }
        return closure()
    }
}
