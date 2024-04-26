import SwiftUI

struct SettingsView: View {
    
    private enum Tabs: Hashable {
        case general, advanced
    }
    
    let appIcons: [String] = ["AppIconDark", "AppIconLight", "AppIconAndroid"]
    let modes : [String] = ["Automatic", "Dark", "Light"]
    
    @AppStorage("mode") private var mode = "Automatic"
    @AppStorage("appIconName") private var appIconName = "AppIconDark"
    
    
    // State to track the currently selected icon
    @State private var selectedIcon: String = (NSApplication.shared.applicationIconImage.name() ?? "")
    
    var body: some View {
        Form {
            Group {

                Section("Apparance") {
                    VStack {
                        Picker("", selection: $mode) {
                            ForEach(modes, id: \.self) { mode in
                                Text(mode)
                                if mode == modes.first {
                                    Divider()
                                }
                                
                            }
                        }
                        
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
                        
                        Spacer()
                    }
                }
            }
        }


    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
