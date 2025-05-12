import SwiftUI

struct EmergencyHelpView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "ant.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .padding()
                .foregroundColor(.white)
                .background(Color.red)
                .clipShape(Circle())
                .shadow(radius: 10)

            Text("EMERGENCY HELP")
                .font(.title.bold())
                .foregroundColor(.primary)

            Text("If you’re having an allergic reaction, or were bitten by a venomous insect, call emergency services immediately.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button(action: {
                if let url = URL(string: "tel://911"), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "phone.fill")
                        .font(.headline)
                    Text("Call")
                        .font(.headline)
                        .bold()
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .cornerRadius(16)
                .padding(.horizontal)
            }

            Link("View First Aid Information",
                 destination: URL(string: "https://www.redcross.org/take-a-class/first-aid")!)
                .font(.footnote)
                .foregroundColor(.blue)

            Spacer()
        }
        .padding()
        .navigationTitle("Emergency Help")
        .navigationBarTitleDisplayMode(.inline)
    }
}
