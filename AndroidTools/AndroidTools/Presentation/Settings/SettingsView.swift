import SwiftUI

struct SettingsView: View {
    
    private enum Tabs: Hashable {
        case general, advanced
    }
    
    @StateObject private var viewModel = SettingsViewModel()
    
    private let appIcons: [String] = ["AppIconDark", "AppIconLight", "AppIconAndroid"]
    private let modes : [String] = ["Automatic", "Dark", "Light"]
    
    @AppStorage("mode") private var mode = "Automatic"
    @AppStorage("appIconName") private var appIconName = "AppIconDark"
    
    @AppStorage("adbPath") private var adbPath = "/usr/local/bin/adb"
    
    
    // State to track the currently selected icon
    @State private var selectedIcon: String = (NSApplication.shared.applicationIconImage.name() ?? "")
    
    
    private func openFinderToSelectADB() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: adbPath)
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                self.adbPath = url.path
                viewModel.getAdbVersion()
            }
        }
    }
    
    var body: some View {
        Form {
            Group {
                Section(header: Text("Apparence")) {
                    VStack {
                        Picker("", selection: $mode) {
                            ForEach(modes, id: \.self) { mode in
                                Text(mode)
                                if mode == modes.first {
                                    Divider()
                                }
                                
                            }
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(appIcons, id: \.self) { name in
                                    VStack {
                                        Image(nsImage: NSImage(named: name)!)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 60, height: 60) // Highlight the selected icon
                                    }
                                
                                    .background(appIconName == name ? Color.accentColor : Color.clear)
                                    .cornerRadius(13.4)

                                    .onTapGesture {
                                        NSApplication.shared.applicationIconImage = NSImage(named: name)
                                        appIconName = name  // Update the selected icon
                                    }
                                }
                            }
                            .padding()
                        }
                        
                        
                    }
                }
                
                Section("Application"){
                    Button {
                        viewModel.checkForUpdates()
                    } label: {
                        Text("Check for updates")
                        
                    }.buttonStyle(LargeButtonStyle())
                    
                    
                    TextField("", text: $adbPath)
                        .disabled(true)
                    

                    
                    HStack {
                        Button("Change location"){
                            openFinderToSelectADB()
                        }
                        
                        Button("Check installation") {
                            viewModel.getAdbVersion()
                        }
                    }
                    
                    Text(viewModel.adbVersion)
                    
  

                    
                    
                }
            }
            
            Spacer()
        }
        .onAppear {
            viewModel.getAdbVersion()
        }
        



    }

}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
