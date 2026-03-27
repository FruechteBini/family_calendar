import Foundation

enum HTTPMethod: String {
    case GET, POST, PUT, PATCH, DELETE
}

actor APIClient {
    private let keychainManager: KeychainManager
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var onUnauthorized: (@Sendable () -> Void)?

    private static let serverURLKey = "server_url"
    private static let defaultServerURL = "http://localhost:8000"

    var baseURL: String {
        UserDefaults.standard.string(forKey: Self.serverURLKey) ?? Self.defaultServerURL
    }

    init(keychainManager: KeychainManager, session: URLSession = .shared) {
        self.keychainManager = keychainManager
        self.session = session

        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = dec

        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = enc
    }

    func setUnauthorizedHandler(_ handler: @escaping @Sendable () -> Void) {
        self.onUnauthorized = handler
    }

    static func setServerURL(_ url: String) {
        UserDefaults.standard.set(url, forKey: serverURLKey)
    }

    // MARK: - Generic Request

    func request<T: Decodable>(
        method: HTTPMethod,
        path: String,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let urlRequest = try buildRequest(method: method, path: path, body: body, queryItems: queryItems)
        let (data, response) = try await performRequest(urlRequest)
        try mapStatusCode(response: response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func requestNoContent(
        method: HTTPMethod,
        path: String,
        body: (any Encodable)? = nil
    ) async throws {
        let urlRequest = try buildRequest(method: method, path: path, body: body, queryItems: nil)
        let (data, response) = try await performRequest(urlRequest)
        try mapStatusCode(response: response, data: data)
    }

    // MARK: - Convenience

    func get<T: Decodable>(path: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        try await request(method: .GET, path: path, queryItems: queryItems)
    }

    func post<T: Decodable>(path: String, body: (any Encodable)? = nil) async throws -> T {
        try await request(method: .POST, path: path, body: body)
    }

    func put<T: Decodable>(path: String, body: (any Encodable)? = nil) async throws -> T {
        try await request(method: .PUT, path: path, body: body)
    }

    func patch<T: Decodable>(path: String, body: (any Encodable)? = nil) async throws -> T {
        try await request(method: .PATCH, path: path, body: body)
    }

    func delete(path: String) async throws {
        try await requestNoContent(method: .DELETE, path: path)
    }

    func delete<T: Decodable>(path: String) async throws -> T {
        try await request(method: .DELETE, path: path)
    }

    // MARK: - Login (Form-Encoded)

    func login(username: String, password: String) async throws -> TokenResponse {
        guard var components = URLComponents(string: baseURL) else {
            throw APIError.invalidURL
        }
        components.path = Endpoints.Auth.login

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HTTPMethod.POST.rawValue
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let formBody = "username=\(formEncode(username))&password=\(formEncode(password))"
        urlRequest.httpBody = formBody.data(using: .utf8)

        let (data, response) = try await performRequest(urlRequest)
        try mapStatusCode(response: response, data: data)

        do {
            return try decoder.decode(TokenResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Internal

    private func buildRequest(
        method: HTTPMethod,
        path: String,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]?
    ) throws -> URLRequest {
        guard var components = URLComponents(string: baseURL) else {
            throw APIError.invalidURL
        }
        components.path = path
        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue

        if let token = keychainManager.loadToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try encoder.encode(AnyEncodable(body))
        }

        return urlRequest
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }

        return (data, httpResponse)
    }

    private func mapStatusCode(response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            onUnauthorized?()
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden(extractDetail(from: data) ?? "Zugriff verweigert")
        case 404:
            throw APIError.notFound(extractDetail(from: data) ?? "Nicht gefunden")
        case 409:
            throw APIError.conflict(extractDetail(from: data) ?? "Konflikt")
        case 503:
            throw APIError.serviceUnavailable(extractDetail(from: data) ?? "Service nicht verfuegbar")
        default:
            if response.statusCode >= 500 {
                throw APIError.serverError(extractDetail(from: data) ?? "Interner Serverfehler (\(response.statusCode))")
            }
            throw APIError.serverError(extractDetail(from: data) ?? "Unbekannter Fehler (\(response.statusCode))")
        }
    }

    private func extractDetail(from data: Data) -> String? {
        struct ErrorBody: Decodable { let detail: String }
        return try? JSONDecoder().decode(ErrorBody.self, from: data).detail
    }

    private func formEncode(_ value: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&=")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }
}

// MARK: - Type Erasure for Encodable

private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void

    init(_ wrapped: any Encodable) {
        self.encodeFunc = { encoder in
            try wrapped.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}

// MARK: - Auth Response Models

struct TokenResponse: Codable, Sendable {
    let accessToken: String
    let tokenType: String
}
