import Foundation

import Foundation

class LogcatViewModel : ObservableObject {
    private let adbHelper = AdbHelper()
    
    @Published var package: String = ""
    @Published var logLevel: LogLevel? = nil
    
    @Published var logEntries: [LogEntryModel] = []
    
    private var buffer: String = ""
    private var pidToPackageMap: [Int: String] = [:]

    func getLogcat(deviceId: String) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let command = "-s \(deviceId) logcat -v threadtime"
            
            adbHelper.runAdbCommand(command) { result in
                DispatchQueue.main.async { [self] in
                    buffer.append(result)
                    processBuffer()
                }
            }
        }
    }
    
    private func processBuffer() {
        let lines = buffer.components(separatedBy: "\n")
        for i in 0..<lines.count-1 {
            if let logEntry = parseLogEntry(entry: lines[i]) {
                logEntries.append(logEntry)
                if logEntries.count > 500 {
                    logEntries.removeFirst(logEntries.count - 200)
                }
            }
        }
        buffer = lines.last ?? ""
    }
    
    private func parseLogEntry(entry: String) -> LogEntryModel? {
        let components = entry.split(separator: " ", maxSplits: 6, omittingEmptySubsequences: true)
        if components.count < 7 {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd HH:mm:ss.SSS"
        guard let date = dateFormatter.date(from: "\(components[0]) \(components[1])") else {
            return nil
        }
        
        guard let processId = Int(components[2]), let threadId = Int(components[3]) else {
            return nil
        }
        
        guard let level = LogLevel(rawValue: String(components[4])) else {
            return nil
        }
        
        let tagAndMessage = components[6].split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
        if tagAndMessage.count < 2 {
            return nil
        }
        
        let tag = String(tagAndMessage[0])
        let message = String(tagAndMessage[1]).trimmingCharacters(in: .whitespacesAndNewlines)
        let packageName = retrievePackageName(for: processId)
        
        return LogEntryModel(
            datetime: date,
            processID: processId,
            threadID: threadId,
            level: level,
            packageName: packageName,
            tag: tag,
            message: message
        )
    }

    private func retrievePackageName(for pid: Int) -> String {
        if let packageName = pidToPackageMap[pid] {
            return packageName
        } else {
            let packageName = String(adbHelper.runAdbCommand("shell ps -A | grep \(pid)").split(separator: " ").last ?? "Unknown")
            
            pidToPackageMap[pid] = packageName
            return packageName
        }
    }
}
