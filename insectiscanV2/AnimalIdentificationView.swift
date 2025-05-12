import SwiftUI
import PhotosUI
import UIKit

extension UIApplication {
    func hideKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct AnimalIdentificationView: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var notes: String = ""
    @State private var isAnalyzing = false
    @State private var resultText: String? = nil
    @State private var showCamera = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Animal Identifier")
                    .font(.largeTitle.bold())
                    .padding(.top)

                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(Color("PrimaryColor"))
                                Text("Select or take a photo")
                                    .foregroundColor(.gray)
                            }
                        )
                }

                HStack(spacing: 12) {
                    Button {
                        showCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Choose Photo", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("AccentColor"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        if let newItem {
                            Task {
                                if let data = try? await newItem.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    selectedImage = uiImage
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading) {
                    Text("Add any notes")
                        .font(.headline)
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }

                Button(action: analyzeContent) {
                    HStack {
                        if isAnalyzing {
                            ProgressView()
                        } else {
                            Label("Analyze Animal", systemImage: "binoculars")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("PrimaryColor"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isAnalyzing || selectedImage == nil)

                if let result = resultText {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Result")
                            .font(.headline)
                        Text(result)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                Spacer(minLength: 60)
            }
            .padding()
        }
        .onTapGesture {
            UIApplication.shared.hideKeyboard()
        }
        .sheet(isPresented: $showCamera) {
            CameraView(image: $selectedImage)
        }
    }

    private func analyzeContent() {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            resultText = "No image data found."
            return
        }

        let base64Image = imageData.base64EncodedString()
        isAnalyzing = true
        resultText = nil

        ChatGPTService.shared.sendAnimalPrompt(base64Image: base64Image, userNotes: notes) { result in
            DispatchQueue.main.async {
                self.isAnalyzing = false
                switch result {
                case .success(let response):
                    self.resultText = response
                case .failure(let error):
                    self.resultText = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
