import SwiftUI

struct TermsAndConditionsView: View {
    @AppStorage("didAcceptTerms") private var didAcceptTerms = false

    var body: some View {
        VStack {
            Text("Terms & Conditions")
                .font(.largeTitle)
                .bold()
                .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Welcome to InsectiScan. Before using the app, please read the following terms and conditions carefully.")
                    
                    Text("1. **Use of Information**")
                    Text("Information provided by InsectiScan is for general guidance and safety only. It is not a substitute for professional medical or emergency advice.")

                    Text("2. **Data Privacy**")
                    Text("We may collect minimal personal data to help personalize your experience. This data is stored securely and never sold.")

                    Text("3. **Outdoor Risk**")
                    Text("Always exercise your own judgment when outdoors. InsectiScan does not guarantee 100% accuracy of bite analysis or species identification.")

                    Text("4. **Limitation of Liability**")
                    Text("By using this app, you agree that the developers are not liable for any injuries or damages arising from its use.")

                    Text("5. **Acceptance**")
                    Text("By tapping 'I Agree', you accept these terms and conditions and may proceed to use the app.")
                }
                .padding()
                .font(.body)
            }

            Button(action: {
                didAcceptTerms = true
            }) {
                Text("I Agree")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .padding(.bottom)
        }
    }
}
