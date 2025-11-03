//
//  SampleDataInjector.swift
//  GriGriMVP
//
//  Created by Sam Quested on 14/10/2025.
//  TEMPORARY: Development tool for injecting sample data into Firestore
//

import SwiftUI
import FirebaseFirestore

struct SampleDataInjectorView: View {
    @State private var isInjecting = false
    @State private var injectionStatus = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Sample Data Injector")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("⚠️ Development Tool Only")
                    .foregroundColor(.orange)
                    .font(.headline)

                Divider()

                if isInjecting {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()

                    Text(injectionStatus)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This will inject:")
                            .font(.headline)

                        Group {
                            Text("• 5 Users")
                            Text("• 27 Media Items")
                            Text("• 3 Gym Companies")
                            Text("• 7 Gyms")
                            Text("• 40+ Events")
                        }
                        .font(.body)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                    Button(action: {
                        Task {
                            await injectSampleData()
                        }
                    }) {
                        Text("Inject Sample Data")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(isInjecting)

                    Button(action: {
                        Task {
                            await clearAllData()
                        }
                    }) {
                        Text("Clear All Data")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    .disabled(isInjecting)

                    Button(action: {
                        Task {
                            await testFirestoreConnection()
                        }
                    }) {
                        Text("Test Firestore Connection")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                    }
                    .disabled(isInjecting)
                }

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Data Injection", isPresented: $showAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Data Injection Methods

    private func injectSampleData() async {
        isInjecting = true
        let db = Firestore.firestore()

        print("DEBUG: Starting data injection")
        print("DEBUG: Firebase App Name: \(db.app.name)")

        var successCount = 0
        var totalCount = 0

        do {
            // 1. Inject Users
            injectionStatus = "Injecting users..."
            await MainActor.run { }  // Allow UI to update
            for user in SampleData.users {
                let userData = user.toFirestoreData()
                print("DEBUG: Injecting user \(user.id)")

                // Write with merge to avoid overwriting
                try await db.collection("users").document(user.id).setData(userData, merge: false)

                // Wait a moment for the write to propagate
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

                // Verify the write by reading it back
                let verifyDoc = try await db.collection("users").document(user.id).getDocument()
                if verifyDoc.exists {
                    print("DEBUG: ✅ User \(user.id) verified in Firestore")
                    successCount += 1
                } else {
                    print("DEBUG: ❌ User \(user.id) NOT found after write!")
                }
                totalCount += 1
            }

            // 2. Inject Media Items
            injectionStatus = "Injecting media items... (\(successCount) done)"
            await MainActor.run { }  // Allow UI to update
            for media in SampleData.mediaItems {
                let mediaData = media.toFirestoreData()
                print("DEBUG: Injecting media \(media.id)")
                try await db.collection("media").document(media.id).setData(mediaData)
                successCount += 1
                totalCount += 1
            }

            // 3. Inject Gym Companies
            injectionStatus = "Injecting gym companies... (\(successCount) done)"
            await MainActor.run { }  // Allow UI to update
            for company in SampleData.gymCompanies {
                let companyData = company.toFirestoreData()
                print("DEBUG: Injecting company \(company.id)")
                try await db.collection("gymCompanies").document(company.id).setData(companyData)
                successCount += 1
                totalCount += 1
            }

            // 4. Inject Gyms
            injectionStatus = "Injecting gyms... (\(successCount) done)"
            await MainActor.run { }  // Allow UI to update
            for gym in SampleData.gyms {
                let gymData = gym.toFirestoreData()
                print("DEBUG: Injecting gym \(gym.id) with data keys: \(gymData.keys.sorted())")
                try await db.collection("gyms").document(gym.id).setData(gymData)
                successCount += 1
                totalCount += 1
                print("DEBUG: Successfully injected gym \(gym.id)")
            }

            // 5. Inject Events
            injectionStatus = "Injecting events... (\(successCount) done)"
            await MainActor.run { }  // Allow UI to update
            for event in SampleData.events {
                let eventData = event.toFirestoreData()
                print("DEBUG: Injecting event \(event.id) with keys: \(eventData.keys.sorted())")
                try await db.collection("events").document(event.id).setData(eventData)
                successCount += 1
                totalCount += 1
                print("DEBUG: Successfully injected event \(event.id)")
            }

            injectionStatus = "Complete!"
            alertMessage = "Successfully injected \(successCount) items into Firestore!\n\nUsers: \(SampleData.users.count)\nMedia: \(SampleData.mediaItems.count)\nCompanies: \(SampleData.gymCompanies.count)\nGyms: \(SampleData.gyms.count)\nEvents: \(SampleData.events.count)"
            showAlert = true

        } catch {
            injectionStatus = "Error occurred"
            alertMessage = "Failed to inject data: \(error.localizedDescription)\n\nSuccessfully injected: \(successCount) items"
            print("DEBUG ERROR: \(error)")
            showAlert = true
        }

        isInjecting = false
    }

    private func clearAllData() async {
        isInjecting = true
        let db = Firestore.firestore()

        var successCount = 0

        do {
            // Clear Events
            injectionStatus = "Clearing events..."
            await MainActor.run { }
            for event in SampleData.events {
                print("DEBUG: Deleting event \(event.id)")
                try await db.collection("events").document(event.id).delete()
                successCount += 1
            }

            // Clear Gyms
            injectionStatus = "Clearing gyms... (\(successCount) done)"
            await MainActor.run { }
            for gym in SampleData.gyms {
                print("DEBUG: Deleting gym \(gym.id)")
                try await db.collection("gyms").document(gym.id).delete()
                successCount += 1
            }

            // Clear Gym Companies
            injectionStatus = "Clearing gym companies... (\(successCount) done)"
            await MainActor.run { }
            for company in SampleData.gymCompanies {
                print("DEBUG: Deleting company \(company.id)")
                try await db.collection("gymCompanies").document(company.id).delete()
                successCount += 1
            }

            // Clear Media Items
            injectionStatus = "Clearing media items... (\(successCount) done)"
            await MainActor.run { }
            for media in SampleData.mediaItems {
                print("DEBUG: Deleting media \(media.id)")
                try await db.collection("media").document(media.id).delete()
                successCount += 1
            }

            // Clear Users
            injectionStatus = "Clearing users... (\(successCount) done)"
            await MainActor.run { }
            for user in SampleData.users {
                print("DEBUG: Deleting user \(user.id)")
                try await db.collection("users").document(user.id).delete()
                successCount += 1
            }

            injectionStatus = "Complete!"
            alertMessage = "Successfully cleared \(successCount) items from Firestore!"
            showAlert = true

        } catch {
            injectionStatus = "Error occurred"
            alertMessage = "Failed to clear data: \(error.localizedDescription)\n\nSuccessfully cleared: \(successCount) items"
            print("DEBUG ERROR: \(error)")
            showAlert = true
        }

        isInjecting = false
    }

    // MARK: - Diagnostic Test
    private func testFirestoreConnection() async {
        isInjecting = true
        let db = Firestore.firestore()

        injectionStatus = "Testing Firestore connection..."
        await MainActor.run { }

        do {
            // Test 1: Write a test document
            let testData = ["test": "value", "timestamp": Timestamp(date: Date())] as [String : Any]
            let testDocRef = db.collection("_test").document("test_doc")

            print("DEBUG: Writing test document...")
            try await testDocRef.setData(testData)
            print("DEBUG: ✅ Write successful")

            // Test 2: Read it back
            print("DEBUG: Reading test document...")
            let snapshot = try await testDocRef.getDocument()
            if snapshot.exists {
                print("DEBUG: ✅ Read successful - Data: \(snapshot.data() ?? [:])")
            } else {
                print("DEBUG: ❌ Document doesn't exist after write")
            }

            // Test 3: Delete it
            print("DEBUG: Deleting test document...")
            try await testDocRef.delete()
            print("DEBUG: ✅ Delete successful")

            // Test 4: Verify deletion
            print("DEBUG: Verifying deletion...")
            let deletedSnapshot = try await testDocRef.getDocument()
            if !deletedSnapshot.exists {
                print("DEBUG: ✅ Deletion verified - document no longer exists")
            } else {
                print("DEBUG: ⚠️ Document still exists after delete!")
            }

            // Test 5: Check if we can read existing collections
            print("DEBUG: Checking existing collections...")
            let usersSnapshot = try await db.collection("users").limit(to: 1).getDocuments()
            print("DEBUG: Found \(usersSnapshot.documents.count) user documents")

            let gymsSnapshot = try await db.collection("gyms").limit(to: 1).getDocuments()
            print("DEBUG: Found \(gymsSnapshot.documents.count) gym documents")

            let eventsSnapshot = try await db.collection("events").limit(to: 1).getDocuments()
            print("DEBUG: Found \(eventsSnapshot.documents.count) event documents")

            injectionStatus = "Test complete!"
            alertMessage = "Firestore connection test passed! ✅\n\nCheck Xcode console for detailed results.\n\nFound:\n• Users: \(usersSnapshot.documents.count)\n• Gyms: \(gymsSnapshot.documents.count)\n• Events: \(eventsSnapshot.documents.count)"
            showAlert = true

        } catch {
            print("DEBUG: ❌ Test failed with error: \(error)")
            print("DEBUG: Error details: \(error.localizedDescription)")
            if let firestoreError = error as NSError? {
                print("DEBUG: Error code: \(firestoreError.code)")
                print("DEBUG: Error domain: \(firestoreError.domain)")
                print("DEBUG: Error userInfo: \(firestoreError.userInfo)")
            }

            injectionStatus = "Test failed"
            alertMessage = "Firestore test failed!\n\nError: \(error.localizedDescription)\n\nThis could be:\n• Security rules issue\n• Network connectivity\n• Firebase not initialized\n\nCheck Xcode console for details."
            showAlert = true
        }

        isInjecting = false
    }
}

#Preview {
    SampleDataInjectorView()
}
