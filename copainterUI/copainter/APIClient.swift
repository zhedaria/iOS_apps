import Foundation
import UIKit

struct GenerateOutlineResponse: Decodable {
    let image_id: String
    let result_image_url: String
    let status: String
}

struct UploadRecord: Decodable {
    let image_id: String
    let original_image_url: String
    let result_image_url: String
    let status: String
    let created_at: String
    let original_filename: String?
    let result_filename: String?
}

enum APIError: Error {
    case invalidImageData
}

final class APIClient {
    static let shared = APIClient()
    
    private init() {}
    
    func generateOutline(from image: UIImage) async throws -> GenerateOutlineResponse {
        guard let url = URL(string: "http://127.0.0.1:8000/generate-outline") else {
            throw URLError(.badURL)
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw APIError.invalidImageData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let body = createMultipartBody(
            boundary: boundary,
            data: imageData,
            mimeType: "image/jpeg",
            filename: "upload.jpg",
            fieldName: "file"
        )
        
        print("Uploading to: \(url)")
        print("Image bytes: \(imageData.count)")
        
        let (data, response) = try await URLSession.shared.upload(for: request, from: body)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("Status code: \(httpResponse.statusCode)")
        print("Raw response: \(String(data: data, encoding: .utf8) ?? "nil")")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let responseText = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [
                NSLocalizedDescriptionKey: responseText
            ])
        }
        
        return try JSONDecoder().decode(GenerateOutlineResponse.self, from: data)
    }
    
    private func createMultipartBody(
        boundary: String,
        data: Data,
        mimeType: String,
        filename: String,
        fieldName: String
    ) -> Data {
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
    
    func getUploads() async throws -> [UploadRecord] {
        guard let url = URL(string: "http://127.0.0.1:8000/uploads") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        print("Fetching uploads from: \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("Status code: \(httpResponse.statusCode)")
        print("Raw response: \(String(data: data, encoding: .utf8) ?? "nil")")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let responseText = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [
                NSLocalizedDescriptionKey: responseText
            ])
        }
        
        return try JSONDecoder().decode([UploadRecord].self, from: data)
    }
}

// generate value map


