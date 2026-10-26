import Foundation

public protocol RatesClient: Sendable {
    func fetchLast(codes: [String]) async throws -> RatesSnapshot
    func fetchDaily(code: String, days: Int) async throws -> [HistoryPoint]
}

public struct AwesomeAPIClient: RatesClient {
    static let base = URL(string: "https://economia.awesomeapi.com.br/json/")!
    private let session: URLSession

    public init(session: URLSession = .shared) { self.session = session }

    public static func lastURL(codes: [String]) -> URL {
        base.appendingPathComponent("last/" + codes.map { "\($0)-BRL" }.joined(separator: ","))
    }

    public static func dailyURL(code: String, days: Int) -> URL {
        base.appendingPathComponent("daily/\(code)-BRL/\(days)")
    }

    public func fetchLast(codes: [String]) async throws -> RatesSnapshot {
        try AwesomeAPIDecoder.decodeLast(try await get(Self.lastURL(codes: codes)))
    }

    public func fetchDaily(code: String, days: Int) async throws -> [HistoryPoint] {
        try AwesomeAPIDecoder.decodeDaily(try await get(Self.dailyURL(code: code, days: days)))
    }

    private func get(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("DollarApple (+https://github.com/marzanchet/dollarapple)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw QuoteError.http(http.statusCode)
        }
        return data
    }
}
