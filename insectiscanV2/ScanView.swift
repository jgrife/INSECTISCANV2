// ScanView.swift (Complete with Location Tagging and Reset Button)

import SwiftUI
import PhotosUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

struct Product: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let url: URL?
}

struct ScanView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var locationManager: LocationManager

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var symptomText: String = ""
    @State private var isAnalyzing = false
    @State private var resultText: String? = nil
    @State private var parsedSections: [String: String] = [:]
    @State private var products: [Product] = []
    @State private var dangerLevel: Int? = nil
    @State private var showCamera = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Insect Bite Scanner")
                    .font(.largeTitle.bold())
                    .padding(.top)

                imageSection
                photoControls

                VStack(alignment: .leading) {
                    Text("Describe your symptoms")
                        .font(.headline)
                    TextEditor(text: $symptomText)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }

                analyzeButton

                if let result = resultText {
                    resultView
                    resetButton
                }

                Spacer(minLength: 60)
            }
            .padding()
        }
        .sheet(isPresented: $showCamera) {
            CameraView(image: $selectedImage)
        }
        .onTapGesture {
            UIApplication.shared.endEditing()
        }
    }

    private var imageSection: some View {
        Group {
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
        }
    }

    private var photoControls: some View {
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
    }

    private var analyzeButton: some View {
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
    }

    private var resetButton: some View {
        Button("Reset Scan") {
            selectedItem = nil
            selectedImage = nil
            symptomText = ""
            resultText = nil
            parsedSections = [:]
            products = []
            dangerLevel = nil
        }
        .font(.body)
        .foregroundColor(.red)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private var resultView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Result")
                .font(.headline)

            if let level = dangerLevel {
                DangerSliderView(dangerLevel: level)
            }

            ForEach(parsedSections.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                if key.lowercased() != "recommended products" {
                    Label {
                        Text(value)
                    } icon: {
                        Image(systemName: iconName(for: key))
                            .foregroundColor(.blue)
                    }
                }
            }

            if !products.isEmpty {
                Divider()
                Text("🛒 Suggested Products")
                    .font(.headline)
                ForEach(products) { product in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.name)
                            .bold()
                        Text(product.description)
                        if let url = product.url {
                            Link("View", destination: url)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
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

    private func analyzeContent() {
        guard let user = authViewModel.currentUser else {
            resultText = "Error: User profile not loaded."
            return
        }

        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            resultText = "Please provide a valid image."
            return
        }

        isAnalyzing = true
        resultText = nil
        dangerLevel = nil
        parsedSections = [:]
        products = []

        let base64Image = imageData.base64EncodedString()
        
        print("📤 Submitting scan to ChatGPT...")

        ChatGPTService.shared.sendImagePromptWithProfile(
            base64Image: base64Image,
            symptomText: symptomText,
            user: user
        ) { result in
            DispatchQueue.main.async {
                self.isAnalyzing = false
                switch result {
                case .success(let response):
                    print("✅ Received response: \(response)")
                    self.resultText = response
                    let parsed = parseSections(from: response)
                    self.parsedSections = parsed
                    if let levelStr = parsed["Danger Level (1-10)"], let level = Int(levelStr) {
                        self.dangerLevel = level
                    }
                    if let productBlock = parsed["Recommended Products"] {
                        self.products = parseProducts(from: productBlock)
                    }
                    if let image = self.selectedImage {
                        self.autoSaveScanEntry(userId: user.id, image: image, parsed: parsed, notes: self.symptomText, severity: self.dangerLevel)
                    }
                case .failure(let error):
                    print("❌ ChatGPT error: \(error.localizedDescription)")
                    self.resultText = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func autoSaveScanEntry(userId: String, image: UIImage, parsed: [String: String], notes: String, severity: Int?) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        let id = UUID()
        let storageRef = Storage.storage().reference().child("users/\(userId)/biteLogs/\(id.uuidString).jpg")

        storageRef.putData(imageData) { _, error in
            if let error = error {
                print("❌ Failed to upload scan image: \(error)")
                return
            }

            storageRef.downloadURL { url, error in
                guard let url = url else {
                    print("❌ Failed to get scan image URL")
                    return
                }

                // Create location description from LocationManager
                let locationDesc = [locationManager.locality, locationManager.administrativeArea]
                    .compactMap { $0 }
                    .joined(separator: ", ")

                let entry: [String: Any] = [
                    "id": id.uuidString,
                    "date": Timestamp(date: Date()),
                    "imageURL": url.absoluteString,
                    "notes": notes,
                    "diagnosisSummary": parsed["Insect or Cause"] ?? "Unknown",
                    "severity": severity ?? 0,
                    "autoSaved": true,
                    "locationDescription": locationDesc
                ]

                Firestore.firestore().collection("users").document(userId).collection("biteLogs").document(id.uuidString).setData(entry) { error in
                    if let error = error {
                        print("❌ Failed to save scan entry: \(error)")
                    } else {
                        pruneOldAutoSavedEntries(for: userId)
                    }
                }
            }
        }
    }

    private func pruneOldAutoSavedEntries(for userId: String) {
        let logsRef = Firestore.firestore().collection("users").document(userId).collection("biteLogs")
        logsRef.whereField("autoSaved", isEqualTo: true).order(by: "date", descending: true).getDocuments { snapshot, error in
            guard let docs = snapshot?.documents, docs.count > 5 else { return }
            let excess = docs.dropFirst(5)
            for doc in excess {
                doc.reference.delete(completion: nil)
            }
        }
    }

    private func parseSections(from text: String) -> [String: String] {
        var result: [String: String] = [:]
        let lines = text.components(separatedBy: "\n")
        var currentKey: String?
        var currentValue = ""

        for line in lines {
            if let colonRange = line.range(of: ":") {
                if let key = currentKey {
                    result[key] = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                currentKey = String(line[..<colonRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                currentValue = String(line[colonRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            } else if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                currentValue += "\n" + line
            }
        }

        if let key = currentKey {
            result[key] = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return result
    }

    private func parseProducts(from block: String) -> [Product] {
        let lines = block.components(separatedBy: .newlines).filter { $0.contains("-") }
        return lines.compactMap { line in
            let components = line.split(separator: "-", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard components.count >= 2 else { return nil }

            let name = components[0].replacingOccurrences(of: "• ", with: "").replacingOccurrences(of: "- ", with: "")
            let description = components[1]
            let url = description.extractURL()
            return Product(name: name, description: description, url: url)
        }
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
        case "recommended products": return "cross.case.fill"
        default: return "doc.text"
        }
    }
}

extension String {
    func extractURL() -> URL? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
              let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: utf16.count)),
              let range = Range(match.range, in: self) else {
            return nil
        }
        return URL(string: String(self[range]))
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

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
                        startPoint: .leading, endPoint: .trailing
                    ).opacity(0.3))
                    .frame(height: 16)

                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: CGFloat(animatedLevel / 10) * UIScreen.main.bounds.width * 0.8, height: 16)

                Circle()
                    .fill(dangerColor)
                    .frame(width: 24, height: 24)
                    .shadow(radius: 2)
                    .offset(x: max(0, CGFloat(animatedLevel / 10) * UIScreen.main.bounds.width * 0.8 - 12))
            }
            .animation(.easeOut(duration: 1.0), value: animatedLevel)

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

// NOTE: Make sure your LocationManager has 'locality' and 'administrativeArea' properties
