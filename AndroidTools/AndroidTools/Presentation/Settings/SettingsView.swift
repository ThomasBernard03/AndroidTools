import SwiftUI

struct SettingsView: View {

    private enum Tabs: Hashable {
        case application, appearance
    }
    
    var body: some View {
        TabView {
            ApplicationSettingsView()
                .tabItem {
                    Label("Application", systemImage: "gear")
                }
                .tag(Tabs.application)
            
            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "sun.max")
                }
                .tag(Tabs.appearance)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
