//
//  ShipSwiftAPIService.swift
//  ShipSwift
//
//  API client for ShipSwift server endpoints.
//  Handles App Store purchase verification and API key management.
//
//  Created by ShipSwift on 2/27/26.
//

import Foundation

struct ShipSwiftAPIService {
    private let baseURL = "https://api.shipswift.app"

    // MARK: - Response Types

    struct VerifyResponse: Decodable {
        let apiKey: String
        let message: String
        let isExisting: Bool
    }

    struct KeyStatusResponse: Decodable {
        let hasKey: Bool
        let plan: String?
        let status: String?
        let apiKey: String?
        let email: String?
        let purchasedAt: String?
        let lastUsedAt: String?
    }

    struct RevealResponse: Decodable {
        let apiKey: String
    }

    // MARK: - App Store Purchase Verification

    /// Verify an App Store purchase and get an API key
    func verifyAppStorePurchase(idToken: String, signedTransactionInfo: String) async throws -> VerifyResponse {
        let url = URL(string: "\(baseURL)/api/appstore/verify")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["signedTransactionInfo": signedTransactionInfo])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 200 else {
            throw URLError(.init(rawValue: httpResponse.statusCode))
        }

        return try JSONDecoder().decode(VerifyResponse.self, from: data)
    }

    // MARK: - API Key Management

    /// Get current API key status (masked)
    func getApiKeyStatus(idToken: String) async throws -> KeyStatusResponse {
        let url = URL(string: "\(baseURL)/api/dashboard/key")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(KeyStatusResponse.self, from: data)
    }

    /// Reveal the full API key
    func revealApiKey(idToken: String) async throws -> String {
        let url = URL(string: "\(baseURL)/api/dashboard/key/reveal")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let result = try JSONDecoder().decode(RevealResponse.self, from: data)
        return result.apiKey
    }
}
