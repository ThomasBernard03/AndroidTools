import SwiftUI
import UniformTypeIdentifiers.UTType

struct InstallerView: View {
    
    let deviceId: String
    
    @State private var dropTargetted: Bool = false
    @State private var isHoveringPhone: Bool = false
    @State private var viewModel = InstallerViewModel()
    

    
    private func loadApkFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.apk]
        panel.begin { (response) in
            if response == .OK, let url = panel.url {
                DispatchQueue.global(qos: .userInitiated).async {
                    viewModel.installApk(deviceId: deviceId, path: url.path)
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Animated background waves
            CircleWavesAnimation()

            // Image to represent APK dropping
            Image("ApkFile")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
            
            VStack {
                HStack {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Drag and drop your .apk file to install your application\nYou can also click on the add button to import file from Finder")
                    }
                    .padding()
                    .background(Material.ultraThin)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .padding(16)

                    Spacer()
                }

                Spacer()
            }
                
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)  // Make drop zone full screen
        .onDrop(of: [.apk], isTargeted: $dropTargetted) { providers in
            providers.first?.loadItem(forTypeIdentifier: UTType.apk.identifier, options: nil) { (item, error) in
                if let item = item as? URL {
                    let fileUrl = item.startAccessingSecurityScopedResource() ? item : URL(fileURLWithPath: item.path)
                    viewModel.installApk(deviceId: deviceId, path: fileUrl.path)
                    item.stopAccessingSecurityScopedResource()
                }
            }
            return true
        }
        .overlay {
            if dropTargetted {
                ZStack {
                    Color.black.opacity(0.5)
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                        Text("Drop your apk here...")
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                }
            }
        }
        .animation(.default, value: dropTargetted)
        .navigationTitle("Application Installer")
        .toolbar {
            Button(action: {loadApkFile()}, label: {
                Label("Load file from finder", systemImage: "doc.badge.plus")
            })
        }
        .toastView(toast: $viewModel.toast)
    }
}

struct InstallerView_Previews: PreviewProvider {
    static var previews: some View {
        InstallerView(deviceId: "4dfda049")
    }
}
