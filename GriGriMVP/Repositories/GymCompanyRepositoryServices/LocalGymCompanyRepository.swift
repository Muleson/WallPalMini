//
//  LocalGymCompanyRepository.swift
//  GriGriMVP
//
//  Created by Sam Quested on 09/10/2025.
//

import Foundation
import UIKit

class LocalGymCompanyRepository: GymCompanyRepositoryProtocol {
    private var companies = SampleData.gymCompanies

    func fetchAllCompanies() async throws -> [GymCompany] {
        return companies
    }

    func searchCompanies(query: String) async throws -> [GymCompany] {
        return companies.filter { company in
            company.name.localizedCaseInsensitiveContains(query) ||
            company.description?.localizedCaseInsensitiveContains(query) == true
        }
    }

    func getCompany(id: String) async throws -> GymCompany? {
        return companies.first { $0.id == id }
    }

    func getCompanies(ids: [String]) async throws -> [GymCompany] {
        return companies.filter { ids.contains($0.id) }
    }

    func getCompanyForGym(gymId: String) async throws -> GymCompany? {
        return companies.first { company in
            company.gymIds?.contains(gymId) ?? false
        }
    }

    func createCompany(_ company: GymCompany) async throws -> GymCompany {
        companies.append(company)
        return company
    }

    func updateCompany(_ company: GymCompany) async throws -> GymCompany {
        if let index = companies.firstIndex(where: { $0.id == company.id }) {
            companies[index] = company
        }
        return company
    }

    func updateCompanyImage(companyId: String, image: UIImage) async throws -> URL {
        // Return sample URL for local testing
        return URL(string: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4")!
    }

    func deleteCompany(id: String) async throws {
        companies.removeAll { $0.id == id }
    }

    func addGymToCompany(gymId: String, companyId: String) async throws {
        if let index = companies.firstIndex(where: { $0.id == companyId }) {
            var company = companies[index]
            if company.gymIds == nil {
                company.gymIds = [gymId]
            } else if !company.gymIds!.contains(gymId) {
                company.gymIds!.append(gymId)
            }
            companies[index] = company
        }
    }

    func removeGymFromCompany(gymId: String, companyId: String) async throws {
        if let index = companies.firstIndex(where: { $0.id == companyId }) {
            var company = companies[index]
            company.gymIds?.removeAll { $0 == gymId }
            companies[index] = company
        }
    }

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
