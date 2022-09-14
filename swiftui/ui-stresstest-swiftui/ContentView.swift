//
//  ContentView.swift
//  ui-stresstest-swiftui
//
//  Created by Robert Feldbinder on 09.09.2022.
//

import SwiftUI

struct ContentView: View {
    let numPerRowColumn = 10 // higher numbers will generate more load
    let colors: [Color] = [.red, .orange, .yellow, .green, .cyan, .purple, .blue]
 
    @State private var offsetX: CGFloat = 0
    @State private var offsetY: CGFloat = 0
    
    var body: some View
    {
        ZStack(alignment: .topLeading)
        {
            HStack(spacing: 0)
            {
                ForEach((0...numPerRowColumn), id: \.self)
                {
                    indexH in
                    VStack(spacing: 0)
                    {
                        ForEach((0...numPerRowColumn), id: \.self)
                        {
                            indexV in
                            Rectangle()
                                .fill(colors[(indexH + indexV) % (colors.count) ])
                        }
                    }
                }
            }
            
            
            Rectangle().fill(.gray).frame(width: 100, height:100).offset(x: offsetX, y: offsetY)
                .animation(.linear(duration: 1).repeatForever(), value: offsetX)
                .onAppear
            {
                offsetX = 1200
                offsetY = 600
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
