//
//  EditProfileView.swift
//  insectiscanV2
//
//  Created by Jason Grife on 4/30/25.
//




// MARK: - 8. EditProfileView.swift
import SwiftUI

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var age: String = ""
    @State private var gender: String = ""
    @State private var skinTone: String = ""
    @State private var allergies: String = ""
    @State private var region: String = ""
    @State private var country: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Info")) {
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                    TextField("Gender", text: $gender)
                    TextField("Skin Tone", text: $skinTone)
                    TextField("Country", text: $country)
                }

                Section(header: Text("Medical Info")) {
                    TextField("Known Allergies", text: $allergies)
                    TextField("Region/State", text: $region)
                }

                Section {
                    Button(action: {
                        // Save logic or Firestore update here
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save")
                        }
                        .foregroundColor(Color("PrimaryColor"))
                    }

                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Cancel")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
