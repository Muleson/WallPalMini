//
//  LocalPermissionsRepository.swift
//  GriGriMVP
//
//  Created by Sam Quested on 22/08/2025.
//

import Foundation

class LocalGymPermissionRepository: PermissionRepositoryProtocol {
    private var permissions: [GymPermission] = []
    
    init() {
        // Initialize with sample permissions
        setupSamplePermissions()
    }
    
    private func setupSamplePermissions() {
        // Owner permissions
        permissions.append(GymPermission(
            id: "perm_1",
            userId: "user1",
            gymId: "gym1",
            role: .owner,
            grantedAt: Date(timeIntervalSinceNow: -86400 * 30),
            grantedBy: "user1"
        ))
        
        // Staff permissions
        permissions.append(GymPermission(
            id: "perm_2",
            userId: "user2",
            gymId: "gym1",
            role: .staff,
            grantedAt: Date(timeIntervalSinceNow: -86400 * 15),
            grantedBy: "user1"
        ))
        
        permissions.append(GymPermission(
            id: "perm_3",
            userId: "user3",
            gymId: "gym2",
            role: .owner,
            grantedAt: Date(timeIntervalSinceNow: -86400 * 60),
            grantedBy: "user3"
        ))
    }
    
    func getPermissionsForUser(userId: String) async throws -> [GymPermission] {
        return permissions.filter { $0.userId == userId && $0.isValid }
    }
    
    func getPermissionsForGym(gymId: String) async throws -> [GymPermission] {
        return permissions.filter { $0.gymId == gymId && $0.isValid }
    }
    
    func getPermission(userId: String, gymId: String) async throws -> GymPermission? {
        return permissions.first { $0.userId == userId && $0.gymId == gymId && $0.isValid }
    }
    
    func grantPermission(_ permission: GymPermission) async throws {
        if permissions.contains(where: { $0.userId == permission.userId && $0.gymId == permission.gymId }) {
            throw GymPermissionError.permissionAlreadyExists(userId: permission.userId, gymId: permission.gymId)
        }
        permissions.append(permission)
    }
    
    func revokePermission(permissionId: String) async throws {
        permissions.removeAll { $0.id == permissionId }
    }
    
    func updatePermission(_ permission: GymPermission) async throws {
        if let index = permissions.firstIndex(where: { $0.id == permission.id }) {
            permissions[index] = permission
        }
    }
    
    func getPermissionsForGyms(gymIds: [String], userId: String) async throws -> [GymPermission] {
        return permissions.filter { gymIds.contains($0.gymId) && $0.userId == userId && $0.isValid }
    }
    
    func transferOwnership(gymId: String, fromUserId: String, toUserId: String) async throws {
        // Find current owner permission
        guard let ownerIndex = permissions.firstIndex(where: {
            $0.userId == fromUserId && $0.gymId == gymId && $0.role == .owner
        }) else {
            throw GymPermissionError.notOwner
        }
        
        // Downgrade current owner to staff
        permissions[ownerIndex] = GymPermission(
            id: permissions[ownerIndex].id,
            userId: fromUserId,
            gymId: gymId,
            role: .staff,
            grantedAt: permissions[ownerIndex].grantedAt,
            grantedBy: permissions[ownerIndex].grantedBy,
            notes: "Previous owner"
        )
        
        // Create or update new owner permission
        if let existingIndex = permissions.firstIndex(where: { $0.userId == toUserId && $0.gymId == gymId }) {
            permissions[existingIndex] = GymPermission(
                id: permissions[existingIndex].id,
                userId: toUserId,
                gymId: gymId,
                role: .owner,
                grantedAt: Date(),
                grantedBy: fromUserId
            )
        } else {
            permissions.append(GymPermission(
                userId: toUserId,
                gymId: gymId,
                role: .owner,
                grantedBy: fromUserId
            ))
        }
    }
    
    func getUsersWithPermissions(for gymId: String) async throws -> [(user: User, permission: GymPermission)] {
        let gymPermissions = permissions.filter { $0.gymId == gymId && $0.isValid }
        return gymPermissions.compactMap { permission in
            if let user = SampleData.users.first(where: { $0.id == permission.userId }) {
                return (user, permission)
            }
            return nil
        }
    }
    
    func hasPermission(userId: String, gymId: String) async throws -> Bool {
        return permissions.contains { $0.userId == userId && $0.gymId == gymId && $0.isValid }
    }
    
    func getGymsForUserWithRole(userId: String, role: GymRole) async throws -> [String] {
        return permissions
            .filter { $0.userId == userId && $0.role == role && $0.isValid }
            .map { $0.gymId }
    }
}
