//
//  PermissonsRepositoryProtocol.swift
//  GriGriMVP
//
//  Created by Sam Quested on 22/08/2025.
//

import Foundation

protocol PermissionRepositoryProtocol {
    /// Get all permissions for a user
    func getPermissionsForUser(userId: String) async throws -> [GymPermission]
    
    /// Get all permissions for a gym
    func getPermissionsForGym(gymId: String) async throws -> [GymPermission]
    
    /// Get a specific permission for a user and gym
    func getPermission(userId: String, gymId: String) async throws -> GymPermission?
    
    /// Grant permission to a user for a gym
    func grantPermission(_ permission: GymPermission) async throws
    
    /// Revoke a permission
    func revokePermission(permissionId: String) async throws
    
    /// Update a permission (e.g., change role)
    func updatePermission(_ permission: GymPermission) async throws
    
    /// Batch fetch permissions for multiple gyms
    func getPermissionsForGyms(gymIds: [String], userId: String) async throws -> [GymPermission]
    
    /// Transfer ownership of a gym
    func transferOwnership(gymId: String, fromUserId: String, toUserId: String) async throws
    
    /// Get all users with permissions for a gym
    func getUsersWithPermissions(for gymId: String) async throws -> [(user: User, permission: GymPermission)]
    
    /// Check if user has any permission for a gym
    func hasPermission(userId: String, gymId: String) async throws -> Bool
    
    /// Get gyms where user has specific role
    func getGymsForUserWithRole(userId: String, role: GymRole) async throws -> [String]
}
