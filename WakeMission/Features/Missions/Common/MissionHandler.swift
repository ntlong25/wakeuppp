import Foundation
import SwiftUI

@MainActor
protocol MissionHandler: ObservableObject {
    var title: String { get }
    var instruction: String { get }
    var isCompleted: Bool { get }
    var progress: Double { get }
    
    func start() async
    func validate() async -> Bool
    func complete()
    func reset()
}
