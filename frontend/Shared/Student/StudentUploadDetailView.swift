//
//  StudentUploadDetailView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI
import MediaPicker
import Alamofire

struct StudentUploadDetailView: View {
    @EnvironmentObject private var nc: NetworkController
    @State private var showingFeedback = false
    
    // Settings for the Feedback/Video view
    @State private var showOnlyVideo = false
    //@State private var uploadID = ""
    
    @State private var isShowingMediaPicker = false
    @State private var isShowingCamera = false
    @State private var url: [URL] = []
    @State private var name = ""
    @State private var originalName = ""
    var student: Bool
    //@State private var bucketContents: BucketContents = BucketContents(id: -1, name: "", user_id: -1, uploads: [])
    var bucketID: String
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var awaiting = false
    @State private var uploading = false
    @State private var uploadingStatus = ""
    @State private var progressPercent = ""
    @State private var showsUploadAlert = false
    @State private var uploadName = ""
    
    func initialize() {
        Task {
            do {
                awaiting = true
                //try await bucketContents = nc.getBucketContents(uid: "2", bucketID: "\(bucketID)")
                try await nc.getBucketContents(uid: "\(student ? nc.userData.shared.id : 4)", bucketID: "\(student ? bucketID : "9")")
                name = nc.userData.bucketContents.name
                print("Finsihed init")
                awaiting = false
                //nc.userData.bucketContents.uploads.sort(by: {$0.created > $1.created})
            } catch {
                print(error)
                errorMessage = error.localizedDescription
                showingError = true
                awaiting = false
            }
        }
    }
    
