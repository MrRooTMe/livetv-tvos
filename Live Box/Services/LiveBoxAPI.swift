import Foundation

enum LiveBoxAPIError: Error, Equatable {
    case invalidURL
    case invalidResponse
}

struct LiveBoxAPI {
    struct ActivationOutcome {
        let isValid: Bool
        let message: String
    }

    private struct VerificationResponse: Decodable {
        let result: String

        var isAuthorized: Bool {
            result.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true"
        }
    }

    private struct ActivationResponseDTO: Decodable {
        let valid: String
        let result: String

        var isValid: Bool {
            let normalized = valid.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return normalized == "1" || normalized == "true"
        }
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func verifyActivation(code: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        request(path: "/activation/verify_activation.php", code: code, completion: completion)
    }

    func requestActivation(code: String, completion: @escaping (Result<ActivationOutcome, Error>) -> Void) {
        guard var components = baseComponents(for: "/activation/new_activation.php") else {
            completion(.failure(LiveBoxAPIError.invalidURL))
            return
        }
        components.queryItems = [URLQueryItem(name: "code", value: code)]

        guard let url = components.url else {
            completion(.failure(LiveBoxAPIError.invalidURL))
            return
        }

        performRequest(url: url, decoding: ActivationResponseDTO.self) { result in
            switch result {
            case .success(let dto):
                let outcome = ActivationOutcome(isValid: dto.isValid, message: dto.result)
                completion(.success(outcome))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchChannels(code: String, completion: @escaping (Result<[Channel], Error>) -> Void) {
        guard var components = baseComponents(for: "/activation/json.php") else {
            completion(.failure(LiveBoxAPIError.invalidURL))
            return
        }
        components.queryItems = [URLQueryItem(name: "code", value: code)]

        guard let url = components.url else {
            completion(.failure(LiveBoxAPIError.invalidURL))
            return
        }

        performRequest(url: url, decoding: [Channel].self, completion: completion)
    }

    private func request(path: String, code: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard var components = baseComponents(for: path) else {
            completion(.failure(LiveBoxAPIError.invalidURL))
            return
        }
        components.queryItems = [URLQueryItem(name: "code", value: code)]

        guard let url = components.url else {
            completion(.failure(LiveBoxAPIError.invalidURL))
            return
        }

        performRequest(url: url, decoding: VerificationResponse.self) { result in
            switch result {
            case .success(let response):
                completion(.success(response.isAuthorized))
            case .failure(let error):
                if let apiError = error as? LiveBoxAPIError, apiError == .invalidResponse {
                    completion(.success(false))
                } else {
                    completion(.failure(error))
                }
            }
        }
    }

    private func baseComponents(for path: String) -> URLComponents? {
        var components = URLComponents()
        components.scheme = "http"
        components.host = "api.liveboxtv.gq"
        components.path = path
        return components
    }

    private func performRequest<Response: Decodable>(url: URL, decoding type: Response.Type, completion: @escaping (Result<Response, Error>) -> Void) {
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard
                let httpResponse = response as? HTTPURLResponse,
                200..<300 ~= httpResponse.statusCode,
                let data = data,
                !data.isEmpty
            else {
                completion(.failure(LiveBoxAPIError.invalidResponse))
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                let decoded = try decoder.decode(type, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
