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
            print("🔥 Firebase UID: \(user.uid)")
            fetchUser(uid: user.uid)
        } else {
            print("ℹ️ No authenticated user found.")
        }
    }

    // MARK: - Login

    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                print("❌ Login error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let uid = result?.user.uid else {
                completion(.failure(NSError(domain: "LoginError", code: -1, userInfo: [NSLocalizedDescriptionKey: "UID not found"])))
                return
            }

            print("✅ Firebase login successful for: \(email)")
            self?.fetchUser(uid: uid)
            completion(.success(()))
        }
    }

    // MARK: - Signup

    func signup(
        name: String,
        email: String,
        password: String,
        age: Int?,
        gender: String?,
        skinColor: String?,
        allergies: [String]?,
        medicalConditions: [String]?,
        country: String?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                print("❌ Signup error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let uid = result?.user.uid else {
                completion(.failure(NSError(domain: "SignupError", code: -1, userInfo: [NSLocalizedDescriptionKey: "UID not found"])))
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
                medicalConditions: medicalConditions,
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
                case .failure(let error):
                    print("❌ Firestore save failed:", error.localizedDescription)
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Save to Firestore

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

    // MARK: - Fetch User

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

    // MARK: - Update User

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

    // MARK: - Delete Account

    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = auth.currentUser else {
            completion(.failure(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user signed in."])))
            return
        }

        let uid = user.uid

        db.collection("users").document(uid).delete { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }

            user.delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    DispatchQueue.main.async {
                        self?.currentUser = nil
                        self?.isAuthenticated = false
                        print("✅ Account deleted from Firebase Auth and Firestore")
                    }
                    completion(.success(()))
                }
            }
        }
    }

    // MARK: - Logout

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
