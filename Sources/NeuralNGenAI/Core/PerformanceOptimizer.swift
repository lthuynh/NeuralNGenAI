import Foundation
import CoreML
import Metal
import MetalPerformanceShaders
import os

/// Main performance optimization engine that distributes workloads across available hardware
public final class PerformanceOptimizer: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = PerformanceOptimizer()
    
    // MARK: - Published Properties
    @Published public private(set) var isOptimizing = false
    @Published public private(set) var currentWorkload: WorkloadInfo?
    @Published public private(set) var optimizationMetrics: OptimizationMetrics?
    
    // MARK: - Core Components
    private let logger = Logger(subsystem: "com.neuralngenai.performance", category: "optimizer")
    private let cpuOptimizer = CPUOptimizer()
    private let gpuOptimizer = GPUOptimizer()
    private let neuralEngineOptimizer = NeuralEngineOptimizer()
    private let memoryOptimizer = MemoryOptimizer()
    
    // MARK: - State
    private var hardwareProfile: HardwareProfile?
    private var workloadQueue: [Workload] = []
    private var isProcessing = false
    
    // MARK: - Performance Tracking
    private var performanceHistory: [PerformanceSnapshot] = []
    private let maxHistorySize = 100
    
    private init() {
        logger.info("🚀 Neural NGen AI Performance Optimizer initialized")
    }
    
    // MARK: - Initialization
    
    /// Initialize the optimizer with hardware profile
    public func initialize(with profile: HardwareProfile?) async {
        logger.info("Initializing performance optimizer with hardware profile")
        
        self.hardwareProfile = profile
        
        guard let profile = profile else {
            logger.error("No hardware profile provided - using defaults")
            return
        }
        
        // Initialize hardware-specific optimizers
        await cpuOptimizer.configure(with: profile.cpuInfo)
        await gpuOptimizer.configure(with: profile.gpuInfo)
        await neuralEngineOptimizer.configure(with: profile.neuralEngineInfo)
        await memoryOptimizer.configure(with: profile.memoryInfo)
        
        logger.info("✅ Performance optimizer configured for optimal Neural NGen AI processing")
    }
    
    // MARK: - Workload Processing
    
    /// Process a workload with optimal hardware allocation
    public func processWorkload(_ workload: Workload) async -> WorkloadResult {
        logger.info("Processing workload: \(workload.type) - \(workload.complexity)")
        
        await MainActor.run {
            isOptimizing = true
            currentWorkload = WorkloadInfo(workload: workload)
        }
        
        defer {
            Task { @MainActor in
                isOptimizing = false
                currentWorkload = nil
            }
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let strategy = determineOptimalStrategy(for: workload)
        
        let result = await executeWorkload(workload, using: strategy)
        
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Record performance metrics
        await recordPerformanceMetrics(
            workload: workload,
            strategy: strategy,
            executionTime: executionTime,
            result: result
        )
        
        logger.info("Workload completed in \(String(format: "%.3f", executionTime))s using \(strategy)")
        
        return result
    }
    
    /// Process multiple workloads concurrently
    public func processWorkloadBatch(_ workloads: [Workload]) async -> [WorkloadResult] {
        logger.info("Processing batch of \(workloads.count) workloads")
        
        return await withTaskGroup(of: WorkloadResult.self) { group in
            for workload in workloads {
                group.addTask {
                    await self.processWorkload(workload)
                }
            }
            
            var results: [WorkloadResult] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }
    
    // MARK: - Strategy Determination
    
    private func determineOptimalStrategy(for workload: Workload) -> ProcessingStrategy {
        guard let profile = hardwareProfile else {
            logger.warning("No hardware profile - using CPU fallback")
            return .cpuOnly
        }
        
        // Determine strategy based on workload type and hardware capabilities
        switch workload.type {
        case .naturalLanguageProcessing:
            return determineNLPStrategy(complexity: workload.complexity, profile: profile)
        case .imageProcessing:
            return determineImageStrategy(complexity: workload.complexity, profile: profile)
        case .audioProcessing:
            return determineAudioStrategy(complexity: workload.complexity, profile: profile)
        case .dataAnalysis:
            return determineDataStrategy(complexity: workload.complexity, profile: profile)
        case .machineLearning:
            return determineMLStrategy(complexity: workload.complexity, profile: profile)
        }
    }
    
    private func determineNLPStrategy(complexity: WorkloadComplexity, profile: HardwareProfile) -> ProcessingStrategy {
        // Prioritize Neural Engine for NLP tasks
        if profile.neuralEngineInfo?.isAvailable == true {
            switch complexity {
            case .low:
                return .neuralEngineOnly
            case .medium:
                return .neuralEnginePlusCPU
            case .high:
                return .hybrid
            }
        }
        
        // Fallback to CPU with GPU assistance
        return complexity == .high ? .cpuPlusGPU : .cpuOnly
    }
    
    private func determineImageStrategy(complexity: WorkloadComplexity, profile: HardwareProfile) -> ProcessingStrategy {
        // Prioritize GPU for image processing
        if profile.gpuInfo?.isAvailable == true {
            return complexity == .high ? .hybrid : .gpuPlusCPU
        }
        
        return .cpuOnly
    }
    
    private func determineAudioStrategy(complexity: WorkloadComplexity, profile: HardwareProfile) -> ProcessingStrategy {
        // Audio processing can benefit from Neural Engine
        if profile.neuralEngineInfo?.isAvailable == true && complexity != .low {
            return .neuralEnginePlusCPU
        }
        
        return .cpuOnly
    }
    
    private func determineDataStrategy(complexity: WorkloadComplexity, profile: HardwareProfile) -> ProcessingStrategy {
        // Data analysis benefits from parallel processing
        switch complexity {
        case .low:
            return .cpuOnly
        case .medium:
            return profile.gpuInfo?.isAvailable == true ? .cpuPlusGPU : .cpuOnly
        case .high:
            return .hybrid
        }
    }
    
    private func determineMLStrategy(complexity: WorkloadComplexity, profile: HardwareProfile) -> ProcessingStrategy {
        // Always use Neural Engine if available for ML
        if profile.neuralEngineInfo?.isAvailable == true {
            return complexity == .high ? .hybrid : .neuralEngineOnly
        }
        
        return profile.gpuInfo?.isAvailable == true ? .cpuPlusGPU : .cpuOnly
    }
    
    // MARK: - Workload Execution
    
    private func executeWorkload(_ workload: Workload, using strategy: ProcessingStrategy) async -> WorkloadResult {
        switch strategy {
        case .cpuOnly:
            return await cpuOptimizer.processWorkload(workload)
            
        case .gpuOnly:
            return await gpuOptimizer.processWorkload(workload)
            
        case .neuralEngineOnly:
            return await neuralEngineOptimizer.processWorkload(workload)
            
        case .cpuPlusGPU:
            return await processCombinedCPUGPU(workload)
            
        case .neuralEnginePlusCPU:
            return await processCombinedNeuralEngineCPU(workload)
            
        case .gpuPlusCPU:
            return await processCombinedGPUCPU(workload)
            
        case .hybrid:
            return await processHybrid(workload)
        }
    }
    
    private func processCombinedCPUGPU(_ workload: Workload) async -> WorkloadResult {
        logger.debug("Processing workload using CPU + GPU strategy")
        
        return await withTaskGroup(of: WorkloadResult.self) { group in
            // Split workload between CPU and GPU
            let cpuPortion = createWorkloadPortion(from: workload, portion: 0.6)
            let gpuPortion = createWorkloadPortion(from: workload, portion: 0.4)
            
            group.addTask { await self.cpuOptimizer.processWorkload(cpuPortion) }
            group.addTask { await self.gpuOptimizer.processWorkload(gpuPortion) }
            
            var results: [WorkloadResult] = []
            for await result in group {
                results.append(result)
            }
            
            return combineResults(results, originalWorkload: workload)
        }
    }
    
    private func processCombinedNeuralEngineCPU(_ workload: Workload) async -> WorkloadResult {
        logger.debug("Processing workload using Neural Engine + CPU strategy")
        
        // Try Neural Engine first, fall back to CPU if needed
        let neResult = await neuralEngineOptimizer.processWorkload(workload)
        
        if neResult.confidence > 0.8 {
            return neResult
        }
        
        // Refine with CPU processing
        let cpuResult = await cpuOptimizer.processWorkload(workload)
        return combineResults([neResult, cpuResult], originalWorkload: workload)
    }
    
    private func processCombinedGPUCPU(_ workload: Workload) async -> WorkloadResult {
        logger.debug("Processing workload using GPU + CPU strategy")
        
        return await withTaskGroup(of: WorkloadResult.self) { group in
            let gpuPortion = createWorkloadPortion(from: workload, portion: 0.7)
            let cpuPortion = createWorkloadPortion(from: workload, portion: 0.3)
            
            group.addTask { await self.gpuOptimizer.processWorkload(gpuPortion) }
            group.addTask { await self.cpuOptimizer.processWorkload(cpuPortion) }
            
            var results: [WorkloadResult] = []
            for await result in group {
                results.append(result)
            }
            
            return combineResults(results, originalWorkload: workload)
        }
    }
    
    private func processHybrid(_ workload: Workload) async -> WorkloadResult {
        logger.debug("Processing workload using hybrid strategy (all hardware)")
        
        return await withTaskGroup(of: WorkloadResult.self) { group in
            // Distribute across all available hardware
            let portions = distributeWorkload(workload)
            
            if let cpuPortion = portions.cpu {
                group.addTask { await self.cpuOptimizer.processWorkload(cpuPortion) }
            }
            
            if let gpuPortion = portions.gpu {
                group.addTask { await self.gpuOptimizer.processWorkload(gpuPortion) }
            }
            
            if let nePortion = portions.neuralEngine {
                group.addTask { await self.neuralEngineOptimizer.processWorkload(nePortion) }
            }
            
            var results: [WorkloadResult] = []
            for await result in group {
                results.append(result)
            }
            
            return combineResults(results, originalWorkload: workload)
        }
    }
    
    // MARK: - Utility Functions
    
    private func createWorkloadPortion(from workload: Workload, portion: Double) -> Workload {
        let portionSize = Int(Double(workload.data.count) * portion)
        let portionData = workload.data.prefix(portionSize)
        
        return Workload(
            type: workload.type,
            complexity: workload.complexity,
            priority: workload.priority,
            data: Data(portionData)
        )
    }
    
    private func distributeWorkload(_ workload: Workload) -> (cpu: Workload?, gpu: Workload?, neuralEngine: Workload?) {
        guard let profile = hardwareProfile else {
            return (cpu: workload, gpu: nil, neuralEngine: nil)
        }
        
        var distribution: (cpu: Workload?, gpu: Workload?, neuralEngine: Workload?) = (nil, nil, nil)
        
        // Distribute based on hardware capabilities
        let totalCapacity = profile.cpuInfo.totalCores + 
                           (profile.gpuInfo?.coreCount ?? 0) + 
                           (profile.neuralEngineInfo?.isAvailable == true ? 16 : 0)
        
        let cpuRatio = Double(profile.cpuInfo.totalCores) / Double(totalCapacity)
        let gpuRatio = Double(profile.gpuInfo?.coreCount ?? 0) / Double(totalCapacity)
        let neRatio = (profile.neuralEngineInfo?.isAvailable == true ? 16.0 : 0.0) / Double(totalCapacity)
        
        if cpuRatio > 0 {
            distribution.cpu = createWorkloadPortion(from: workload, portion: cpuRatio)
        }
        
        if gpuRatio > 0 {
            distribution.gpu = createWorkloadPortion(from: workload, portion: gpuRatio)
        }
        
        if neRatio > 0 {
            distribution.neuralEngine = createWorkloadPortion(from: workload, portion: neRatio)
        }
        
        return distribution
    }
    
    private func combineResults(_ results: [WorkloadResult], originalWorkload: Workload) -> WorkloadResult {
        guard !results.isEmpty else {
            return WorkloadResult(
                output: "No results",
                confidence: 0.0,
                hardwareUtilization: HardwareUtilization(),
                executionTime: 0.0
            )
        }
        
        if results.count == 1 {
            return results[0]
        }
        
        // Combine outputs and calculate weighted confidence
        let combinedOutput = results.map { $0.output }.joined(separator: " ")
        let weightedConfidence = results.reduce(0.0) { $0 + ($1.confidence / Double(results.count)) }
        let totalExecutionTime = results.map { $0.executionTime }.max() ?? 0.0
        
        // Combine hardware utilization
        let combinedUtilization = HardwareUtilization(
            cpuUtilization: results.compactMap { $0.hardwareUtilization.cpuUtilization }.max() ?? 0.0,
            gpuUtilization: results.compactMap { $0.hardwareUtilization.gpuUtilization }.max() ?? 0.0,
            neuralEngineUtilization: results.compactMap { $0.hardwareUtilization.neuralEngineUtilization }.max() ?? 0.0,
            memoryUtilization: results.compactMap { $0.hardwareUtilization.memoryUtilization }.max() ?? 0.0
        )
        
        return WorkloadResult(
            output: combinedOutput,
            confidence: weightedConfidence,
            hardwareUtilization: combinedUtilization,
            executionTime: totalExecutionTime
        )
    }
    
    // MARK: - Performance Monitoring
    
    private func recordPerformanceMetrics(
        workload: Workload,
        strategy: ProcessingStrategy,
        executionTime: TimeInterval,
        result: WorkloadResult
    ) async {
        let snapshot = PerformanceSnapshot(
            timestamp: Date(),
            workloadType: workload.type,
            complexity: workload.complexity,
            strategy: strategy,
            executionTime: executionTime,
            confidence: result.confidence,
            hardwareUtilization: result.hardwareUtilization
        )
        
        performanceHistory.append(snapshot)
        
        // Keep history size manageable
        if performanceHistory.count > maxHistorySize {
            performanceHistory.removeFirst()
        }
        
        // Update current metrics
        await MainActor.run {
            optimizationMetrics = calculateCurrentMetrics()
        }
    }
    
    private func calculateCurrentMetrics() -> OptimizationMetrics {
        guard !performanceHistory.isEmpty else {
            return OptimizationMetrics()
        }
        
        let recentSnapshots = Array(performanceHistory.suffix(10))
        
        let avgCPU = recentSnapshots.compactMap { $0.hardwareUtilization.cpuUtilization }.reduce(0, +) / Double(recentSnapshots.count)
        let avgGPU = recentSnapshots.compactMap { $0.hardwareUtilization.gpuUtilization }.reduce(0, +) / Double(recentSnapshots.count)
        let avgNE = recentSnapshots.compactMap { $0.hardwareUtilization.neuralEngineUtilization }.reduce(0, +) / Double(recentSnapshots.count)
        let avgMemory = recentSnapshots.compactMap { $0.hardwareUtilization.memoryUtilization }.reduce(0, +) / Double(recentSnapshots.count)
        
        let avgExecutionTime = recentSnapshots.map { $0.executionTime }.reduce(0, +) / Double(recentSnapshots.count)
        let avgConfidence = recentSnapshots.map { $0.confidence }.reduce(0, +) / Double(recentSnapshots.count)
        
        return OptimizationMetrics(
            cpuUtilization: avgCPU,
            gpuUtilization: avgGPU,
            neuralEngineUtilization: avgNE,
            memoryUtilization: avgMemory,
            averageExecutionTime: avgExecutionTime,
            averageConfidence: avgConfidence,
            totalWorkloadsProcessed: performanceHistory.count
        )
    }
    
    /// Get current performance metrics
    public func getCurrentMetrics() -> OptimizationMetrics? {
        return optimizationMetrics
    }
    
    /// Adjust optimization strategy based on resource changes
    public func adjustForResourceChanges() async {
        logger.info("Adjusting Neural NGen AI optimization for resource changes")
        
        // Recalculate metrics and adjust strategies
        await MainActor.run {
            optimizationMetrics = calculateCurrentMetrics()
        }
        
        // Future enhancement: Dynamic strategy adjustment based on resource availability
    }
}

// MARK: - Supporting Types

public enum ProcessingStrategy: CustomStringConvertible {
    case cpuOnly
    case gpuOnly
    case neuralEngineOnly
    case cpuPlusGPU
    case neuralEnginePlusCPU
    case gpuPlusCPU
    case hybrid
    
    public var description: String {
        switch self {
        case .cpuOnly: return "CPU Only"
        case .gpuOnly: return "GPU Only"
        case .neuralEngineOnly: return "Neural Engine Only"
        case .cpuPlusGPU: return "CPU + GPU"
        case .neuralEnginePlusCPU: return "Neural Engine + CPU"
        case .gpuPlusCPU: return "GPU + CPU"
        case .hybrid: return "Hybrid (All Hardware)"
        }
    }
}

public struct WorkloadInfo {
    public let type: WorkloadType
    public let complexity: WorkloadComplexity
    public let priority: WorkloadPriority
    public let dataSize: Int
    
    public init(workload: Workload) {
        self.type = workload.type
        self.complexity = workload.complexity
        self.priority = workload.priority
        self.dataSize = workload.data.count
    }
}

public struct OptimizationMetrics {
    public let cpuUtilization: Double
    public let gpuUtilization: Double
    public let neuralEngineUtilization: Double
    public let memoryUtilization: Double
    public let averageExecutionTime: TimeInterval
    public let averageConfidence: Double
    public let totalWorkloadsProcessed: Int
    
    public init(
        cpuUtilization: Double = 0.0,
        gpuUtilization: Double = 0.0,
        neuralEngineUtilization: Double = 0.0,
        memoryUtilization: Double = 0.0,
        averageExecutionTime: TimeInterval = 0.0,
        averageConfidence: Double = 0.0,
        totalWorkloadsProcessed: Int = 0
    ) {
        self.cpuUtilization = cpuUtilization
        self.gpuUtilization = gpuUtilization
        self.neuralEngineUtilization = neuralEngineUtilization
        self.memoryUtilization = memoryUtilization
        self.averageExecutionTime = averageExecutionTime
        self.averageConfidence = averageConfidence
        self.totalWorkloadsProcessed = totalWorkloadsProcessed
    }
}

private struct PerformanceSnapshot {
    let timestamp: Date
    let workloadType: WorkloadType
    let complexity: WorkloadComplexity
    let strategy: ProcessingStrategy
    let executionTime: TimeInterval
    let confidence: Double
    let hardwareUtilization: HardwareUtilization
}
