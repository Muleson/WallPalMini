//
//  SimplifiedDataInjector.swift
//  GriGriMVP
//
//  Created by Sam Quested on 14/10/2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import UIKit

struct SimplifiedDataInjectorView: View {
    @State private var isInjecting = false
    @State private var status = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Simplified Data Injector")
                    .font(.title)
                    .fontWeight(.bold)

                if isInjecting {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()

                    Text(status)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    VStack(spacing: 16) {
                        Text("Test Single Item")
                            .font(.headline)

                        HStack(spacing: 12) {
                            Button("Inject Test User") {
                                Task {
                                    await injectOneUser()
                                }
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Delete Test User") {
                                Task {
                                    await deleteTestUser()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }

                        Divider()

                        Text("Full Sample Data")
                            .font(.headline)

                        Button("Inject All Sample Data") {
                            Task {
                                await injectAllData()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)

                        Button("Delete All Sample Data") {
                            Task {
                                await deleteAllSampleData()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)

                        Divider()

                        Text("Local Data")
                            .font(.headline)

                        Button("Clear All Local/Cached Data") {
                            Task {
                                await clearAllLocalData()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)

                        Divider()

                        Text("Nuclear Options")
                            .font(.headline)
                            .foregroundColor(.red)

                        Button("Clear ENTIRE Database") {
                            Task {
                                await clearEntireDatabase()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)

                        Button("Clear Firebase Storage") {
                            Task {
                                await clearFirebaseStorage()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                }

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Result", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func injectOneUser() async {
        isInjecting = true
        status = "Injecting test user..."

        let db = Firestore.firestore()

        // Create a simple test user
        let testUser: [String: Any] = [
            "email": "test@example.com",
            "firstName": "Test",
            "lastName": "User",
            "createdAt": Timestamp(date: Date())
        ]

        do {
            print("\n=== STARTING TEST USER INJECTION ===")
            print("Firestore instance: \(db)")
            print("Data to inject: \(testUser)")

            // Method 1: Try setData
            print("Attempting setData...")
            try await db.collection("users").document("test_user_1").setData(testUser)
            print("✅ setData completed without throwing")

            // Wait a bit
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            // Verify
            print("Attempting to read back...")
            let doc = try await db.collection("users").document("test_user_1").getDocument()

            if doc.exists {
                print("✅ SUCCESS! Document exists with data: \(doc.data() ?? [:])")
                alertMessage = "✅ Success! User was created and verified in Firestore.\n\nData: \(doc.data() ?? [:])"
            } else {
                print("❌ FAILED! Document does not exist after write")
                alertMessage = "❌ Failed! Write succeeded but document doesn't exist. This suggests offline mode or caching issue."
            }

            print("=== TEST COMPLETE ===\n")
            showAlert = true

        } catch {
            print("❌ ERROR: \(error)")
            print("Error type: \(type(of: error))")
            print("Error localized: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("Error domain: \(nsError.domain)")
                print("Error code: \(nsError.code)")
                print("Error userInfo: \(nsError.userInfo)")
            }

            alertMessage = "❌ Error: \(error.localizedDescription)"
            showAlert = true
        }

        isInjecting = false
    }

    private func deleteTestUser() async {
        isInjecting = true
        status = "Deleting test user..."

        let db = Firestore.firestore()

        do {
            print("\n=== DELETING TEST USER ===")

            // First check if it exists
            let doc = try await db.collection("users").document("test_user_1").getDocument()
            if doc.exists {
                print("Document exists, deleting...")
                try await db.collection("users").document("test_user_1").delete()
                print("Delete call completed")

                // Wait and verify
                try await Task.sleep(nanoseconds: 500_000_000)
                let checkDoc = try await db.collection("users").document("test_user_1").getDocument()

                if !checkDoc.exists {
                    print("✅ Document successfully deleted")
                    alertMessage = "✅ User deleted successfully"
                } else {
                    print("❌ Document still exists after delete!")
                    alertMessage = "❌ Delete call succeeded but document still exists"
                }
            } else {
                print("Document doesn't exist")
                alertMessage = "Document doesn't exist"
            }

            print("=== DELETE COMPLETE ===\n")
            showAlert = true

        } catch {
            print("❌ ERROR: \(error)")
            alertMessage = "Error: \(error.localizedDescription)"
            showAlert = true
        }

        isInjecting = false
    }

    private func injectAllData() async {
        isInjecting = true
        status = "Injecting all sample data with auto-generated IDs..."

        let db = Firestore.firestore()
        var count = 0

        // Maps to track old IDs -> new auto-generated IDs
        var userIdMap: [String: String] = [:]
        var mediaIdMap: [String: String] = [:]
        var mediaUrlMap: [String: String] = [:] // Map old media ID -> new Firebase Storage URL
        var companyIdMap: [String: String] = [:]
        var gymIdMap: [String: String] = [:]

        do {
            print("\n=== INJECTING SAMPLE DATA WITH AUTO-GENERATED IDS ===")

            // 1. Inject Users first (no dependencies)
            status = "Injecting users..."
            await MainActor.run { }
            for user in SampleData.users {
                var userData = user.toFirestoreData()

                // Let Firestore generate the ID
                let docRef = try await db.collection("users").addDocument(data: userData)
                userIdMap[user.id] = docRef.documentID
                count += 1
                print("✅ User '\(user.firstName) \(user.lastName)': \(user.id) -> \(docRef.documentID)")
            }

            // 2. Inject Media Items with Firebase Storage URLs FIRST (so URLs are available for companies/gyms/events)
            status = "Uploading media to Firebase Storage... (\(count) done)"
            await MainActor.run { }

            for media in SampleData.mediaItems {
                var mediaData = media.toFirestoreData()
                var finalURL = media.url.absoluteString

                // Check if this is a local asset URL
                if media.url.scheme == "local-asset" {
                    // Extract asset name from URL
                    let assetName = media.url.host ?? media.url.lastPathComponent

                    // Upload to Firebase Storage and get real URL
                    if let uploadedURL = try? await uploadAssetToFirebaseStorage(assetName: assetName, mediaId: media.id) {
                        // Update the URL in mediaData to use Firebase Storage URL
                        finalURL = uploadedURL.absoluteString
                        mediaData["url"] = finalURL
                        print("  📤 Uploaded \(assetName) -> \(uploadedURL.absoluteString)")
                    } else {
                        print("  ⚠️ Failed to upload \(assetName), using placeholder")
                        // Use a placeholder image URL as fallback
                        finalURL = "https://via.placeholder.com/300x200.png?text=\(assetName)"
                        mediaData["url"] = finalURL
                    }
                }

                let docRef = try await db.collection("media").addDocument(data: mediaData)
                mediaIdMap[media.id] = docRef.documentID
                mediaUrlMap[media.id] = finalURL // Store the Firebase Storage URL
                count += 1
                print("✅ Media: \(media.id) -> \(docRef.documentID)")
            }

            // 3. Inject Gym Companies (may have profile images)
            status = "Injecting gym companies... (\(count) done)"
            await MainActor.run { }
            for company in SampleData.gymCompanies {
                var companyData = company.toFirestoreData()

                // Update profileImage reference with NEW media ID AND URL
                if var profileImageData = companyData["profileImage"] as? [String: Any] {
                    if let oldMediaId = profileImageData["id"] as? String {
                        // Update the ID
                        if let newMediaId = mediaIdMap[oldMediaId] {
                            profileImageData["id"] = newMediaId
                        }
                        // Update the URL to Firebase Storage URL
                        if let newURL = mediaUrlMap[oldMediaId] {
                            profileImageData["url"] = newURL
                            print("  📸 Updated company '\(company.name)' image URL")
                        }
                        companyData["profileImage"] = profileImageData
                    }
                }

                let docRef = try await db.collection("gymCompanies").addDocument(data: companyData)
                companyIdMap[company.id] = docRef.documentID
                count += 1
                print("✅ Company '\(company.name)': \(company.id) -> \(docRef.documentID)")
            }

            // 4. Inject Gyms (they reference companies and media)
            status = "Injecting gyms... (\(count) done)"
            await MainActor.run { }
            for gym in SampleData.gyms {
                var gymData = gym.toFirestoreData()

                // Update companyId reference
                if let oldCompanyId = gymData["companyId"] as? String,
                   let newCompanyId = companyIdMap[oldCompanyId] {
                    gymData["companyId"] = newCompanyId
                }

                // Update profileImage reference with NEW media ID AND URL
                if var profileImageData = gymData["profileImage"] as? [String: Any] {
                    if let oldMediaId = profileImageData["id"] as? String {
                        // Update the ID
                        if let newMediaId = mediaIdMap[oldMediaId] {
                            profileImageData["id"] = newMediaId
                        }
                        // Update the URL to Firebase Storage URL
                        if let newURL = mediaUrlMap[oldMediaId] {
                            profileImageData["url"] = newURL
                            print("  📸 Updated gym '\(gym.name)' image URL: \(oldMediaId) -> \(newURL)")
                        }
                        gymData["profileImage"] = profileImageData
                    }
                }

                let docRef = try await db.collection("gyms").addDocument(data: gymData)
                gymIdMap[gym.id] = docRef.documentID
                count += 1
                print("✅ Gym '\(gym.name)': \(gym.id) -> \(docRef.documentID)")
            }

            // 5. Inject Events (they reference users, gyms, and media)
            status = "Injecting events... (\(count) done)"
            await MainActor.run { }
            for event in SampleData.events {
                var eventData = event.toFirestoreData()

                // Update authorId reference
                if let oldAuthorId = eventData["authorId"] as? String,
                   let newAuthorId = userIdMap[oldAuthorId] {
                    eventData["authorId"] = newAuthorId
                }

                // Update hostId reference
                if let oldHostId = eventData["hostId"] as? String,
                   let newHostId = gymIdMap[oldHostId] {
                    eventData["hostId"] = newHostId
                }

                // Update mediaItems array with NEW media IDs AND URLs
                if var mediaItemsArray = eventData["mediaItems"] as? [[String: Any]] {
                    var updatedMediaItems: [[String: Any]] = []
                    for var mediaItemData in mediaItemsArray {
                        if let oldMediaId = mediaItemData["id"] as? String {
                            // Update the ID
                            if let newMediaId = mediaIdMap[oldMediaId] {
                                mediaItemData["id"] = newMediaId
                            }
                            // Update the URL to Firebase Storage URL
                            if let newURL = mediaUrlMap[oldMediaId] {
                                mediaItemData["url"] = newURL
                                print("  📸 Event '\(event.name)' media URL updated: \(oldMediaId) -> \(newURL)")
                            }
                            updatedMediaItems.append(mediaItemData)
                        } else {
                            updatedMediaItems.append(mediaItemData)
                        }
                    }
                    eventData["mediaItems"] = updatedMediaItems
                }

                let docRef = try await db.collection("events").addDocument(data: eventData)
                count += 1
                print("✅ Event '\(event.name)': \(event.id) -> \(docRef.documentID)")
            }

            print("\n=== INJECTION COMPLETE ===")
            print("ID Mappings:")
            print("Users: \(userIdMap)")
            print("Companies: \(companyIdMap)")
            print("Gyms: \(gymIdMap)")
            print("Media: \(mediaIdMap.count) items")
            print("Total items injected: \(count)")

            alertMessage = "✅ Injected \(count) items with auto-generated IDs!\n\nUsers: \(SampleData.users.count)\nCompanies: \(SampleData.gymCompanies.count)\nGyms: \(SampleData.gyms.count)\nMedia: \(SampleData.mediaItems.count)\nEvents: \(SampleData.events.count)"
            showAlert = true

        } catch {
            print("❌ ERROR: \(error)")
            alertMessage = "Error after \(count) items: \(error.localizedDescription)"
            showAlert = true
        }

        isInjecting = false
    }

    private func deleteAllSampleData() async {
        isInjecting = true
        status = "Deleting all sample data..."

        let db = Firestore.firestore()
        var deletedCount = 0

        do {
            print("\n=== DELETING ALL SAMPLE DATA ===")

            // Delete Events
            status = "Deleting events..."
            await MainActor.run { }
            for event in SampleData.events {
                try await db.collection("events").document(event.id).delete()
                deletedCount += 1
                print("Deleted event \(event.id)")
            }

            // Delete Gyms
            status = "Deleting gyms... (\(deletedCount) done)"
            await MainActor.run { }
            for gym in SampleData.gyms {
                try await db.collection("gyms").document(gym.id).delete()
                deletedCount += 1
                print("Deleted gym \(gym.id)")
            }

            // Delete Gym Companies
            status = "Deleting gym companies... (\(deletedCount) done)"
            await MainActor.run { }
            for company in SampleData.gymCompanies {
                try await db.collection("gymCompanies").document(company.id).delete()
                deletedCount += 1
                print("Deleted company \(company.id)")
            }

            // Delete Media
            status = "Deleting media items... (\(deletedCount) done)"
            await MainActor.run { }
            for media in SampleData.mediaItems {
                try await db.collection("media").document(media.id).delete()
                deletedCount += 1
                print("Deleted media \(media.id)")
            }

            // Delete Users
            status = "Deleting users... (\(deletedCount) done)"
            await MainActor.run { }
            for user in SampleData.users {
                try await db.collection("users").document(user.id).delete()
                deletedCount += 1
                print("Deleted user \(user.id)")
            }

            print("=== DELETION COMPLETE - \(deletedCount) items deleted ===\n")

            alertMessage = "✅ Deleted \(deletedCount) sample data items!\n\nUsers: \(SampleData.users.count)\nMedia: \(SampleData.mediaItems.count)\nCompanies: \(SampleData.gymCompanies.count)\nGyms: \(SampleData.gyms.count)\nEvents: \(SampleData.events.count)"
            showAlert = true

        } catch {
            print("❌ ERROR after deleting \(deletedCount) items: \(error)")
            alertMessage = "Error after deleting \(deletedCount) items: \(error.localizedDescription)"
            showAlert = true
        }

        isInjecting = false
    }

    private func clearEntireDatabase() async {
        isInjecting = true
        status = "⚠️ Clearing ENTIRE database..."

        let db = Firestore.firestore()
        var deletedCount = 0

        do {
            print("\n=== CLEARING ENTIRE DATABASE ===")

            let collections = ["events", "gyms", "gymCompanies", "media", "users"]

            for collectionName in collections {
                status = "Clearing \(collectionName)..."
                await MainActor.run { }

                print("Fetching all documents from \(collectionName)...")
                let snapshot = try await db.collection(collectionName).getDocuments()

                print("Found \(snapshot.documents.count) documents in \(collectionName)")

                for document in snapshot.documents {
                    try await document.reference.delete()
                    deletedCount += 1
                    print("Deleted \(collectionName)/\(document.documentID)")
                }
            }

            print("=== DATABASE CLEARED - \(deletedCount) total items deleted ===\n")

            alertMessage = "✅ Cleared entire database!\n\nDeleted \(deletedCount) documents total"
            showAlert = true

        } catch {
            print("❌ ERROR: \(error)")
            alertMessage = "Error: \(error.localizedDescription)\n\nDeleted \(deletedCount) items before error"
            showAlert = true
        }

        isInjecting = false
    }

    private func clearAllLocalData() async {
        isInjecting = true
        status = "Clearing all local/cached data..."

        do {
            print("\n=== CLEARING ALL LOCAL DATA ===")

            // 1. Clear all memory caches
            status = "Clearing memory caches..."
            await MainActor.run {
                CacheManager.shared.clearAllCaches()
                print("✅ Memory caches cleared")
            }

            // 2. Clear UserDefaults
            status = "Clearing UserDefaults..."
            await MainActor.run {
                if let bundleID = Bundle.main.bundleIdentifier {
                    UserDefaults.standard.removePersistentDomain(forName: bundleID)
                    UserDefaults.standard.synchronize()
                    print("✅ UserDefaults cleared")
                }
            }

            // 3. Clear URLCache
            status = "Clearing URL cache..."
            await MainActor.run {
                URLCache.shared.removeAllCachedResponses()
                print("✅ URL cache cleared")
            }

            // 4. Clear temporary files
            status = "Clearing temporary files..."
            let fileManager = FileManager.default
            let tmpDirectory = fileManager.temporaryDirectory

            if let tmpContents = try? fileManager.contentsOfDirectory(at: tmpDirectory, includingPropertiesForKeys: nil) {
                var deletedFiles = 0
                for fileURL in tmpContents {
                    try? fileManager.removeItem(at: fileURL)
                    deletedFiles += 1
                }
                print("✅ Temporary files cleared (\(deletedFiles) files)")
            }

            // 5. Clear app's cache directory
            status = "Clearing cache directory..."
            if let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
                if let cacheContents = try? fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil) {
                    var deletedFiles = 0
                    for fileURL in cacheContents {
                        try? fileManager.removeItem(at: fileURL)
                        deletedFiles += 1
                    }
                    print("✅ Cache directory cleared (\(deletedFiles) items)")
                }
            }

            // 6. Clear Firestore offline persistence cache (if enabled)
            status = "Clearing Firestore cache..."
            // Note: Firestore cache can only be cleared by disabling persistence before initialization
            // or by clearing the app data completely. We'll note this in the alert.
            print("⚠️ Firestore offline cache requires app restart to fully clear")

            print("=== LOCAL DATA CLEAR COMPLETE ===\n")

            alertMessage = """
            ✅ Local data cleared!

            Cleared:
            • Memory caches (Gyms, Events, Users, Search)
            • UserDefaults
            • URL cache
            • Temporary files
            • Cache directory

            ⚠️ Note: Firestore offline cache persists until app restart.
            Consider restarting the app for a complete clean slate.
            """
            showAlert = true

        } catch {
            print("❌ ERROR: \(error)")
            alertMessage = "Error clearing local data: \(error.localizedDescription)"
            showAlert = true
        }

        isInjecting = false
    }

    private func clearFirebaseStorage() async {
        isInjecting = true
        status = "Clearing Firebase Storage..."

        let storage = Storage.storage()
        var deletedCount = 0

        do {
            print("\n=== CLEARING FIREBASE STORAGE ===")

            // Clear the sample_data folder
            let storageRef = storage.reference().child("sample_data")

            status = "Listing files in Firebase Storage..."
            let listResult = try await storageRef.listAll()

            print("Found \(listResult.items.count) files to delete")

            for item in listResult.items {
                try await item.delete()
                deletedCount += 1
                print("🗑️ Deleted: \(item.fullPath)")
            }

            print("=== STORAGE CLEARED - \(deletedCount) files deleted ===\n")

            alertMessage = "✅ Cleared Firebase Storage!\n\nDeleted \(deletedCount) files from sample_data/"
            showAlert = true

        } catch {
            print("❌ ERROR: \(error)")
            alertMessage = "Error: \(error.localizedDescription)\n\nDeleted \(deletedCount) files before error"
            showAlert = true
        }

        isInjecting = false
    }

    // MARK: - Firebase Storage Upload Helper

    private func uploadAssetToFirebaseStorage(assetName: String, mediaId: String) async throws -> URL {
        let storage = Storage.storage()

        // Load the image from assets
        guard let image = UIImage(named: assetName),
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not load image \(assetName)"])
        }

        // Create a storage reference with a path
        let storageRef = storage.reference()
        let imagesRef = storageRef.child("sample_data/\(mediaId).jpg")

        print("  📤 Uploading \(assetName) (\(imageData.count / 1024)KB) to Firebase Storage...")

        // Upload the image
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await imagesRef.putDataAsync(imageData, metadata: metadata)

        // Get the download URL
        let downloadURL = try await imagesRef.downloadURL()

        print("  ✅ Upload complete: \(downloadURL.absoluteString)")
        return downloadURL
    }
}

#Preview {
    SimplifiedDataInjectorView()
}
