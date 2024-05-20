import Foundation

class LogcatViewModel : ObservableObject {
    private let getLogcatUseCase : GetLogcatUseCase = GetLogcatUseCase()
    
    @Published var package: String = ""
    @Published var logLevel: LogLevel? = nil
    @Published var loading: Bool = false
    
    @Published var logEntries: [LogEntryModel] = []
    @Published var filterPackage : String? = nil
    
    @Published var stickyList : Bool = false
    
    private var buffer: String = ""
    private let bufferMaxSize = 1000

    func getLogcat(deviceId: String) {
        loading = true
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            getLogcatUseCase.execute(deviceId: deviceId) { result in
                self.buffer.append(result)
                self.processBuffer()
            }
        }
    }
    
    private func processBuffer() {
        DispatchQueue.main.async { self.loading = true }
        let lines = buffer.components(separatedBy: "\n")
        for i in 0..<lines.count-1 {
            if let logEntry = lines[i].toLogcatEntry() {
                DispatchQueue.main.async { [self] in
                    logEntries.append(logEntry)
                }
                
                if logEntries.count > bufferMaxSize {
                    DispatchQueue.main.async { [self] in
                        self.logEntries.removeFirst(self.logEntries.count - self.bufferMaxSize)
                    }
                }
            }
        }
        buffer = lines.last ?? ""
        DispatchQueue.main.async { self.loading = false }
    }
    
    func clearLogcat(){
        logEntries = []
    }
    
}