    func uploadInit(fileURL: URL, uploadName: String) {
        Task {
            do {
                uploading = true
                uploadingStatus = "Uploading..."
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
            initialize()
        } catch {
            
            throw NetworkController.NetworkError.failedDecode
        }
    }
    
    
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading) {
                    if (awaiting) {
                        ProgressView()
                    } else if (showingError) {
                        Text(UserData.computeErrorMessage(errorMessage: errorMessage)).padding()
                    } else {
                        Text(nc.userData.bucketContents.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .padding([.top, .leading, .trailing])
                            .onAppear(perform: {print("fgg")})
                        
                        HStack {
                            TextField("Name", text: $name)
                                .autocapitalization(.none)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onAppear(perform: {
                                    self.originalName = name
                                })
                            
                            Button(action: {
                                print("save")
                                originalName = name
                            }, label: {
                                Text("Save")
                                    .foregroundColor(name == originalName ? Color.gray : Color.green)
                                    .fontWeight(.bold)
                            })
                                .disabled(name == originalName)
                        }.padding(.horizontal)
                        
                        if (student) {
                            Button(action: {
                                isShowingMediaPicker.toggle()
                            }, label: {
                                Text("Upload New Video")
                                    .padding(.vertical, 15)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                            }).disabled(uploading)
                                .padding([.horizontal, .top, .bottom])
                                .mediaImporter(isPresented: $isShowingMediaPicker,
                                               allowedMediaTypes: .all,
                                               allowsMultipleSelection: false) { result in
                                    switch result {
                                    case .success(let url):
                                        self.url = url
                                        print(url)
                                        showsUploadAlert = true
                                        //uploadInit(fileURL: url[0])
                                    case .failure(let error):
                                        print(error)
                                        self.url = []
                                    }
                                }
                                   .sheet(isPresented: $showsUploadAlert) {
                                       VStack {
                                           Text("Set Video Name")
                                               .font(.largeTitle)
                                               .fontWeight(.bold)
                                               .foregroundColor(.green)
                                               .padding([.top, .leading, .trailing])
                                           TextField("Sample Video Name", text: $uploadName)
                                               .padding([.top, .leading, .trailing])
                                           Spacer()
                                           Image("testimage")
                                               .frame(maxWidth: .infinity, maxHeight: 500)
                                               .cornerRadius(10)
                                               .shadow(radius: 5)
                                           Spacer()
                                           Spacer()
                                           HStack {
                                               Button(action: {
                                                   showsUploadAlert = false
                                               }, label: {
                                                   Text("Cancel")                            .padding(.vertical, 15)
                                                       .frame(maxWidth: .infinity)
                                                       .background(.white)
                                                       .cornerRadius(10)
                                                       .foregroundColor(.green)
                                                       .overlay(
                                                           RoundedRectangle(cornerRadius: 10)
                                                               .stroke(Color.green, lineWidth: 2)
                                                        )
                                               })
                                               Spacer()
                                               Button(action: {
                                                   uploadInit(fileURL: url[0], uploadName: uploadName)
                                                   showsUploadAlert = false
                                               }, label: {
                                                   Text("Upload")
                                                       .padding(.vertical, 15)
                                                       .frame(maxWidth: .infinity)
                                                       .background(Color.green)
                                                       .cornerRadius(10)
                                                       .foregroundColor(.white)
                                               })
                                           }
                                           .padding([.top, .leading, .trailing])
                                       }
                 
                                   }
                            Button(action: {
                                isShowingCamera.toggle()
                            }, label: {
                                Text("Capture a Video")
                                    .padding(.vertical, 15)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                            })
                                .padding([.horizontal, .top, .bottom])
                                .sheet(isPresented: $isShowingCamera) {
                                    CameraView()

                                }
                        }
                        
                        ForEach(nc.userData.bucketContents.uploads) { upload in
                            HStack {
                                NavigationLink(destination: StudentFeedbackView(text: "SJ", student: true, showOnlyVideo: true, uploadID: "\(upload.id)").navigationTitle("Feedback").navigationBarTitleDisplayMode(.inline))
                                {
                                    if (!upload.stream_ready) {
                                        ProgressView()
                                    } else {
                                        Image("testimage")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(maxWidth: 200, maxHeight: 200)
                                            .cornerRadius(10)
                                            .shadow(radius: 5)
                                    }
                                    
                                }
                                
                                //                                 Button(action: {
                                //                                     showingFeedback.toggle()
                                //                                 }, label: {
                                //                                     if (!upload.stream_ready) {
                                //                                         ProgressView()
                                //                                     } else {
                                //                                         Image("testimage")
                                //                                             .resizable()
                                //                                             .scaledToFill()
                                //                                             .frame(maxWidth: 200, maxHeight: 200)
                                //                                             .cornerRadius(10)
                                //                                             .shadow(radius: 5)
                                //                                     }
                                //
                                //                                 }).sheet(isPresented: $showingFeedback) {
                                //                                     StudentFeedbackView(text: "This is some sample feedback", student: student, showOnlyVideo: true, uploadID: "\(upload.id)")
                                //                                 }
                                
                                VStack(alignment: .leading) {
                                    Text(upload.created.formatted())
                                        .font(.title2)
                                        .fontWeight(.heavy)
                                        .foregroundColor(Color.green)
                                    
                                    Text("\(upload.id)")
                                    
                                    Button(action: {
                                        showingFeedback.toggle()
                                    }, label: {
                                        
                                        if (!upload.stream_ready) {
                                            Text("Processing video, please wait...")
                                                .font(.footnote)
                                                .foregroundColor(Color.green)
                                        }
                                        
                                        else if (upload.comments.count == 0) {
                                            Image(systemName: student ? "person.crop.circle.badge.clock.fill" : "plus.bubble.fill")
                                                .resizable()
                                                .scaledToFill()
                                                .foregroundColor(student ? Color.gray: Color.green)
                                                .frame(width: 25, height: 25)
                                                .opacity(student ? 0.5 : 1)
                                        }
                                        //                                if (studentInfo.feedbacks[i] == .unread) {
                                        //                                    Image(systemName: "text.bubble.fill")
                                        //                                        .resizable()
                                        //                                        .scaledToFill()
                                        //                                        .foregroundColor(Color.green)
                                        //                                        .frame(width: 25, height: 25)
                                        //                                }
                                        //                                if (studentInfo.feedbacks[i] == .read) {
                                        //                                    Image(systemName: "text.bubble.fill")
                                        //                                        .resizable()
                                        //                                        .scaledToFill()
                                        //                                        .foregroundColor(Color.gray)
                                        //                                        .frame(width: 25, height: 25)
                                        //                                }
                                        
                                    })
                                        .disabled(upload.comments.count == 0 && student ? true : false)
                                    
                                    Spacer()
                                    
                                    //                                                                 Text("\(studentInfo.times[i]) | \(studentInfo.sizes[i])")
                                    //                                                                     .font(.footnote)
                                    //                                                                     .foregroundColor(Color.green)
                                    
                                    
                                    
                                }.padding(.leading, 1)
                            }
                            .padding(.horizontal)
                        }
                    }
                }.navigationBarItems(trailing: Button(action: {
                    initialize()
                }, label: {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .foregroundColor(Color.green)
                }))
                
                
                
            }.onAppear(perform: {initialize()})
        }
        
        if (uploading) {
            VStack(alignment: .leading) {
                Text(uploadingStatus)
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(Color.white)
                
                Text(progressPercent)
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundColor(Color.white)
                
            }
            .padding()
            .frame(width: 400)
            .background(Color.green)
            .cornerRadius(10)
            .padding(.horizontal)
            .shadow(radius: 5)
            .allowsHitTesting(false)
            
        }
    }
}

//struct StudentUploadDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        StudentUploadDetailView()
//    }
//}
