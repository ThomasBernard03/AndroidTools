import Foundation
import Combine

class LogcatViewModel: ObservableObject {
    private let getLogcatUseCase: GetLogcatUseCase = GetLogcatUseCase()
    private let getPackagesUseCase: GetPackagesUseCase = GetPackagesUseCase()
    private let clearLogcatUseCase: ClearLogcatUseCase = ClearLogcatUseCase()
    
    @Published var loading: Bool = false
    @Published var logEntries: [LogEntryModel] = []
    @Published var packages: [String] = []
    @Published var paused : Bool = false
    
    private let maxLogEntries = 1000
    private var cancellable: AnyCancellable?

    func getLogcat(deviceId: String, packageName: String) {
        self.logEntries = []
        cancellable?.cancel()
        cancellable = getLogcatUseCase.execute(deviceId: deviceId, packageName: packageName)
            .receive(on: DispatchQueue.main)
            .sink(){ result in
                if self.logEntries.count > self.maxLogEntries {
                    self.logEntries.removeFirst(self.logEntries.count - 200)
                }
                
                self.logEntries += result
        }
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
    
    func pauseResumeLogcat(deviceId: String, packageName: String){
        paused.toggle()
        if paused {
            cancellable?.cancel()
        }
        else {
            getLogcat(deviceId: deviceId, packageName: packageName)
        }
    }
}
