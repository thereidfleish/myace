//
//  MainCameraView.swift
//  AI Tennis Coach (iOS)
//
//  Created by AndrewC on 1/2/22.
//

import SwiftUI

struct CameraView: View {
  @StateObject private var model = ContentViewModel()
    @Environment(\.dismiss) var done

  var body: some View {
    ZStack {
      FrameView(image: model.frame)
        .edgesIgnoringSafeArea(.all)

      ErrorView(error: model.error)

        VStack {
            HStack {
                // Change Camera Position
                Button(action: {
                    //CameraManager.shared.changeCameraPosition()
                }, label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .foregroundColor(Color.green)
                })
                    .padding([.horizontal, .top, .bottom])
                Spacer()
                Spacer()
                // Exit out of Camera View
                Button(action: {
                    done()
                }, label: {
                    Text("Done")
                    .foregroundColor(.green)
                })
                    .padding([.horizontal, .top, .bottom])

            }
            Spacer()
            Spacer()



        }
    }
  }
}
