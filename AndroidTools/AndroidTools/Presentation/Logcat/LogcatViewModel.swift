import Foundation

class LogcatViewModel: ObservableObject {
    private let getLogcatUseCase: GetLogcatUseCase = GetLogcatUseCase()
    private let getPackagesUseCase: GetPackagesUseCase = GetPackagesUseCase()
    private let clearLogcatUseCase: ClearLogcatUseCase = ClearLogcatUseCase()
    
    @Published var loading: Bool = false
    @Published var logEntries: [LogEntryModel] = []
    @Published var packages: [String] = []
    
    private let maxLogEntries = 1000
    private var currentLogcatWorkItem: DispatchWorkItem?

    func getLogcat(deviceId: String, packageName: String) {
        currentLogcatWorkItem?.cancel()
        
        // Créer une nouvelle DispatchWorkItem
        currentLogcatWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.getLogcatUseCase.execute(deviceId: deviceId, packageName: packageName) { result in
                DispatchQueue.main.async {
                    if self.logEntries.count > self.maxLogEntries {
                        self.logEntries = Array(self.logEntries.suffix(self.maxLogEntries))
                    }
                    
                    self.loading = false
                    self.logEntries += result
                }
            }
        }
        

        loading = true
        logEntries = []
        
        // Lancer la nouvelle tâche
        DispatchQueue.global(qos: .userInitiated).async(execute: currentLogcatWorkItem!)
    }
    
    func getPackages(deviceId: String) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let result = getPackagesUseCase.execute(deviceId: deviceId)
            DispatchQueue.main.async {
                switch(result) {
                case .success(let packages):
                    self.packages = packages
                case .failure(let message):
                    break
                }
            }
        }
    }
    
    func clearLogcat(deviceId: String) {
        self.loading = true
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            clearLogcatUseCase.execute(deviceId: deviceId)
            DispatchQueue.main.async {
                self.logEntries = []
                self.loading = false
            }
        }
    }
}
