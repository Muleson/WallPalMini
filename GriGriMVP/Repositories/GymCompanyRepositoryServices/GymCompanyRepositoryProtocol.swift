//
//  GymCompanyRepositoryProtocol.swift
//  GriGriMVP
//
//  Created by Sam Quested on 09/10/2025.
//

import Foundation
import UIKit

protocol GymCompanyRepositoryProtocol {
    /// Fetch all gym companies
    func fetchAllCompanies() async throws -> [GymCompany]

    /// Search for gym companies by name
    func searchCompanies(query: String) async throws -> [GymCompany]

    /// Get a specific gym company by ID
    func getCompany(id: String) async throws -> GymCompany?

    /// Get multiple gym companies by IDs
    func getCompanies(ids: [String]) async throws -> [GymCompany]

    /// Get company for a specific gym
    func getCompanyForGym(gymId: String) async throws -> GymCompany?

    /// Create a new gym company
    func createCompany(_ company: GymCompany) async throws -> GymCompany

    /// Update an existing gym company
    func updateCompany(_ company: GymCompany) async throws -> GymCompany

    /// Update gym company profile image
    func updateCompanyImage(companyId: String, image: UIImage) async throws -> URL

    /// Delete a gym company
    func deleteCompany(id: String) async throws

    /// Add gym to company
    func addGymToCompany(gymId: String, companyId: String) async throws

    /// Remove gym from company
    func removeGymFromCompany(gymId: String, companyId: String) async throws

    /// Sync gyms with company relationships - validates that gym.companyId matches company.gymIds
    func syncGymsWithCompanies(_ gyms: [Gym], companies: [GymCompany]) -> [Gym]
}
