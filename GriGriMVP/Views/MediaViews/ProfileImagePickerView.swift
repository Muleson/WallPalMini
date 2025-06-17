import SwiftUI
import PhotosUI

// MARK: - Profile Image Picker with Circular Preview
struct ProfileImagePickerView: View {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    @State private var tempImage: UIImage?
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedItem: PhotosPickerItem?
    @State private var showSourceSelection = false
    
    let onImageConfirmed: ((UIImage) -> Void)?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Circular preview
                circularPreview
                
                // Source selection buttons
                sourceSelectionButtons
                
                Spacer()
                
                // Confirmation buttons
                confirmationButtons
            }
            .padding()
            .navigationTitle("Profile Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .background(AppTheme.appBackgroundBG)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(
                    selectedImage: $tempImage,
                    sourceType: sourceType,
                    allowsEditing: true,
                    onImageSelected: { image in
                        tempImage = image
                    }
                )
            }
            .confirmationDialog("Select Photo Source", isPresented: $showSourceSelection) {
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
            }
        }
        .onAppear {
            tempImage = selectedImage
        }
    }
    
    private var circularPreview: some View {
        VStack(spacing: 16) {
            // Large circular preview
            Group {
                if let image = tempImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 200)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(AppTheme.appPrimary, lineWidth: 3)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo.circle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                
                                Text("No Image Selected")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        )
                }
            }
            
            Text("Profile Image Preview")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var sourceSelectionButtons: some View {
        VStack(spacing: 16) {
            // Modern PhotosPicker for iOS 16+
            if #available(iOS 16.0, *) {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images
                ) {
                    Label("Select from Photos", systemImage: "photo.on.rectangle")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.appPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.appPrimary.opacity(0.1))
                        .cornerRadius(12)
                }
                .onChange(of: selectedItem) { newItem in
                    if let newItem = newItem {
                        Task {
                            await loadImageFromPhotoPicker(newItem)
                        }
                    }
                }
            }
            
            // Traditional picker options
            Button(action: {
                showSourceSelection = true
            }) {
                Label("Camera or Library", systemImage: "camera")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.appPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.appPrimary.opacity(0.1))
                    .cornerRadius(12)
            }
            
            if tempImage != nil {
                Button(action: {
                    tempImage = nil
                }) {
                    Label("Remove Image", systemImage: "trash")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
    }
    
    private var confirmationButtons: some View {
        HStack(spacing: 16) {
            Button("Cancel") {
                isPresented = false
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            Button("Confirm") {
                if let image = tempImage {
                    selectedImage = image
                    onImageConfirmed?(image)
                }
                isPresented = false
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(tempImage != nil ? AppTheme.appPrimary : Color.gray)
            .cornerRadius(12)
            .disabled(tempImage == nil)
        }
    }
    
    @available(iOS 16.0, *)
    private func loadImageFromPhotoPicker(_ item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    tempImage = image
                }
            }
        } catch {
            print("Error loading image from PhotosPicker: \(error)")
        }
    }
}

// MARK: - Circular Profile Image Button Component
struct ProfileImageSelectionButton: View {
    let selectedImage: UIImage?
    let isUploading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Group {
                if let profileImage = selectedImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 128, height: 128)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(AppTheme.appPrimary, lineWidth: 2)
                        )
                        .overlay(
                            // Edit indicator
                            Circle()
                                .fill(AppTheme.appPrimary)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "pencil")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 44, y: 44)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 128, height: 128)
                        .overlay(
                            VStack(spacing: 8) {
                                if isUploading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.appPrimary))
                                        .scaleEffect(1.2)
                                } else {
                                    Image(systemName: "photo.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(AppTheme.appPrimary)
                                    
                                    Text("Add Photo")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.appPrimary)
                                }
                            }
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    AppTheme.appPrimary,
                                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                                )
                        )
                }
            }
        }
        .disabled(isUploading)
    }
}

#Preview {
    ProfileImagePickerView(
        selectedImage: .constant(nil),
        isPresented: .constant(true),
        onImageConfirmed: { _ in }
    )
}