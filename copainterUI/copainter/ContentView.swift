import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @StateObject private var viewModel = OutlineViewModel()
    @State private var selectedGuide: GuideType = .outline
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    historySection
                    workspaceSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Copainter")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await viewModel.loadUploadHistory()
        }
        .task(id: selectedItem) {
            await viewModel.loadSelectedImage(from: selectedItem)
        }
    }
    
    private var workspaceSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader(
                eyebrow: "Workspace",
                title: "Current Project",
                subtitle: "Upload a reference and generate painting guides"
            )
            
            card {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Reference")
                        .font(.headline)
                    
                    if let selectedImage = viewModel.selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 220, maxHeight: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    } else {
                        placeholderBox(
                            text: "Upload a reference image to start a new project",
                            systemImage: "photo.on.rectangle"
                        )
                    }
                    
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Upload Reference", systemImage: "arrow.up.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .blue))
                }
            }
            
            card {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Generated Guides")
                                .font(.headline)
                            Text("Switch between outputs for this project.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Picker("Guide Type", selection: $selectedGuide) {
                        ForEach(GuideType.allCases, id: \.self) { guide in
                            Text(guide.title).tag(guide)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    guideContent
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                    
                    Button {
                        Task {
                            await viewModel.generateOutline()
                            selectedGuide = .outline
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        } else {
                            Label("Generate Guides", systemImage: "sparkles")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .green))
                    .disabled(viewModel.selectedImage == nil || viewModel.isLoading)
                }
            }
        }
    }
    
    private var guideContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selectedGuide.displayTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            
            switch selectedGuide {
            case .outline:
                if let outlineImage = viewModel.outlineImage {
                    Image(uiImage: outlineImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 220, maxHeight: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    placeholderBox(
                        text: "Your outline will appear here",
                        systemImage: "scribble.variable"
                    )
                }
                
            case .valueMap:
                placeholderBox(
                    text: "Value map coming next",
                    systemImage: "circle.lefthalf.filled"
                )
                
            case .colorMap:
                placeholderBox(
                    text: "Colour map coming next",
                    systemImage: "paintpalette"
                )
            }
        }
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recent Projects")
                        .font(.title3.weight(.semibold))
                    Text("Your previous uploads and generated studies")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
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
                card {
                    VStack(spacing: 8) {
                        Image(systemName: "square.stack.3d.up")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        
                        Text("No projects yet")
                            .font(.subheadline.weight(.semibold))
                        
                        Text("Generated projects will appear here.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 26)
                }
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
                        .padding(.horizontal, max((geometry.size.width - (cardWidth * 2) - 12) / 2, 0))
                        .padding(.vertical, 8)
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .contentMargins(.horizontal, 0, for: .scrollContent)
                }
                .frame(height: 214)
            }
        }
    }
    
    private func sectionHeader(eyebrow: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.title2.weight(.bold))
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 14, y: 6)
    }
    
    @ViewBuilder
    private func placeholderBox(text: String, systemImage: String) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(.secondarySystemBackground))
            .frame(minHeight: 220, maxHeight: 320)
            .overlay(
                VStack(spacing: 10) {
                    Image(systemName: systemImage)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    
                    Text(text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            )
    }
}

private enum GuideType: CaseIterable {
    case outline
    case valueMap
    case colorMap
    
    var title: String {
        switch self {
        case .outline: return "Outline"
        case .valueMap: return "Value"
        case .colorMap: return "Colour"
        }
    }
    
    var displayTitle: String {
        switch self {
        case .outline: return "Outline Result"
        case .valueMap: return "Value Map"
        case .colorMap: return "Colour Map"
        }
    }
}

private struct UploadHistoryCard: View {
    let record: UploadRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                thumbnail(urlString: record.result_image_url)
                    .frame(width: 132, height: 102)
                    .offset(x: 10, y: 10)
                    .zIndex(0)
                
                thumbnail(urlString: record.original_image_url)
                    .frame(width: 132, height: 102)
                    .zIndex(1)
            }
            .frame(height: 118)
            .frame(maxWidth: .infinity)
            .clipped()
            .padding(.bottom, 4)
            .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(shortIdentifier)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 5)
    }
    
    private var shortIdentifier: String {
        record.original_filename?
            .components(separatedBy: "_")
            .first?
            .prefix(8)
            .lowercased() ?? String(record.image_id.prefix(8)).lowercased()
    }
    
    private var formattedDate: String {
        let createdAt = record.created_at
        
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: createdAt) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
        
        return createdAt
    }
    
    @ViewBuilder
    private func thumbnail(urlString: String) -> some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .clipped()
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
                .stroke(Color.white.opacity(0.88), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 10, y: 5)
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color.opacity(configuration.isPressed ? 0.85 : 1))
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
