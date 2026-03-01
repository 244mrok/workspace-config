import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

// MARK: - Protocol

protocol FirebaseServiceProtocol {
    // Auth
    var currentUserId: String? { get }
    var isAuthenticated: Bool { get }
    func signUp(email: String, password: String) async throws
    func signIn(email: String, password: String) async throws
    func signOut() throws

    // Measurements
    func addMeasurement(_ measurement: BodyMeasurement) async throws
    func fetchMeasurements(limit: Int) async throws -> [BodyMeasurement]
    func updateMeasurement(_ measurement: BodyMeasurement) async throws
    func deleteMeasurement(id: String) async throws

    // UserProfile
    func createUserProfile(_ profile: UserProfile) async throws
    func fetchUserProfile() async throws -> UserProfile?

    // Goals
    func addGoal(_ goal: Goal) async throws
    func fetchActiveGoals() async throws -> [Goal]
}

// MARK: - Implementation

@Observable
final class FirebaseService: FirebaseServiceProtocol {
    private(set) var currentUserId: String?
    private var authStateListener: AuthStateDidChangeListenerHandle?

    private var isFirebaseConfigured: Bool {
        FirebaseApp.app() != nil
    }

    // Not tracked by @Observable — use @ObservationIgnored
    @ObservationIgnored
    private var _db: Firestore?
    private var db: Firestore {
        if _db == nil { _db = Firestore.firestore() }
        return _db!
    }

    var isAuthenticated: Bool {
        currentUserId != nil
    }

    init() {
        if isFirebaseConfigured {
            setupAuthStateListener()
        }
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Auth State

    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUserId = user?.uid
            }
        }
    }

    // MARK: - Auth

    func signUp(email: String, password: String) async throws {
        guard isFirebaseConfigured else { throw FirebaseServiceError.notConfigured }
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        currentUserId = result.user.uid

        let profile = UserProfile(email: email, displayName: email.components(separatedBy: "@").first ?? email)
        try await createUserProfile(profile)
    }

    func signIn(email: String, password: String) async throws {
        guard isFirebaseConfigured else { throw FirebaseServiceError.notConfigured }
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        currentUserId = result.user.uid
    }

    func signOut() throws {
        guard isFirebaseConfigured else { throw FirebaseServiceError.notConfigured }
        try Auth.auth().signOut()
        currentUserId = nil
    }

    // MARK: - Private Helpers

    private func userDocument() throws -> DocumentReference {
        guard let userId = currentUserId else {
            throw FirebaseServiceError.notAuthenticated
        }
        return db.collection("users").document(userId)
    }

    private func measurementsCollection() throws -> CollectionReference {
        try userDocument().collection("measurements")
    }

    private func goalsCollection() throws -> CollectionReference {
        try userDocument().collection("goals")
    }

    // MARK: - Measurements

    func addMeasurement(_ measurement: BodyMeasurement) async throws {
        let collection = try measurementsCollection()
        try collection.addDocument(from: measurement)
    }

    func fetchMeasurements(limit: Int = 50) async throws -> [BodyMeasurement] {
        let collection = try measurementsCollection()
        let snapshot = try await collection
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            try? doc.data(as: BodyMeasurement.self)
        }
    }

    func updateMeasurement(_ measurement: BodyMeasurement) async throws {
        guard let id = measurement.id else {
            throw FirebaseServiceError.missingId
        }
        let collection = try measurementsCollection()
        try collection.document(id).setData(from: measurement)
    }

    func deleteMeasurement(id: String) async throws {
        let collection = try measurementsCollection()
        try await collection.document(id).delete()
    }

    func listenToMeasurements(limit: Int = 50, onChange: @escaping ([BodyMeasurement]) -> Void) -> ListenerRegistration? {
        guard let collection = try? measurementsCollection() else { return nil }

        return collection
            .order(by: "date", descending: true)
            .limit(to: limit)
            .addSnapshotListener { snapshot, _ in
                guard let snapshot else { return }
                let measurements = snapshot.documents.compactMap { doc in
                    try? doc.data(as: BodyMeasurement.self)
                }
                DispatchQueue.main.async {
                    onChange(measurements)
                }
            }
    }

    // MARK: - UserProfile

    func createUserProfile(_ profile: UserProfile) async throws {
        let doc = try userDocument()
        try doc.collection("profile").document("main").setData(from: profile)
    }

    func fetchUserProfile() async throws -> UserProfile? {
        let doc = try userDocument()
        let snapshot = try await doc.collection("profile").document("main").getDocument()
        return try? snapshot.data(as: UserProfile.self)
    }

    // MARK: - Goals

    func addGoal(_ goal: Goal) async throws {
        let collection = try goalsCollection()
        try collection.addDocument(from: goal)
    }

    func fetchActiveGoals() async throws -> [Goal] {
        let collection = try goalsCollection()
        let snapshot = try await collection
            .whereField("isActive", isEqualTo: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Goal.self)
        }
    }
}

// MARK: - Errors

enum FirebaseServiceError: LocalizedError {
    case notAuthenticated
    case notConfigured
    case missingId

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "ログインが必要です"
        case .notConfigured:
            return "Firebaseが初期化されていません"
        case .missingId:
            return "ドキュメントIDが見つかりません"
        }
    }
}
