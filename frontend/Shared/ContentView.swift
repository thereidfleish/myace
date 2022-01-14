//
//  ContentView.swift
//  Shared
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    @StateObject var studentInfo = StudentInfo()
    @StateObject var coachInfo = CoachInfo()
    @EnvironmentObject private var networkController: NetworkController
    @StateObject var camera = CameraCapture()
    var body: some View {
        TabView(selection: $selection) {
            if (networkController.userData.shared.type == 0) {
                StudentUploadView()
                    .environmentObject(studentInfo)
                    .environmentObject(coachInfo)
                    .tabItem {
                        VStack {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .foregroundColor(.green)
                            Text("Student View")
                                .foregroundColor(.green)
                        }
                    }
                    .tag(0)
            }
            else {
                CoachMainView()
                    .environmentObject(coachInfo)
                    .environmentObject(studentInfo)
                    .tabItem {
                        VStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.green)
                            Text("Coach View")
                                .foregroundColor(.green)
                        }
                    }
                    .tag(0)
            }
            
            ProfileView()
                .tabItem {
                    VStack {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(.green)
                        Text("My Profile")
                            .foregroundColor(.green)
                    }
                }
                .tag(1)
            
            //CameraView()
            ZStack {
                //CameraCaptureRepresentable()
                CamPreviewView(camera: camera)
                    .ignoresSafeArea()
                VStack {
                    Spacer()
                    Button(action: camera.startCapture, label: {
                        ZStack {
                            
                            if camera.movieOutput.isRecording == false {
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
                .tabItem {
                    VStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.green)
                        Text("Camera")
                            .foregroundColor(.green)
                    }
                }
                .tag(2)
            
            
        }.accentColor(Color.green)
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
