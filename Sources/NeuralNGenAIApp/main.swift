import Foundation
import NeuralNGenAI

@main
struct NeuralNGenAIMain {
    static func main() async {
        print("🧠 Neural NGen AI - Next Generation Neural Assistant")
        print("=" * 50)
        
        let app = NeuralNGenAIApp()
        
        // Initialize the system
        print("🚀 Initializing Neural NGen AI...")
        await app.initialize()
        
        print("✅ Neural NGen AI is ready!")
        print("\nProcessing sample query...")
        
        // Process a sample query
        let response = await app.processQuery("What are the capabilities of Neural NGen AI?")
        
        print("\n📝 Response:")
        print("   Content: \(response.response)")
        print("   Confidence: \(String(format: "%.1f", response.confidence * 100))%")
        print("   Processing Time: \(String(format: "%.3f", response.processingTime))s")
        
        // Show performance summary
        let summary = app.getPerformanceSummary()
        print("\n📊 Performance Summary:")
        print("   Overall Rating: \(summary.overallRating)")
        print("   CPU Utilization: \(String(format: "%.1f", summary.cpuUtilization * 100))%")
        print("   GPU Utilization: \(String(format: "%.1f", summary.gpuUtilization * 100))%")
        print("   Neural Engine: \(String(format: "%.1f", summary.neuralEngineUtilization * 100))%")
        print("   Memory Pressure: \(String(format: "%.1f", summary.memoryPressure * 100))%")
        
        print("\n💡 Recommendations:")
        for recommendation in summary.recommendations {
            print("   • \(recommendation)")
        }
        
        print("\n🌟 Neural NGen AI demonstration complete!")
        print("Ready for advanced AI processing and optimization.")
    }
}

extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}
