import SwiftUI
import PhotosUI

struct ScanView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var symptomText: String = ""
    @State private var isAnalyzing = false
    @State private var resultText: String? = nil
    @State private var showCamera = false
    @State private var dangerLevel: Int? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Insect Bite Scanner")
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
                    .onChange(of: selectedItem) { oldValue, newValue in
                        if let newItem = newValue {
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
                    Text("Describe your symptoms")
                        .font(.headline)
                    TextEditor(text: $symptomText)
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
                            Label("Analyze Bite", systemImage: "waveform.path.ecg")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("PrimaryColor"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isAnalyzing || (selectedImage == nil && symptomText.isEmpty))

                if let result = resultText {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Result")
                            .font(.headline)

                        let parsed = parseSections(from: result)

                        if let levelStr = parsed["Danger Level (1-10)"], let level = Int(levelStr) {
                            DangerSliderView(dangerLevel: level)
                        }

                        if parsed.isEmpty {
                            Text(result).font(.body)
                        } else {
                            ForEach(parsed.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                Label {
                                    Text(value)
                                } icon: {
                                    Image(systemName: iconName(for: key))
                                        .foregroundColor(.blue)
                                }
                            }
                        }

                        Text("🧠 This result is AI-generated and not a substitute for professional medical advice.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                Spacer(minLength: 60)
            }
            .padding()
        }
        .sheet(isPresented: $showCamera) {
            CameraView(image: $selectedImage)
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    private func analyzeContent() {
        guard !symptomText.isEmpty || selectedImage != nil else { return }
        isAnalyzing = true
        resultText = nil
        dangerLevel = nil

        guard let user = authViewModel.currentUser else {
            resultText = "Error: User profile not loaded."
            isAnalyzing = false
            return
        }

        if let image = selectedImage,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            let base64Image = imageData.base64EncodedString()
            ChatGPTService.shared.sendImagePromptWithProfile(
                base64Image: base64Image,
                symptomText: symptomText,
                user: user
            ) { result in
                DispatchQueue.main.async {
                    isAnalyzing = false
                    switch result {
                    case .success(let response):
                        resultText = response
                        let parsed = parseSections(from: response)
                        if let levelStr = parsed["Danger Level (1-10)"], let level = Int(levelStr) {
                            dangerLevel = level
                        }
                    case .failure(let error):
                        resultText = "Error: \(error.localizedDescription)"
                    }
                }
            }
        } else {
            resultText = "Please provide an image to analyze the bite."
            isAnalyzing = false
        }
    }

    private func parseSections(from text: String) -> [String: String] {
        var result: [String: String] = [:]
        let lines = text.components(separatedBy: "\n")
        for line in lines {
            if let range = line.range(of: ":") {
                let key = String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let value = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                result[key] = value
            }
        }
        return result
    }

    private func iconName(for section: String) -> String {
        switch section.lowercased() {
        case "insect or cause": return "ant.circle"
        case "pattern description": return "scribble.variable"
        case "severity": return "exclamationmark.triangle"
        case "recommended care": return "bandage"
        case "possible risks": return "bolt.heart"
        case "when to seek medical attention": return "cross.case"
        case "danger level (1-10)": return "thermometer"
        case "disclaimer": return "info.circle"
        default: return "doc.text"
        }
    }
}

struct DangerSliderView: View {
    let dangerLevel: Int
    @State private var animatedLevel: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("⚠️ Bite Risk Assessment")
                    .font(.headline)
                Spacer()
                Text("\(dangerLevel)/10")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(dangerColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(dangerColor.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // Risk gauge/slider
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .opacity(0.3)
                    )
                    .frame(height: 16)
                
                // Filled portion
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: CGFloat(animatedLevel / 10) * UIScreen.main.bounds.width * 0.8, height: 16)
                
                // Indicator dot at the end of the fill
                Circle()
                    .fill(dangerColor)
                    .frame(width: 24, height: 24)
                    .shadow(radius: 2)
                    .offset(x: max(0, CGFloat(animatedLevel / 10) * UIScreen.main.bounds.width * 0.8 - 12))
            }
            .animation(.easeOut(duration: 1.0), value: animatedLevel)
            
            // Legend
            HStack {
                Text("Low")
                    .font(.caption)
                    .foregroundColor(.green)
                Spacer()
                Text("Moderate")
                    .font(.caption)
                    .foregroundColor(.yellow)
                Spacer()
                Text("High")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            // Risk description
            HStack {
                Image(systemName: riskIcon)
                    .foregroundColor(dangerColor)
                Text(riskDescription)
                    .font(.subheadline.bold())
                    .foregroundColor(dangerColor)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animatedLevel = Double(dangerLevel)
            }
        }
    }
    
    private var dangerColor: Color {
        switch dangerLevel {
        case 1...3: return .green
        case 4...6: return .yellow
        case 7...8: return .orange
        case 9...10: return .red
        default: return .gray
        }
    }
    
    private var riskDescription: String {
        switch dangerLevel {
        case 1...3: return "Low Risk - Typically non-venomous"
        case 4...6: return "Moderate Risk - May require attention"
        case 7...8: return "High Risk - Medical consultation advised"
        case 9...10: return "Severe Risk - Seek immediate medical care"
        default: return "Unknown Risk"
        }
    }
    
    private var riskIcon: String {
        switch dangerLevel {
        case 1...3: return "checkmark.circle"
        case 4...6: return "exclamationmark.triangle"
        case 7...8: return "exclamationmark.octagon"
        case 9...10: return "cross.circle"
        default: return "questionmark.circle"
        }
    }
}
