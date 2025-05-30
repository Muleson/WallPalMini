//
//  ImagePickerView.swift
//  GriGriMVP
//
//  Created by Sam Quested on 27/05/2025.
//

import SwiftUI
import PhotosUI

// MARK: - Modern Photo Picker (iOS 16+)
struct ModernPhotosPicker: View {
    @Binding var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    let onImageSelected: ((UIImage) -> Void)?
    
    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images
        ) {
            Label("Select Photo", systemImage: "photo")
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let newItem = newItem {
                    await loadImage(from: newItem)
                }
            }
        }
    }
    
    private func loadImage(from item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                    onImageSelected?(image)
                }
            }
        } catch {
            print("Error loading image: \(error)")
        }
    }
}

// MARK: - Legacy Image Picker (for backwards compatibility)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var allowsEditing: Bool = false
    var onImageSelected: ((UIImage) -> Void)?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.allowsEditing = allowsEditing
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[parent.allowsEditing ? .editedImage : .originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImageSelected?(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Camera/Photo Selection Sheet
struct MediaSelectionSheet: View {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    let onImageSelected: ((UIImage) -> Void)?
    
    var body: some View {
        EmptyView()
            .confirmationDialog("Select Photo", isPresented: $isPresented) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Take Photo") {
                        sourceType = .camera
                        showImagePicker = true
                    }
                }
                
                Button("Choose from Library") {
                    sourceType = .photoLibrary
                    showImagePicker = true
                }
                
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Select a photo source")
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(
                    selectedImage: $selectedImage,
                    sourceType: sourceType,
                    onImageSelected: onImageSelected
                )
            }
    }
}

// MARK: - Image Upload View Component
struct ImageUploadView: View {
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var showImagePicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    let mediaRepository: MediaRepositoryProtocol
    let ownerId: String
    let onUploadComplete: ((MediaItem) -> Void)?
    
    init(
        mediaRepository: MediaRepositoryProtocol = FirebaseMediaRepository(),
        ownerId: String,
        onUploadComplete: ((MediaItem) -> Void)? = nil
    ) {
        self.mediaRepository = mediaRepository
        self.ownerId = ownerId
        self.onUploadComplete = onUploadComplete
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Image preview or placeholder
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No image selected")
                                .foregroundColor(.gray)
                        }
                    )
            }
            
            // Buttons
            HStack(spacing: 16) {
                if #available(iOS 16.0, *) {
                    ModernPhotosPicker(
                        selectedImage: $selectedImage,
                        onImageSelected: nil
                    )
                    .buttonStyle(.bordered)
                } else {
                    Button("Select Photo") {
                        showImagePicker = true
                    }
                    .buttonStyle(.bordered)
                }
                
                if selectedImage != nil {
                    Button(action: uploadImage) {
                        if isUploading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Label("Upload", systemImage: "icloud.and.arrow.up")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isUploading)
                }
            }
            
            // Upload progress
            if isUploading {
                VStack(spacing: 8) {
                    ProgressView(value: uploadProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text("Uploading... \(Int(uploadProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(
                selectedImage: $selectedImage,
                sourceType: .photoLibrary
            )
        }
        .alert("Upload Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func uploadImage() {
        guard let image = selectedImage else { return }
        
        isUploading = true
        uploadProgress = 0
        
        Task {
            do {
                // Simulate progress (in real implementation, use Storage upload progress)
                for i in 1...10 {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    await MainActor.run {
                        uploadProgress = Double(i) / 10.0
                    }
                }
                
                let mediaItem = try await mediaRepository.uploadImage(
                    image,
                    ownerId: ownerId,
                    compressionQuality: 0.8
                )
                
                await MainActor.run {
                    isUploading = false
                    selectedImage = nil
                    uploadProgress = 0
                    onUploadComplete?(mediaItem)
                }
            } catch {
                await MainActor.run {
                    isUploading = false
                    uploadProgress = 0
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}
