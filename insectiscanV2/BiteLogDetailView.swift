import SwiftUI
import Firebase
import FirebaseStorage
import PhotosUI
import Foundation

struct BiteLogDetailView: View {
    let entry: BiteLogEntry
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var locationManager: LocationManager

    @State private var progressImages: [ProgressPhoto] = []
    @State private var showPhotoPicker = false
    @State private var selectedDay = 1
    @State private var selectedImage: UIImage? = nil
    @State private var healingStatus: String? = nil
    @State private var newPhotoNote: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                AsyncImage(url: URL(string: entry.imageURL)) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Color.gray.opacity(0.1)
                }
                .cornerRadius(10)

                if let location = entry.locationDescription {
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                        Text("Logged near: \(location)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Text(entry.diagnosisSummary)
                    .font(.title3.bold())

                Text(entry.notes)
                    .font(.body)

                if let severity = entry.severity {
                    Text("Severity: \(severity)/10")
                        .padding(8)
                        .background(severityColor(for: severity).opacity(0.2))
                        .foregroundColor(severityColor(for: severity))
                        .cornerRadius(8)
                }

                Divider()
                Text("Healing Progress Photos")
                    .font(.headline)

                ForEach(progressImages.sorted(by: { $0.day < $1.day })) { photo in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Day \(photo.day)")
                                .font(.subheadline.bold())
                            Spacer()
                            Button("Edit") {
                                selectedDay = photo.day
                                newPhotoNote = photo.notes ?? ""
                                showPhotoPicker = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)

                            Button(role: .destructive) {
                                deleteProgressPhoto(photo)
                            } label: {
                                Text("Delete")
                            }
                            .font(.caption)
                        }

                        AsyncImage(url: URL(string: photo.imageURL)) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            Color.gray.opacity(0.1)
                        }
                        .cornerRadius(8)

                        if let status = photo.healingStatus {
                            Text("AI Healing Assessment: \(status)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }

                        if let note = photo.notes {
                            Text("Notes: \(note)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 8)
                }

                if let status = healingStatus {
                    Divider()
                    Text("Healing Status 🧠")
                        .font(.headline)
                    Text(status)
                        .font(.body)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }

                Picker("Add Photo For Day", selection: $selectedDay) {
                    Text("Day 1").tag(1)
                    Text("Day 3").tag(3)
                    Text("Day 7").tag(7)
                }
                .pickerStyle(SegmentedPickerStyle())

                TextField("Optional notes for this photo...", text: $newPhotoNote)
                    .textFieldStyle(.roundedBorder)

                Button("Upload Progress Photo") {
                    showPhotoPicker = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(authViewModel.currentUser == nil)
            }
            .padding()
        }
        .onAppear {
            progressImages = entry.progressImages ?? []
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(sourceType: .photoLibrary, selectedImage: $selectedImage)
                .onDisappear {
                    if let image = selectedImage,
                       let uid = authViewModel.currentUser?.id,
                       let data = image.jpegData(compressionQuality: 0.8) {
                        uploadProgressPhoto(imageData: data, userId: uid)
                    }
                }
        }
    }

    private func severityColor(for level: Int) -> Color {
        switch level {
        case 1...3: return .green
        case 4...6: return .orange
        case 7...10: return .red
        default: return .gray
        }
    }

    private func uploadProgressPhoto(imageData: Data, userId: String) {
        let photoId = UUID()
        let storageRef = Storage.storage().reference().child("users/\(userId)/biteLogs/\(entry.id.uuidString)/progress_day\(selectedDay).jpg")

        storageRef.putData(imageData) { _, error in
            guard error == nil else {
                print("❌ Upload failed: \(error!.localizedDescription)")
                return
            }

            storageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    print("❌ URL retrieval failed")
                    return
                }

                let newPhoto = ProgressPhoto(
                    id: photoId,
                    day: selectedDay,
                    imageURL: downloadURL.absoluteString,
                    date: Date(),
                    healingStatus: nil,
                    notes: newPhotoNote.isEmpty ? nil : newPhotoNote
                )

                var updatedPhotos = entry.progressImages ?? []
                updatedPhotos.removeAll { $0.day == selectedDay }
                updatedPhotos.append(newPhoto)

                let updateData: [String: Any] = [
                    "progressImages": updatedPhotos.map { [
                        "id": $0.id.uuidString,
                        "day": $0.day,
                        "imageURL": $0.imageURL,
                        "date": Timestamp(date: $0.date),
                        "healingStatus": $0.healingStatus ?? "",
                        "notes": $0.notes ?? ""
                    ] }
                ]

                Firestore.firestore().collection("users").document(userId).collection("biteLogs").document(entry.id.uuidString).updateData(updateData)

                self.progressImages = updatedPhotos
                self.newPhotoNote = ""
                self.selectedImage = nil

                if [3, 7].contains(selectedDay), let day1 = updatedPhotos.first(where: { $0.day == 1 }) {
                    compareHealingImages(day1URL: day1.imageURL, latestURL: downloadURL.absoluteString)
                }
            }
        }
    }

    private func deleteProgressPhoto(_ photo: ProgressPhoto) {
        guard let userId = authViewModel.currentUser?.id else { return }

        var updatedPhotos = entry.progressImages ?? []
        updatedPhotos.removeAll { $0.id == photo.id }

        let updateData: [String: Any] = [
            "progressImages": updatedPhotos.map { [
                "id": $0.id.uuidString,
                "day": $0.day,
                "imageURL": $0.imageURL,
                "date": Timestamp(date: $0.date),
                "healingStatus": $0.healingStatus ?? "",
                "notes": $0.notes ?? ""
            ] }
        ]

        Firestore.firestore().collection("users").document(userId).collection("biteLogs").document(entry.id.uuidString).updateData(updateData)

        self.progressImages = updatedPhotos
    }

    private func compareHealingImages(day1URL: String, latestURL: String) {
        ChatGPTService.shared.sendHealingComparison(day1URL: day1URL, dayXURL: latestURL) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let assessment):
                    self.healingStatus = assessment
                case .failure(let error):
                    self.healingStatus = "AI comparison failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
