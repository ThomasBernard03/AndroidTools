//
//  EmulatorsView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 11/08/2024.
//

import SwiftUI

struct EmulatorsView: View {
    
    private let emulatorRepository : EmulatorRepository = EmulatorRepositoryImpl()
    
    @State private var emulators : [EmulatorListModel] = []
    
    var body: some View {
        List(emulators) { emulator in
            NavigationLink(destination: EmulatorView(emulatorName: emulator.name)) {
                Text(emulator.name)
            }
            
        }
        .onAppear {
            emulators = emulatorRepository.getEmulators()
        }
    }
}

#Preview {
    EmulatorsView()
}
