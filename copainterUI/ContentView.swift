import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var previewItem: PreviewItem?
    @State private var selectedItem: PhotosPickerItem?
    @StateObject private var viewModel = OutlineViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    historySection
                    
                    Text("Let's start painting")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Text("Upload Reference")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button {
                        Task {
                            await viewModel.generateOutline()
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Generate Outline")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(viewModel.selectedImage == nil ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(viewModel.selectedImage == nil || viewModel.isLoading)
                    
                    if viewModel.selectedImage != nil || viewModel.outlineImage != nil {
                        currentImagesSection
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                }
                .padding()
            }
            .navigationTitle("Copainter")
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: viewModel.selectedImage != nil)
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: viewModel.outlineImage != nil)
        .task {
            await viewModel.loadUploadHistory()
        }
        .task(id: selectedItem) {
            await viewModel.loadSelectedImage(from: selectedItem)
        }
        .fullScreenCover(item: $previewItem) { item in
            FullScreenImageView(item: item)
        }
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("History")
                    .font(.title3.weight(.semibold))
                
                Spacer()
                
                if !viewModel.uploadHistory.isEmpty {
                    Text("\(viewModel.uploadHistory.count)")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
            
            if viewModel.uploadHistory.isEmpty {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 120)
                    .overlay(
                        VStack(spacing: 6) {
                            Image(systemName: "square.stack.3d.up")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            
                            Text("Generated outlines will appear here")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    )
            } else {
                GeometryReader { geometry in
                    let cardWidth = max((geometry.size.width - 12) / 2, 0)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.uploadHistory, id: \.image_id) { record in
                                UploadHistoryCard(
                                    record: record,
                                    onSelectOriginal: {
                                        previewItem = PreviewItem(
                                            title: "Original Reference",
                                            imageURL: record.original_image_url
                                        )
                                    },
                                    onSelectResult: {
                                        previewItem = PreviewItem(
                                            title: "Generated Outline",
                                            imageURL: record.result_image_url
                                        )
                                    }
                                )
                                .frame(width: cardWidth)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, max((geometry.size.width - (cardWidth * 2) - 12) / 2, 0))
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .contentMargins(.horizontal, 0, for: .scrollContent)
                }
                .frame(height: 190)
            }
        }
    }
    
    private var currentImagesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Current Images")
                .font(.title3.weight(.semibold))
            
            HStack(alignment: .top, spacing: 14) {
                if let selectedImage = viewModel.selectedImage {
                    currentImageThumbnail(
                        title: "Reference",
                        image: selectedImage
                    )
                }
                
                if let outlineImage = viewModel.outlineImage {
                    currentImageThumbnail(
                        title: "Outline",
                        image: outlineImage
                    )
                }
            }
        }
    }
    
    private func currentImageThumbnail(title: String, image: UIImage) -> some View {
        Button {
            previewItem = PreviewItem(title: title, image: image)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct UploadHistoryCard: View {
    let record: UploadRecord
    let onSelectOriginal: () -> Void
    let onSelectResult: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                thumbnailButton(
                    urlString: record.result_image_url,
                    action: onSelectResult
                )
                .frame(height: 96)
                .offset(x: 10, y: 8)
                .zIndex(0)
                
                thumbnailButton(
                    urlString: record.original_image_url,
                    action: onSelectOriginal
                )
                .frame(height: 96)
                .zIndex(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.trailing, 10)
            .padding(.bottom, 8)
            
            Text(shortIdentifier)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Text(lastUpdatedText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }
    
    private var shortIdentifier: String {
        record.original_filename?
            .components(separatedBy: "_")
            .first?
            .prefix(8)
            .lowercased() ?? String(record.image_id.prefix(8)).lowercased()
    }
    
    private var lastUpdatedText: String {
        guard let date = ISO8601DateFormatter().date(from: record.created_at) else {
            return "Updated recently"
        }
        
        return "Updated \(date.formatted(.relative(presentation: .named)))"
    }
    
    @ViewBuilder
    private func thumbnailButton(urlString: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            AsyncImage(url: URL(string: urlString)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        )
                case .empty:
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                        .overlay(ProgressView())
                @unknown default:
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.85), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

private struct PreviewItem: Identifiable {
    let id = UUID()
    let title: String
    let image: UIImage?
    let imageURL: String?
    
    init(title: String, image: UIImage) {
        self.title = title
        self.image = image
        self.imageURL = nil
    }
    
    init(title: String, imageURL: String) {
        self.title = title
        self.image = nil
        self.imageURL = imageURL
    }
}

private struct FullScreenImageView: View {
    @Environment(\.dismiss) private var dismiss
    
    let item: PreviewItem
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let image = item.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                } else if let imageURL = item.imageURL {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .padding()
                        case .failure:
                            ContentUnavailableView(
                                "Image Unavailable",
                                systemImage: "photo",
                                description: Text("The full-size image could not be loaded.")
                            )
                            .foregroundStyle(.white, .white.opacity(0.7))
                        case .empty:
                            ProgressView()
                                .tint(.white)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .tint(.white)
                }
                
                ToolbarItem(placement: .principal) {
                    Text(item.title)
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
