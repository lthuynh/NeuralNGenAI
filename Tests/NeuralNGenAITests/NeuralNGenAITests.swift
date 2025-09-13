import XCTest
@testable import NeuralNGenAI

final class NeuralNGenAITests: XCTestCase {
    
    func testHardwareProfiling() async throws {
        let profiler = HardwareProfiler()
        await profiler.profileSystem()
        
        XCTAssertNotNil(profiler.profile)
        XCTAssertGreaterThan(profiler.profile!.cpuInfo.totalCores, 0)
        XCTAssertGreaterThan(profiler.profile!.memoryInfo.totalMemory, 0)
    }
    
    func testWorkloadProcessing() async throws {
        let workload = Workload(
            type: .naturalLanguageProcessing,
            complexity: .medium,
            priority: .high,
            data: "Test query".data(using: .utf8)!
        )
        
        let optimizer = PerformanceOptimizer.shared
        let result = await optimizer.processWorkload(workload)
        
        XCTAssertFalse(result.output.isEmpty)
        XCTAssertGreaterThan(result.confidence, 0.0)
        XCTAssertGreaterThan(result.executionTime, 0.0)
    }
    
    func testNeuralNGenAIApp() async throws {
        let app = NeuralNGenAIApp()
        await app.initialize()
        
        let response = await app.processQuery("Hello, Neural NGen AI!")
        
        XCTAssertFalse(response.response.isEmpty)
        XCTAssertGreaterThan(response.confidence, 0.0)
        XCTAssertGreaterThan(response.processingTime, 0.0)
    }
    
    func testPerformanceSummary() async throws {
        let app = NeuralNGenAIApp()
        await app.initialize()
        
        let summary = app.getPerformanceSummary()
        
        XCTAssertFalse(summary.overallRating.isEmpty)
        XCTAssertGreaterThanOrEqual(summary.cpuUtilization, 0.0)
        XCTAssertGreaterThanOrEqual(summary.memoryPressure, 0.0)
        XCTAssertFalse(summary.recommendations.isEmpty)
    }
    
    func testStreamingResponse() async throws {
        let app = NeuralNGenAIApp()
        await app.initialize()
        
        var responseCount = 0
        for await response in app.processStreamingQuery("Test streaming query") {
            responseCount += 1
            XCTAssertFalse(response.partialResponse.isEmpty)
            XCTAssertGreaterThanOrEqual(response.progress, 0.0)
            XCTAssertLessThanOrEqual(response.progress, 1.0)
        }
        
        XCTAssertGreaterThan(responseCount, 0)
    }
    
    func testWorkloadManager() {
        let manager = WorkloadManager()
        
        let workload1 = Workload(type: .naturalLanguageProcessing, complexity: .low, priority: .high, data: Data())
        let workload2 = Workload(type: .imageProcessing, complexity: .medium, priority: .normal, data: Data())
        
        manager.enqueue(workload1)
        manager.enqueue(workload2)
        
        let stats = manager.getQueueStatistics()
        XCTAssertEqual(stats.totalCount, 2)
        
        let dequeued = manager.dequeue()
        XCTAssertNotNil(dequeued)
        XCTAssertEqual(dequeued?.priority, .high) // Higher priority should come first
    }
    
    func testHardwareOptimizers() async throws {
        let cpuOptimizer = CPUOptimizer()
        let gpuOptimizer = GPUOptimizer()
        let neOptimizer = NeuralEngineOptimizer()
        let memoryOptimizer = MemoryOptimizer()
        
        let workload = Workload(
            type: .machineLearning,
            complexity: .high,
            priority: .critical,
            data: "Test data".data(using: .utf8)!
        )
        
        let cpuResult = await cpuOptimizer.processWorkload(workload)
        XCTAssertFalse(cpuResult.output.isEmpty)
        
        let gpuResult = await gpuOptimizer.processWorkload(workload)
        XCTAssertFalse(gpuResult.output.isEmpty)
        
        let neResult = await neOptimizer.processWorkload(workload)
        XCTAssertFalse(neResult.output.isEmpty)
    }
}
