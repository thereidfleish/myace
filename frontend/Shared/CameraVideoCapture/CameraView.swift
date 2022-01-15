//
//  CameraView.swift
//  AI Tennis Coach (iOS)
//
//  Created by AndrewC on 1/14/22.
//

import SwiftUI

struct CameraView: View {
    @StateObject var camera = CameraCapture()
    @State var isRecording = false
    var body: some View {
        ZStack {
            CamPreviewView(camera: camera)
                .ignoresSafeArea()
            VStack {
                Spacer()
                Button(action: {
                    camera.startCapture()
                    isRecording.toggle()
                }, label: {
                    ZStack {
                        if isRecording == false {
                            Circle()
                            .fill(Color.red)
                            .frame(width: 65, height: 65)
                        }
                        else {
                            Rectangle()
                            .fill(Color.red)
                            .frame(width: 20, height: 20)
                        }
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 75, height: 75)
                    }
                })
            }
        }
        
    }
}
