//
//  UploadView.swift
//  AI Tennis Coach
//
//  Created by AndrewC on 1/20/22.
//

import SwiftUI
import Alamofire
import AVKit

struct UploadView: View {
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    @EnvironmentObject private var nc: NetworkController
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var awaiting = false
    @State private var uploading = false
    @State private var uploadingStatus = ""
    @State private var progressPercent = ""
    @State private var uploadName = ""
    @State private var uploadBucketName = ""
    var url: [URL]
    var uploadInCurrentBucket: Bool
    @State var bucketID: String
    
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("My Video", text: $uploadName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if (!uploadInCurrentBucket) {
                    Text("Choose a bucket")
                        .bucketTextInternalStyle()
                    Picker("None Selected", selection: $bucketID) {
                        ForEach(nc.userData.buckets) {
                            //Text(String($0.id))
                            Text($0.name).tag($0.id)
                        }
                    }
                }
                //.pickerStyle(.)
                
                Spacer()
                
                VideoPlayer(player: AVPlayer(url: url[0]))
                    .frame(height: 300)
                
                Spacer()
                
                Button(action: {
                    uploadInit(fileURL: url[0], uploadName: uploadName)
                }, label: {
                    Text("Upload")
                        .buttonStyle()
                    //.padding([.top, .leading, .trailing])
                })
                Text(uploadingStatus)
                    .bucketNameStyle()
                    .foregroundColor(Color.green)
                
                Text(progressPercent)
                    .videoInfoStyle()
                    .foregroundColor(Color.green)
                
            }.padding()
                .navigationTitle("Set Video Title")
                .navigationBarItems(leading: Button(action: {
                    self.mode.wrappedValue.dismiss()
                }, label: {
                    Text("Cancel")
                        .foregroundColor(Color.green)
                        .fontWeight(.bold)
                }))
            
        }
        
    }
    
    func uploadInit(fileURL: URL, uploadName: String) {
        Task {
            do {
                uploading = true
                uploadingStatus = "Uploading..."
                print(bucketID)
                try await upload(display_title: uploadName, bucket_id: Int(bucketID)!, uid: "\(nc.userData.shared.id)", fileURL: fileURL)
            } catch {
                print(error)
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    // POST
    func upload(display_title: String, bucket_id: Int, uid: String, fileURL: URL) async throws {
        
        let req: VideoReq = VideoReq(filename: fileURL.lastPathComponent, display_title: display_title, bucket_id: bucket_id)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            throw NetworkController.NetworkError.failedEncode
        }
        
        let url = URL(string: "\(nc.host)/uploads/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        do {
            let (data, _) = try await URLSession.shared.upload(for: request, from: encoded)
            print(data.prettyPrintedJSONString)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            let decodedResponse = try decoder.decode(VideoRes.self, from: data)
            try await uploadFields(url: decodedResponse.url, fields: decodedResponse.fields, fileURL: fileURL, completionHandler: {(result)->Void in
                switch result {
                case .success(_):
                    print("EDEN")
                    Task {
                        do {
                            try await convert(uid: "\(nc.userData.shared.id)", uploadID: "\(decodedResponse.id)")
                        }
                        catch {
                            throw NetworkController.NetworkError.failedUpload
                        }
                    }
                    
                case .failure(let error):
                    self.uploading = false
                    self.uploadingStatus = "Upload Failed.  Error: \(error)"
                }
                
            })
            
            
        } catch {
            
            throw NetworkController.NetworkError.failedDecode
        }
    }
    
    func uploadFields(url: String, fields: Field, fileURL: URL, completionHandler: @escaping (Result<Data, Error>) -> Void) async throws {
        let videoData = try! Data(contentsOf: fileURL)
        print(videoData)
        
        AF.upload(multipartFormData: { (multipartFormData) in
            multipartFormData.append(fields.key.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "key")
            multipartFormData.append(fields.x_amz_algorithm.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "x-amz-algorithm")
            multipartFormData.append(fields.x_amz_credential.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "x-amz-credential")
            multipartFormData.append(fields.x_amz_date.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "x-amz-date")
            multipartFormData.append(fields.policy.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "policy")
            multipartFormData.append(fields.x_amz_signature.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "x-amz-signature")
            multipartFormData.append(videoData, withName: "file", fileName: fileURL.lastPathComponent)
            
        }, to: url)
            .uploadProgress { progress in // main queue by default
                //                print("Upload Progress: \(progress.fractionCompleted)")
                //                print("Upload Estimated Time Remaining: \(String(describing: progress.estimatedTimeRemaining))")
                //                print("Upload Total Unit count: \(progress.totalUnitCount)")
                //                print("Upload Completed Unit Count: \(progress.completedUnitCount)")
                progressPercent = "\(Double(round(progress.fractionCompleted * 100 * 10) / 10.0))%"
                
            }
            .responseJSON(completionHandler: { response in
                if response.error == nil {
                    completionHandler(.success(response.data ?? "success".data(using: .utf8)!))
                } else {
                    completionHandler(.failure(response.error!))
                }
            })
        
        //throw NetworkError.failedUpload
    }
    
    // POST
    func convert(uid: String, uploadID: String) async throws {
        print ("Beginning conversion of upload \(uploadID) for user #\(uid)")
        
        let req: [String: Any] = ["a": "s"]
        
        guard let encoded = try? JSONSerialization.data(withJSONObject: req) else {
            throw NetworkController.NetworkError.failedEncode
        }
        
        let url = URL(string: "\(nc.host)/uploads/\(uploadID)/convert/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        do {
            let (_, response) = try await URLSession.shared.upload(for: request, from: encoded)
            print(response)
            
            self.uploading = false
            self.uploadingStatus = "Upload Complete!"
            self.mode.wrappedValue.dismiss()
            // initialize()
        } catch {
            
            throw NetworkController.NetworkError.failedDecode
        }
    }
}

