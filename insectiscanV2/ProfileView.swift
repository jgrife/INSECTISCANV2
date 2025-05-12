import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isEditing = false

    @State private var name = ""
    @State private var email = ""
    @State private var age = ""
    @State private var gender = ""
    @State private var skinColor = ""
    @State private var allergies = ""
    @State private var medicalConditions = ""
    @State private var country = ""

    let genderOptions = ["Male", "Female", "Non-Binary", "Prefer not to say"]
    let skinColorOptions = ["Fair", "Light", "Medium", "Tan", "Dark", "Deep"]

    var body: some View {
        NavigationView {
            Form {
                if isEditing {
                    Section(header: Text("Edit Info")) {
                        TextField("Name", text: $name)
                        TextField("Email", text: $email)
                        TextField("Age", text: $age)
                            .keyboardType(.numberPad)

                        Picker("Gender", selection: $gender) {
                            ForEach(genderOptions, id: \.self) { option in
                                Text(option)
                            }
                        }

                        Picker("Skin Color", selection: $skinColor) {
                            ForEach(skinColorOptions, id: \.self) { option in
                                Text(option)
                            }
                        }

                        TextField("Allergies (comma-separated)", text: $allergies)
                        TextField("Medical Conditions (comma-separated)", text: $medicalConditions)
                        TextField("Country", text: $country)

                        Button("Save Changes") {
                            saveProfileChanges()
                            isEditing = false
                        }
                    }
                } else {
                    Section(header: Text("Basic Info")) {
                        Text("Name: \(authViewModel.currentUser?.name ?? "N/A")")
                        Text("Email: \(authViewModel.currentUser?.email ?? "N/A")")
                        if let age = authViewModel.currentUser?.age {
                            Text("Age: \(age)")
                        }
                        if let gender = authViewModel.currentUser?.gender {
                            Text("Gender: \(gender)")
                        }
                        if let skinColor = authViewModel.currentUser?.skinColor {
                            Text("Skin Color: \(skinColor)")
                        }
                    }

                    Section(header: Text("Medical Info")) {
                        if let allergies = authViewModel.currentUser?.allergies, !allergies.isEmpty {
                            Text("Allergies: \(allergies.joined(separator: ", "))")
                        } else {
                            Text("Allergies: None listed")
                        }
                        if let conditions = authViewModel.currentUser?.medicalConditions, !conditions.isEmpty {
                            Text("Medical Conditions: \(conditions.joined(separator: ", "))")
                        } else {
                            Text("Medical Conditions: None listed")
                        }
                    }
                }

                Section {
                    Button(isEditing ? "Cancel" : "Edit Profile") {
                        if let user = authViewModel.currentUser {
                            name = user.name
                            email = user.email
                            age = user.age.map { String($0) } ?? ""
                            gender = user.gender ?? ""
                            skinColor = user.skinColor ?? ""
                            allergies = user.allergies?.joined(separator: ", ") ?? ""
                            medicalConditions = user.medicalConditions?.joined(separator: ", ") ?? ""
                            country = user.country ?? ""
                        }
                        isEditing.toggle()
                    }
                    .foregroundColor(.blue)

                    Button("Log Out") {
                        authViewModel.logout()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("My Profile")
        }
    }

    private func saveProfileChanges() {
        guard var user = authViewModel.currentUser else { return }
        user.name = name
        user.email = email
        user.age = Int(age)
        user.gender = gender
        user.skinColor = skinColor
        user.allergies = allergies.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        user.medicalConditions = medicalConditions.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        user.country = country

        authViewModel.updateUserProfile(user)
    }
}
