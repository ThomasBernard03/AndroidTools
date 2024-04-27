import SwiftUI
import UniformTypeIdentifiers.UTType

struct InstallerView: View {
    
    let deviceId: String
    
    @State private var dropTargetted: Bool = false
    @State private var isHoveringPhone: Bool = false
    @State private var viewModel = InstallerViewModel()
    
    @State private var scale: [Double] = [1, 1, 1, 1, 1, 1]
    @State private var opacity: [Double] = [1, 1, 1, 1, 1, 1]
    
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
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.accentColor)
                    .scaleEffect(scale[index])
                    .opacity(opacity[index])
                    .animation(
                        Animation.easeOut(duration: 5).repeatForever(autoreverses: false).delay(Double(index)),
                        value: scale[index]
                    )
                    .onAppear {
                        scale[index] = 5
                        opacity[index] = 0
                    }
            }

            // Image to represent APK dropping
            Image("ApkFile")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
            
            VStack(alignment:.leading) {
                HStack {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Drag and drop your .apk file to install your application\nYou can also click on the add button to import file from Finder")
        
                    }
                    .padding()
                    .background(.background.opacity(0.9))
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
