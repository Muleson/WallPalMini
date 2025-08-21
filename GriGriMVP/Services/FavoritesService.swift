//
//  FavoritesService.swift
//  GriGriMVP
//
//  Created by Sam Quested on 20/05/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class FavoritesService: ObservableObject {
    // Firestore reference
    private let db = Firestore.firestore()
    private let favoritesCollection = "userFavorites"
    
    // In-memory cache of favorite event IDs
    @Published private(set) var favoritedEventIds: Set<String> = []
    
    // Authentication state
    private var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    init() {
        // Load cached favorites if user is logged in
        if let userId = currentUserId {
            loadFavoritesFromCache(userId: userId)
            setupFavoritesListener(userId: userId)
        }
        
        // Listen for authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            if let userId = user?.uid {
                self?.loadFavoritesFromCache(userId: userId)
                self?.setupFavoritesListener(userId: userId)
            } else {
                // User signed out, clear favorites
                self?.favoritedEventIds = []
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadFavoritesFromCache(userId: String) {
        let userDefaultsKey = "favorites_\(userId)"
        if let cachedFavorites = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] {
            self.favoritedEventIds = Set(cachedFavorites)
        }
    }
    
    private func saveFavoritesToCache(userId: String, favorites: Set<String>) {
        let userDefaultsKey = "favorites_\(userId)"
        UserDefaults.standard.set(Array(favorites), forKey: userDefaultsKey)
    }
    
    private func setupFavoritesListener(userId: String) {
        // Real-time listener for favorites changes
        db.collection(favoritesCollection)
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening for favorite changes: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                var favoriteIds = Set<String>()
                for document in documents {
                    if let favorite = UserFavorite(firestoreData: document.data()),
                       favorite.userId == userId {
                        favoriteIds.insert(favorite.eventId)
                    }
                }
                
                self.favoritedEventIds = favoriteIds
                self.saveFavoritesToCache(userId: userId, favorites: favoriteIds)
            }
    }
    
    // MARK: - Public Methods
    
    /// Fetch all favorites for current user
    func fetchFavorites() async throws -> Set<String> {
        guard let userId = currentUserId else {
            throw AuthError.notAuthenticated
        }
        
        let snapshot = try await db.collection(favoritesCollection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        var favoriteIds = Set<String>()
        for document in snapshot.documents {
            if let favorite = UserFavorite(firestoreData: document.data()) {
                favoriteIds.insert(favorite.eventId)
            }
        }
        
        // Update the published property on the main thread
        await MainActor.run { [weak self] in
            guard let self = self else { return }
            self.favoritedEventIds = favoriteIds
        }
        
        // Update cache
        saveFavoritesToCache(userId: userId, favorites: favoriteIds)
        
        return favoriteIds
    }
    
    /// Toggle favorite status for an event
    @discardableResult
    func toggleFavorite(eventId: String) async throws -> Bool {
        guard let userId = currentUserId else {
            throw AuthError.notAuthenticated
        }
        
        // Check if event is already favorited
        let query = db.collection(favoritesCollection)
            .whereField("userId", isEqualTo: userId)
            .whereField("eventId", isEqualTo: eventId)
        
        let snapshot = try await query.getDocuments()
        
        // If favorite exists, delete it
        if let existingDoc = snapshot.documents.first {
            try await existingDoc.reference.delete()
            
            // Update local cache
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.favoritedEventIds.remove(eventId)
            }
            
            return false // Not favorited anymore
        }
        // Otherwise, add new favorite
        else {
            let favorite = UserFavorite(
                id: UUID().uuidString,
                userId: userId,
                eventId: eventId,
                dateAdded: Date()
            )
            
            try await db.collection(favoritesCollection).document(favorite.id)
                .setData(favorite.toFirestoreData())
            
            // Update local cache
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.favoritedEventIds.insert(eventId)
            }
            
            return true // Now favorited
        }
    }
    
    /// Check if an event is favorited by the current user
    func isEventFavorited(_ eventId: String) -> Bool {
        return favoritedEventIds.contains(eventId)
    }
    
    /// Get all favorite event IDs for the current user
    func getFavoritedEventIds() -> Set<String> {
        return favoritedEventIds
    }
}

// MARK: - Auth Error Enum
enum AuthError: Error {
    case notAuthenticated
    
    var localizedDescription: String {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        }
    }
}
