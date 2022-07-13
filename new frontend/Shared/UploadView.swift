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
    @State private var awaiting = true
    @State private var uploading = false
    @State private var uploadingStatus = ""
    @State private var progressPercent = ""
    @State private var progressPercentFraction = 0.0
    @State private var uploadName = ""
    @State private var uploadBucketName = ""
    @State private var isShowingNewStrokeView = false
    @State var url: [URL]
    @State var bucketID: String?
    @State private var dontAllowClose = true
    var otherUser: SharedData?
    @State private var visibility: Visibility = Visibility()
    let visOptions: [VisibilityOptions: String] = [.`private`: "Private",
                                                                  .coaches_only: "Coaches Only",
                                                                  .friends_only: "Friends Only",
                                                                  .friends_and_coaches: "Friends and Coaches Only",
                                                                  .`public`: "Public"]
    var editMode: Bool = false
    //var editUploadID: String
    //@State private var alsoSharedWith: [SharedData] = []
    @State private var searchText = ""
    
    @State private var uploadInfo: Upload = Upload()
    
    func computeBucketName() -> String {
        for bucket in nc.userData.buckets {
            if bucketID != nil {
                if (bucket.id == Int(bucketID!)) {
                    return bucket.name
                }
            }
        }
        return "Choose a tag"
    }
    
    func initialize() {
        Task {
            do {
                uploadInfo = try await nc.getUpload(uploadID: nc.editUploadID)
                uploadName = uploadInfo.display_title
                bucketID = String(uploadInfo.bucket.id)
                visibility = uploadInfo.visibility
                uploadBucketName = uploadInfo.bucket.name
                url = [URL(string: uploadInfo.url!)!]
                awaiting = false
            } catch {
                print("Showing error: \(error)")
                errorMessage = error.localizedDescription
                showingError = true
                awaiting = false
            }
        }
    }
    
    func editUpload() {
        Task {
            do {
                try await nc.editUpload(uploadID: nc.editUploadID, displayTitle: uploadName == uploadInfo.display_title ? nil : uploadName, bucketID: bucketID! == String(uploadInfo.bucket.id) ? nil : Int(bucketID!), visibility: uploadInfo.visibility == visibility ? nil : visibility)
                self.mode.wrappedValue.dismiss()
            } catch {
                print("Showing error: \(error)")
                errorMessage = error.localizedDescription
                showingError = true
                awaiting = false
            }
        }
    }
    
    func uploadInit(fileURL: URL, uploadName: String) {
        Task {
            do {
                //visibility.also_shared_with = alsoSharedWith
                uploading = true
                uploadingStatus = "Uploading..."
                print(bucketID)
                try await upload(display_title: uploadName == "" ? "My Video" : uploadName, bucket_id: Int(bucketID!)!, visibility: visibility, uid: "\(nc.userData.shared.id)", fileURL: fileURL)
            } catch {
                print("Showing error: \(error)")
                errorMessage = error.localizedDescription
                showingError = true
                awaiting = false
            }
        }
    }
    
    
    var body: some View {
        ZStack {
            NavigationView {
                ScrollView {
                    if(awaiting && editMode) { // Don't need to initialize if not in edit mode
                        ProgressView()
                    }
                    else {
                        VStack(alignment: .leading) {
                            
                            Text("Set Video Title")
                                .bucketTextInternalStyle()
                                .onAppear {
                                    if otherUser != nil  && otherUser?.id != nc.userData.shared.id && !editMode {
                                        visibility.also_shared_with.append(otherUser!)
                                    }
                                }
                            
                            TextField("My Video", text: $uploadName)
                                .textFieldStyle()
                                .disabled(uploading)

                                Text("Tag")
                                .bucketTextInternalStyle()
                                .padding(.top)
                            
                            HStack {
                                Text(computeBucketName())
                                
                                Menu {
                                    Button(action: {
                                        isShowingNewStrokeView.toggle()
                                    }, label: {
                                        Label("New Tag", systemImage: "plus.circle.fill")
                                    })
                                    
                                    ForEach(nc.userData.buckets) { bucket in
                                        Button(bucketID == "\(bucket.id)" ? "\(bucket.name)  🎾" : bucket.name) {
                                            bucketID = "\(bucket.id)"
                                        }
                                    }
                                } label: {
                                    Image(systemName: "pencil.circle.fill")
                                        .resizable()
                                        .circularButtonStyle()
                                    
                                }.disabled(uploading)
                            }
                            
                            Group {
                                Text("Visibility")
                                    .padding(.top)
                                    .bucketTextInternalStyle()
                                
                                HStack {
                                    Text(visOptions[visibility.default]!)
                                    
                                    Menu {
                                        ForEach(Array(visOptions.keys), id: \.self) { visOp in
                                            Button(visOptions[visOp]!) {
                                                visibility.default = visOp
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "pencil.circle.fill")
                                            .resizable()
                                            .circularButtonStyle()
                                    }.disabled(uploading)
                                }
                                
                                Text("Also shared with:")
                                    .padding(.top, 5.0)
                                    .smallestSubsectionStyle()
                                
                                ForEach(visibility.also_shared_with.indices, id: \.self) { index in
                                    HStack {
                                        Text("\(visibility.also_shared_with[index].display_name) (\(visibility.also_shared_with[index].username))")
                                        
                                        Button(action: {
                                            visibility.also_shared_with.remove(at: index)
                                        }, label: {
                                            Image(systemName: "trash.circle.fill")
                                                .resizable()
                                                .circularButtonStyle()
                                                .foregroundColor(.red)
                                        }).disabled(uploading)
                                    }
                                    
                                }
                                
                                TextField("Search for courtships...", text: $searchText)
                                    .textFieldStyle()
                                    .disabled(uploading)
                                
                                ForEach(nc.userData.courtships.filter { ($0.display_name.lowercased().contains(searchText.lowercased()) || $0.username.lowercased().contains(searchText.lowercased())) && (!visibility.also_shared_with.contains($0)) }, id: \.self.id) { courtship in
                                    
                                    Button(action: {
                                        withAnimation {
                                            visibility.also_shared_with.append(courtship)
                                        }
                                        
                                    }, label: {
                                        Text("\(courtship.display_name) (\(courtship.username))")
                                            .buttonStyle()
                                    }).disabled(uploading)
                                }
                            }
                            
                            if !uploading {
                                Text("Preview Video")
                                    .padding(.top)
                                    .bucketTextInternalStyle()
                                VideoPlayer(player: AVPlayer(url: url[0]))
                                    .frame(height: 300)
                            }
                            
//                            if (!uploading) {
//                                Button(action: {
//                                    if(editMode) {
//                                        editUpload()
//                                    }
//                                    else {
//                                        uploadInit(fileURL: url[0], uploadName: uploadName)
//                                    }
//                                }, label: {
//                                    Text(editMode ? "Save" : "Upload")
//                                        .buttonStyle()
//                                        .opacity(bucketID == "" || editMode && uploadName == uploadInfo.display_title && bucketID! == String(uploadInfo.bucket.id) && uploadInfo.visibility == visibility ? 0.5 : 1)
//                                }).disabled(bucketID == "" || editMode && uploadName == uploadInfo.display_title && bucketID! == String(uploadInfo.bucket.id) && uploadInfo.visibility == visibility)
//                            } else {
//                                ProgressView()
//                            }
                            
                            
//                            Text(uploadingStatus)
//                                .bucketNameStyle()
//                                .foregroundColor(Color.green)
//
//                            Text(progressPercent)
//                                .videoInfoStyle()
//                                .foregroundColor(Color.green)
                            
                        }.padding()
                            .navigationTitle(editMode ? "Edit Video" : "Upload Video")
                            .navigationBarItems(leading: Button(action: {
                                self.mode.wrappedValue.dismiss()
                            }, label: {
                                Text("Cancel")
                                    .bold()
                                    .foregroundColor(Color.green)
                            }), trailing: uploading ? AnyView(ProgressView()) : AnyView(Button(action: {
                                if(editMode) {
                                    editUpload()
                                }
                                else {
                                    uploadInit(fileURL: url[0], uploadName: uploadName)
                                }
                            }, label: {
                                Text(editMode ? "Save" : "Upload")
                                    .foregroundColor(Color.green)
                                    .bold()
                                    .opacity(bucketID == "-1" || editMode && uploadName == uploadInfo.display_title && bucketID! == String(uploadInfo.bucket.id) && uploadInfo.visibility == visibility ? 0.5 : 1)
                            }).disabled(bucketID == "-1" || editMode && uploadName == uploadInfo.display_title && bucketID! == String(uploadInfo.bucket.id) && uploadInfo.visibility == visibility)))
                    }
                }.onAppear(perform: {if(editMode) {initialize()}})
                
            }
            .sheet(isPresented: $isShowingNewStrokeView) {
                NewBucketView()
            }
            if showingError {
                Message(title: "Error", message: errorMessage, style: .error, isPresented: $showingError, view: nil)
            }
            if (uploading) {
                Message(title: uploadingStatus, message: "", style: .success, isPresented: $dontAllowClose, view: AnyView(ProgressView(value: progressPercentFraction, total: 100)))
            }
        }
        
    }
    
    
    // POST
    func upload(display_title: String, bucket_id: Int, visibility: Visibility, uid: String, fileURL: URL) async throws {
        
        // have to convert the visibility into an array of user IDs
        var newVisibility = NewVisibility()
        newVisibility.default = visibility.default
        for user in visibility.also_shared_with {
            newVisibility.also_shared_with.append(user.id)
        }
        
        
        let req: VideoReq = VideoReq(filename: fileURL.lastPathComponent, display_title: display_title, bucket_id: bucket_id, visibility: newVisibility)
        
        print(req)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            throw NetworkController.NetworkError.failedEncode
        }
        
        let url = URL(string: "\(nc.host)/uploads/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        do {
            let (data, response) = try await URLSession.shared.upload(for: request, from: encoded)
            print(response)
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
            self.uploading = false
            self.uploadingStatus = "Upload Failed :("
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
            progressPercentFraction = progress.fractionCompleted * 100
            
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

