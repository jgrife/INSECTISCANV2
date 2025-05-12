import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import Combine

final class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false

    private var cancellables = Set<AnyCancellable>()
    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    init() {
        checkAuthState()
    }

    private func checkAuthState() {
        if let user = auth.currentUser {
            print("✅ Existing user session found: \(user.email ?? "unknown")")
            fetchUser(uid: user.uid)
        } else {
            print("ℹ️ No authenticated user found.")
        }
    }

    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                print("❌ Login error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let uid = result?.user.uid else {
                print("❌ Login failed: no UID returned")
                completion(.failure(NSError(domain: "LoginError", code: -1)))
                return
            }

            print("✅ Firebase login successful for: \(email)")
            self?.fetchUser(uid: uid)
            completion(.success(()))
        }
    }

    func signup(
        name: String,
        email: String,
        password: String,
        age: Int,
        gender: String,
        skinColor: String,
        allergies: [String],
        medicalConditions: [String], // ✅ Now included
        country: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                print("❌ Signup error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let uid = result?.user.uid else {
                print("❌ Signup failed: no UID returned")
                completion(.failure(NSError(domain: "SignupError", code: -1)))
                return
            }

            let newUser = User(
                id: uid,
                name: name,
                email: email,
                age: age,
                gender: gender,
                skinColor: skinColor,
                allergies: allergies,
                medicalConditions: medicalConditions, // ✅ Now passed in
                country: country
            )

            self?.saveUserToFirestore(newUser) { saveResult in
                switch saveResult {
                case .success:
                    print("✅ User saved to Firestore")
                    DispatchQueue.main.async {
                        self?.currentUser = newUser
                        self?.isAuthenticated = true
                    }
                    completion(.success(()))
                case .failure(let saveError):
                    print("❌ Firestore save failed:", saveError.localizedDescription)
                    completion(.failure(saveError))
                }
            }
        }
    }

    private func saveUserToFirestore(_ user: User, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection("users").document(user.id).setData(from: user) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    private func fetchUser(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            if let data = snapshot?.data() {
                do {
                    let user = try Firestore.Decoder().decode(User.self, from: data)
                    DispatchQueue.main.async {
                        self?.currentUser = user
                        self?.isAuthenticated = true
                        print("✅ User loaded from Firestore: \(user.name)")
                    }
                } catch {
                    print("❌ Error decoding user: \(error.localizedDescription)")
                }
            } else if let error = error {
                print("❌ Error fetching user: \(error.localizedDescription)")
            }
        }
    }

    func updateUserProfile(_ updatedUser: User) {
        do {
            try db.collection("users").document(updatedUser.id).setData(from: updatedUser) { [weak self] error in
                if let error = error {
                    print("❌ Failed to update user: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self?.currentUser = updatedUser
                        print("✅ Profile updated successfully")
                    }
                }
            }
        } catch {
            print("❌ Error encoding user data: \(error.localizedDescription)")
        }
    }

    func logout() {
        do {
            try auth.signOut()
            currentUser = nil
            isAuthenticated = false
            print("ℹ️ User signed out.")
        } catch {
            print("❌ Error signing out: \(error.localizedDescription)")
        }
    }
}
