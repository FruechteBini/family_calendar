import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case forbidden(String)
    case notFound(String)
    case conflict(String)
    case serverError(String)
    case serviceUnavailable(String)
    case networkError(Error)
    case decodingError(Error)
    case invalidURL
    case noData

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Sitzung abgelaufen. Bitte erneut anmelden."
        case .forbidden(let msg): return msg
        case .notFound(let msg): return msg
        case .conflict(let msg): return msg
        case .serverError(let msg): return "Serverfehler: \(msg)"
        case .serviceUnavailable(let msg): return msg
        case .networkError(let error): return "Netzwerkfehler: \(error.localizedDescription)"
        case .decodingError(let error): return "Datenverarbeitungsfehler: \(error.localizedDescription)"
        case .invalidURL: return "Ungueltige URL"
        case .noData: return "Keine Daten erhalten"
        }
    }
}
