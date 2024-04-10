//
//  InformationView.swift
//  AndroidTools
//
//  Created by Thomas Bernard on 09/04/2024.
//

import SwiftUI

struct InformationView: View {
    var body: some View {
        
        HStack{
            Image("Phone")

                .resizable()
                .scaledToFit()
                .frame(height: 50)
            
            VStack {
                HStack {
                    Text("AK12 HD")
                    Spacer()
                }
                
                HStack {
                    Text("Xiaomi REDMIN K20 PRO")
                    
                    Spacer()
                }
            }
                
                
        }
        .padding()
        
        List {
            Section(header: Text("General informations")) {
                HStack{
                    Image(systemName: "smartphone" )
                    Text("Android version")
                    
                    Spacer()
                    
                    Text("11.0")
                }
                
                HStack{
                    Image(systemName: "smartphone" )
                    Text("Constructeur")
                    
                    Spacer()
                    
                    Text("Xiaomi")
                }
                
                HStack{
                    Image(systemName: "smartphone" )
                    Text("Modèle")
                    
                    Spacer()
                    
                    Text("Redmi K20PRO")
                }
            }
        }
    }
}

#Preview {
    InformationView()
}
