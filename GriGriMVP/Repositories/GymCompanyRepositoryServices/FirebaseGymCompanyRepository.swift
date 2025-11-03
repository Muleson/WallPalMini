//
//  FirebaseGymCompanyRepository.swift
//  GriGriMVP
//
//  Created by Sam Quested on 09/10/2025.
//

import Foundation
import FirebaseFirestore

class FirebaseGymCompanyRepository: GymCompanyRepositoryProtocol {
    private let db = Firestore.firestore()
    private let companiesCollection = "gymCompanies"
    private let mediaRepository: MediaRepositoryProtocol

    init(mediaRepository: MediaRepositoryProtocol = RepositoryFactory.createMediaRepository()) {
        self.mediaRepository = mediaRepository
    }

    // MARK: - Fetch Methods

    func fetchAllCompanies() async throws -> [GymCompany] {
        let snapshot = try await db.collection(companiesCollection).getDocuments()
        return snapshot.documents.compactMap { document -> GymCompany? in
            var data = document.data()
            data["id"] = document.documentID
            return GymCompany(firestoreData: data)
        }
    }

    func searchCompanies(query: String) async throws -> [GymCompany] {
        let lowercaseQuery = query.lowercased()

        let nameQuery = db.collection(companiesCollection)
            .whereField("name", isGreaterThanOrEqualTo: lowercaseQuery)
            .whereField("name", isLessThanOrEqualTo: lowercaseQuery + "\u{f8ff}")
            .limit(to: 20)

        let snapshot = try await nameQuery.getDocuments()

        return snapshot.documents.compactMap { document -> GymCompany? in
            var data = document.data()
            data["id"] = document.documentID
            return GymCompany(firestoreData: data)
        }
    }

    func getCompany(id: String) async throws -> GymCompany? {
        do {
            let document = try await db.collection(companiesCollection).document(id).getDocument()

            guard let data = document.data() else {
                return nil // Document doesn't exist
            }

            // Add the ID to the data before decoding
            var companyData = data
            companyData["id"] = document.documentID

            // Use FirestoreCodable initializer
            let company = GymCompany(firestoreData: companyData)

            if company == nil {
                print("DEBUG: Failed to decode company with ID: \(id)")
                print("DEBUG: Document data keys: \(companyData.keys.sorted())")
            }

            return company
        } catch {
            print("DEBUG: Error in getCompany(\(id)): \(error.localizedDescription)")
            throw error
        }
    }

    func getCompanies(ids: [String]) async throws -> [GymCompany] {
        guard !ids.isEmpty else { return [] }

        var allCompanies: [GymCompany] = []

        // Firestore 'in' queries are limited to 10 items
        for chunk in ids.chunked(into: 10) {
            let snapshot = try await db.collection(companiesCollection)
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()

            let companies = snapshot.documents.compactMap { document -> GymCompany? in
                var data = document.data()
                data["id"] = document.documentID
                return GymCompany(firestoreData: data)
            }

            allCompanies.append(contentsOf: companies)
        }

        return allCompanies
    }

    func getCompanyForGym(gymId: String) async throws -> GymCompany? {
        let query = db.collection(companiesCollection)
            .whereField("gymIds", arrayContains: gymId)
            .limit(to: 1)

        let snapshot = try await query.getDocuments()

        guard let document = snapshot.documents.first else {
            return nil
        }

        var data = document.data()
        data["id"] = document.documentID
        return GymCompany(firestoreData: data)
    }

    // MARK: - Create Methods

    func createCompany(_ company: GymCompany) async throws -> GymCompany {
        // Convert company to Firestore data using FirestoreCodable
        let companyData = company.toFirestoreData()

        // Add to Firestore
        let documentRef = try await db.collection(companiesCollection).addDocument(data: companyData)

        // Create updated company with the generated ID
        var updatedCompanyData = companyData
        updatedCompanyData["id"] = documentRef.documentID

        guard let updatedCompany = GymCompany(firestoreData: updatedCompanyData) else {
            throw NSError(domain: "GymCompanyRepository", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create company with generated ID"
            ])
        }

        return updatedCompany
    }

    // MARK: - Update Methods

    func updateCompany(_ company: GymCompany) async throws -> GymCompany {
        let companyData = company.toFirestoreData()

        try await db.collection(companiesCollection).document(company.id).setData(companyData, merge: true)

        return company
    }

    func updateCompanyImage(companyId: String, image: UIImage) async throws -> URL {
        guard let company = try await getCompany(id: companyId) else {
            throw NSError(domain: "GymCompanyRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Company not found"
            ])
        }

        // Delete old image if exists
        if let oldImage = company.profileImage {
            try? await mediaRepository.deleteMedia(oldImage)
        }

        // Upload new image
        let mediaItem = try await mediaRepository.uploadImage(
            image,
            ownerId: "company_\(companyId)",
            compressionQuality: 0.8
        )

        // Update company with new MediaItem using FirestoreCodable
        try await db.collection(companiesCollection).document(companyId).updateData([
            "profileImage": mediaItem.toFirestoreData()
        ])

        return mediaItem.url
    }

    func addGymToCompany(gymId: String, companyId: String) async throws {
        try await db.collection(companiesCollection).document(companyId).updateData([
            "gymIds": FieldValue.arrayUnion([gymId])
        ])
    }

    func removeGymFromCompany(gymId: String, companyId: String) async throws {
        try await db.collection(companiesCollection).document(companyId).updateData([
            "gymIds": FieldValue.arrayRemove([gymId])
        ])
    }

    // MARK: - Delete Methods

    func deleteCompany(id: String) async throws {
        // Get company to check for image
        if let company = try await getCompany(id: id),
           let profileImage = company.profileImage {
            // Delete associated image
            try? await mediaRepository.deleteMedia(profileImage)
        }

        // Delete company document
        try await db.collection(companiesCollection).document(id).delete()
    }

    // MARK: - Sync Methods

    func syncGymsWithCompanies(_ gyms: [Gym], companies: [GymCompany]) -> [Gym] {
        return gyms.map { gym in
            var syncedGym = gym

            // Validate: does the claimed company actually include this gym?
            if let claimedCompanyId = gym.companyId {
                let companyClaimsGym = companies.first {
                    $0.id == claimedCompanyId && ($0.gymIds?.contains(gym.id) ?? false)
                } != nil

                if !companyClaimsGym {
                    syncedGym.companyId = nil // Remove invalid reference
                    print("⚠️ Removed invalid companyId '\(claimedCompanyId)' from gym '\(gym.name)' (ID: \(gym.id))")
                }
            }

            return syncedGym
        }
    }
}
