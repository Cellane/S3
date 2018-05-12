//
//  S3.swift
//  S3
//
//  Created by Ondrej Rafaj on 01/12/2016.
//  Copyright © 2016 manGoweb UK Ltd. All rights reserved.
//

import Foundation
import Vapor
import HTTP
@_exported import S3Signer


/// Main S3 class
public class S3: S3Client {
    
    /// Error messages
    public enum Error: Swift.Error {
        case invalidUrl
        case errorResponse(HTTPResponseStatus, ErrorMessage)
        case badResponse(Response)
        case badStringData
        case missingData
        case notFound
        case s3NotRegistered
    }
    
    /// If set, this bucket name value will be used globally unless overriden by a specific call
    public internal(set) var defaultBucket: String
    
    
    // MARK: Initialization
    
    /// Basic initialization method, also registers S3Signer and self with services
    @discardableResult public convenience init(defaultBucket: String, config: S3Signer.Config, services: inout Services) throws {
        try self.init(defaultBucket: defaultBucket)
        
        try services.register(S3Signer(config))
        services.register(self, as: S3Client.self)
    }
    
    /// Basic initialization method
    public init(defaultBucket: String) throws {
        self.defaultBucket = defaultBucket
    }
    
}

// MARK: - Helper methods

extension S3 {
    
    /// Check response for error
    @discardableResult func check(_ response: Response) throws -> Response {
        guard response.http.status == .ok || response.http.status == .noContent else {
            if let error = try? response.decode(to: ErrorMessage.self) {
                throw Error.errorResponse(response.http.status, error)
            } else {
                throw Error.badResponse(response)
            }
        }
        return response
    }
    
    /// Get mime type for file
    static func mimeType(forFileAtUrl url: URL) -> String {
        guard let mediaType = MediaType.fileExtension(url.pathExtension) else {
            return MediaType(type: "application", subType: "octet-stream").description
        }
        return mediaType.description
    }
    
    /// Get mime type for file
    func mimeType(forFileAtUrl url: URL) -> String {
        return S3.mimeType(forFileAtUrl: url)
    }
    
    /// Base URL for S3 region
    func url(region: Region? = nil, bucket: String? = nil, on container: Container) throws -> URL {
        let signer = try container.makeS3Signer()
        let urlString = (region ?? signer.config.region).hostUrlString + (bucket?.finished(with: "/") ?? "")
        guard let url = URL(string: urlString) else {
            throw Error.invalidUrl
        }
        return url
    }
    
    /// Base URL for a file in a bucket
    func url(file: LocationConvertible, on container: Container) throws -> URL {
        let signer = try container.makeS3Signer()
        let bucket = file.bucket ?? defaultBucket
        guard let url = URL(string: signer.config.region.hostUrlString + bucket.finished(with: "/") + file.path) else {
            throw Error.invalidUrl
        }
        return url
    }
    
}
