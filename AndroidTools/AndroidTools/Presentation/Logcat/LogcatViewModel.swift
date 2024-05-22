import Foundation

class LogcatViewModel : ObservableObject {
    private let getLogcatUseCase : GetLogcatUseCase = GetLogcatUseCase()
    private let getPackagesUseCase : GetPackagesUseCase = GetPackagesUseCase()
    
    @Published var logLevel: LogLevel? = nil
    @Published var loading: Bool = false
    
    @Published var logEntries: [LogEntryModel] = []

    @Published var packages : [String] = []
    
    private var buffer: String = ""
    private let bufferMaxSize = 1000

    func getLogcat(deviceId: String, packageName : String) {
        loading = true
        self.buffer = ""
        self.logEntries = []
        
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            getLogcatUseCase.execute(deviceId: deviceId, packageName: packageName) { result in
                self.buffer.append(result)
                self.processBuffer()
            }
        }
    }
    
    func getPackages(deviceId : String){
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let result = getPackagesUseCase.execute(deviceId: deviceId)
            DispatchQueue.main.async {
                switch(result){
                case .success(let packages) : self.packages = packages
                case .failure(let message): break
                    
                }
            }
        }
    }
    

    
    func clearLogcat(){
        logEntries = []
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
}
