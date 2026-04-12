import SwiftUI
import Combine
import PhotosUI

@MainActor
final class OutlineViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var outlineImage: UIImage?
    @Published var uploadHistory: [UploadRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadSelectedImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
                outlineImage = nil
                errorMessage = nil
            } else {
                errorMessage = "Could not load the selected image."
            }
        } catch {
            errorMessage = "Failed to load image: \(error.localizedDescription)"
        }
    }

    func loadUploadHistory() async {
        do {
            let uploads = try await APIClient.shared.getUploads()
            uploadHistory = uploads.sorted { left, right in
                historySortKey(for: left) > historySortKey(for: right)
            }
        } catch {
            errorMessage = "Failed to load uploads: \(error.localizedDescription)"
        }
    }
    
    func generateOutline() async {
        guard let selectedImage else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await APIClient.shared.generateOutline(from: selectedImage)
            
            guard let url = URL(string: response.result_image_url) else {
                errorMessage = "The server returned an invalid image URL."
                isLoading = false
                return
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let image = UIImage(data: data) {
                outlineImage = image
                await loadUploadHistory()
            } else {
                errorMessage = "Could not load the generated outline image."
            }
        } catch {
            errorMessage = "Failed to generate outline: \(error.localizedDescription)"
        }
        
        isLoading = false
    }

    private func historySortKey(for record: UploadRecord) -> String {
        if let originalFilename = record.original_filename {
            return originalFilename.components(separatedBy: "_").first ?? record.image_id
        }

        return record.image_id
    }
}
