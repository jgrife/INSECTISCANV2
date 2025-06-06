import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var age = ""
    @State private var gender = ""
    @State private var skinColor = ""
    @State private var allergies = ""
    @State private var medicalConditions = ""
    @State private var country = ""
    @State private var errorMessage = ""

    let genders = ["", "Male", "Female", "Non-binary", "Prefer not to say"]
    let skinColors = ["", "Fair", "Light", "Medium", "Olive", "Brown", "Dark"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Required")) {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $password)
                }

                Section(header: Text("Optional")) {
                    TextField("Age (optional)", text: $age)
                        .keyboardType(.numberPad)

                    Picker("Gender", selection: $gender) {
                        ForEach(genders, id: \.self) { option in
                            Text(option)
                        }
                    }

                    Picker("Skin Color", selection: $skinColor) {
                        ForEach(skinColors, id: \.self) { option in
                            Text(option)
                        }
                    }

                    TextField("Allergies (comma separated)", text: $allergies)
                    TextField("Medical Conditions (comma separated)", text: $medicalConditions)
                    TextField("Country", text: $country)
                }

                Section {
                    Button(action: {
                        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
                            errorMessage = "Please fill in name, email, and password."
                            return
                        }

                        let ageInt = Int(age)  // If empty or invalid, becomes nil
                        let allergyList = allergies.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                        let conditionList = medicalConditions.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

                        authViewModel.signup(
                            name: name,
                            email: email,
                            password: password,
                            age: ageInt,
                            gender: gender.isEmpty ? nil : gender,
                            skinColor: skinColor.isEmpty ? nil : skinColor,
                            allergies: allergyList.isEmpty ? nil : allergyList,
                            medicalConditions: conditionList.isEmpty ? nil : conditionList,
                            country: country.isEmpty ? nil : country
                        ) { result in
                            switch result {
                            case .success:
                                errorMessage = ""
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                            }
                        }
                    }) {
                        Text("Create Account")
                    }
                }

                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Create Account")
        }
    }
}
