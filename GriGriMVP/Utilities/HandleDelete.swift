//
//  HandleDelete.swift
//  GriGriMVP
//
//  Created by Sam Quested on 30/12/2024.
//

import Foundation

protocol DeletableItem: Identifiable{
    var deletionMessage: String { get }
    var requiresConfirmation: Bool { get }
}

enum DeletionState<T: DeletableItem> {
    case none
    case confirming(T)
}

protocol DeletionManager: ObservableObject {
    associatedtype Item: DeletableItem
    func delete(id: UUID, wasItemPrimary: Bool)
}

/* class GenericDeletionManager<T: DeletableItem>: DeletionManager {
    @Published var deletionState: DeletionState<T> = .none
    var deleteAction: (T) -> Void
    
    init(deleteAction: @escaping (T) -> Void) {
        self.deleteAction = deleteAction
    }
    
    func confirmDelete(item: T) {
        deletionState = .confirming(item)
    }
    
    func handleDelete() {
        if case let .confirming(item) = deletionState {
            delete(item)
            deletionState = .none
        }
    }
    
    func cancelDelete() {
        deletionState = .none
    }
    
    func delete(_ item: T) {
        deleteAction(item)
    }
} */
