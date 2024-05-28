import Foundation
import os

class DatabaseExplorerViewModel : ObservableObject {
    private let getPackagesUseCase : GetPackagesUseCase = GetPackagesUseCase()
    private let adbRepository : AdbRepository = AdbRepositoryImpl()
    
    @Published var toast : Toast? = nil
    @Published var loading : Bool = false
    
    @Published var packages : [String] = []
    @Published var selectedPackage : String? = nil
    @Published var selectedDatabaseFile : String? = nil
    
    @Published var tables : [String] = []
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: DatabaseExplorerViewModel.self)
    )
    
    func getPackages(deviceId : String){
        self.loading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.getPackagesUseCase.execute(deviceId: deviceId)
            DispatchQueue.main.async {
                self.loading = false
                switch(result){
                case .success(let packagesResult): self.packages = packagesResult
                case .failure(let error): self.manageGetPackagesError(error: error)
                }
            }
        }
    }
    
    
    func getPackageDatabaseTables(deviceId: String, packageName: String) {
        let databasesFiles = try? adbRepository.runAdbCommand("shell 'run-as \(packageName) sh -c \"cd databases; ls\"'")
        
        let files = databasesFiles?.split(separator: "\n").map { String($0) }
        
        if let databaseFile = files?.first {
            logger.debug("Database file found : \(databaseFile)")
            selectedDatabaseFile = databaseFile
            
            let databaseTablesResult = try? adbRepository.runAdbCommand("shell 'run-as \(packageName) sh -c \"cd databases; sqlite3 \(databaseFile) .tables\"'")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .split(separator: "\n")
                .flatMap { $0.split(separator: " ") }
                .map { String($0) }
            
            if let databaseTables = databaseTablesResult {
                tables = databaseTables
            }
        }
    }
    
    func goBack(){
        selectedPackage = nil
        selectedDatabaseFile = nil
    }
    
    private func manageGetPackagesError(error : GetAllPackagesError){
        switch(error){
        case .unknownError(let message) : toast = Toast(style: .error, message: message)
        }
    }
}
