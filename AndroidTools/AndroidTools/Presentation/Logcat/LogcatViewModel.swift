import Foundation

import Foundation

class LogcatViewModel : ObservableObject {
    private let adbHelper = AdbHelper()
    
    @Published var package: String = ""
    @Published var logLevel: LogLevel? = nil
    @Published var loading: Bool = false
    
    @Published var logEntries: [LogEntryModel] = []
    @Published var filterPackage : String? = nil
    
    private var buffer: String = ""
    @Published var pidToPackageMap: [Int: String] = [:]

    func getLogcat(deviceId: String) {
        loading = true
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let command = "-s \(deviceId) logcat -v threadtime"
            
            adbHelper.runAdbCommand(command) { [self] result in
                buffer.append(result)
                processBuffer()
            }
        }
    }
    
    private func processBuffer() {
        DispatchQueue.main.async {
            self.loading = true
        }
        let lines = buffer.components(separatedBy: "\n")
        for i in 0..<lines.count-1 {
            if let logEntry = lines[i].toLogcatEntry() {
                DispatchQueue.main.async { [self] in
                    logEntries.append(logEntry)
                }
                
                if logEntries.count > 500 {
                    DispatchQueue.main.async { [self] in
                        logEntries.removeFirst(logEntries.count - 200)
                    }
                }
            }
        }
        buffer = lines.last ?? ""
        DispatchQueue.main.async {
            self.loading = false
        }
    }
    
}
