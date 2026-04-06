import SwiftUI
import PhotosUI

struct ContentView: View {
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
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reference")
                            .font(.headline)
                        
                        if let selectedImage = viewModel.selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            placeholderBox(text: "Inspiration Placeholder")
                        }
                    }
                    
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
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Outline Result")
                            .font(.headline)
                        
                        if let outlineImage = viewModel.outlineImage {
                            Image(uiImage: outlineImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            placeholderBox(text: "No outline generated yet")
                        }
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
        .task {
            await viewModel.loadUploadHistory()
        }
        .task(id: selectedItem) {
            await viewModel.loadSelectedImage(from: selectedItem)
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
                                UploadHistoryCard(record: record)
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
    
    @ViewBuilder
    private func placeholderBox(text: String) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.15))
            .frame(height: 300)
            .overlay(
                Text(text)
                    .foregroundColor(.secondary)
            )
    }
}

private struct UploadHistoryCard: View {
    let record: UploadRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                thumbnail(urlString: record.result_image_url)
                    .frame(height: 96)
                    .offset(x: 10, y: 8)
                    .zIndex(0)
                
                thumbnail(urlString: record.original_image_url)
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
            
            Text("Original on top")
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
    
    @ViewBuilder
    private func thumbnail(urlString: String) -> some View {
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
}

#Preview {
    ContentView()
}
