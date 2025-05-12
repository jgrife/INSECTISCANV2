import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Log In")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button("Log In") {
                    authViewModel.login(email: email, password: password) { result in
                        switch result {
                        case .success:
                            print("✅ Login successful")
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                        }
                    }
                }
                .buttonStyle(.borderedProminent)

                NavigationLink("Don't have an account? Sign Up", destination: SignUpView())
                    .padding(.top, 10)

                Spacer()
            }
            .padding()
        }
    }
}
